pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */
import "./PHXVestingPoolData.sol";
import "../modules/SafeMath.sol";
import "../acceleratedMinePool/IAcceleratedMinePool.sol";
import "../modules/whiteListAddress.sol";
import "../modules/SmallNumbers.sol";
contract PHXVestingPool is PHXVestingPoolData{
    using SafeMath for uint256;
    using whiteListAddress for address[];
        /**
     * @dev constructor.
     */
    constructor (address multiSignature) proxyOwner(multiSignature) public{
    }
    function initMineLockedInfo(uint256 _startTime,uint256 _periodTime,uint256 _maxPeriodLimit) external originOnce {
        startTime = _startTime;
        period = _periodTime;
        maxPeriodLimit = _maxPeriodLimit;
    }
    function update() external versionUpdate {
    }
    //rate = rateThousandth / 1000;
    function setVestingRate(address token,uint256 rateThousandth) external OwnerOrOrigin {
        vestTokens.addWhiteListAddress(token);
        vestingTokenRate[token] = rateThousandth;
    }
    function removeVestingToken(address token) external OwnerOrOrigin {
        vestTokens.removeWhiteListAddress(token);
        vestingTokenRate[token] = 0;
    }
    function getVestingTokenBalance(address account)external view returns(uint256,uint64){
         return (userInfoMap[account].vestingTokenBalance,userInfoMap[account].maxPeriodID);
    }
    function getAcceleratedBalance(address account,address minePool)external view returns(uint256,uint64){
        return (userInfoMap[account].acceleratedBalance[minePool],userInfoMap[account].maxPeriodID);
    }
    function getAcceleratorPeriodInfo()external view returns (uint256,uint256){
        return (startTime,period);
    }
    function stake(address token,uint256 amount,uint64 maxLockedPeriod,address toMinePool) tokenPermission(token) validPeriod(maxLockedPeriod) nonReentrant notHalted public {
        amount = getPayableAmount(token,amount);
        require(amount>0, "Stake amount is zero!");
        uint64 oldPeriod = userInfoMap[msg.sender].maxPeriodID;
        uint256 balance = amount.mul(vestingTokenRate[token]);
        userInfoMap[msg.sender].vestingTokenBalance  =  userInfoMap[msg.sender].vestingTokenBalance.add(balance);
        setUserLockedPeriod(msg.sender,maxLockedPeriod);
        _accelerateMinePool(toMinePool,balance,oldPeriod);
        if (oldPeriod != userInfoMap[msg.sender].maxPeriodID){
            uint256 poolLen = minePoolList.length;
            for(uint256 i=0;i<poolLen;i++){
                if (minePoolList[i] != toMinePool){
                    changeAcceleratedInfo(minePoolList[i],userInfoMap[msg.sender].acceleratedBalance[minePoolList[i]],oldPeriod);
                }
            }
        }        
        emit Stake(msg.sender,token,amount,maxLockedPeriod);
    }
    /**
     * @dev Add PHX locked period.
     * @param maxLockedPeriod accelerated locked preiod number.
     */
    function changeStakePeriod(uint64 maxLockedPeriod)public validPeriod(maxLockedPeriod) notHalted{
        require(userInfoMap[msg.sender].vestingTokenBalance > 0, "stake balance is zero");
        uint64 oldPeriod = userInfoMap[msg.sender].maxPeriodID;
        setUserLockedPeriod(msg.sender,maxLockedPeriod);
        if (oldPeriod != userInfoMap[msg.sender].maxPeriodID){
            uint256 poolLen = minePoolList.length;
            for(uint256 i=0;i<poolLen;i++){
                changeAcceleratedInfo(minePoolList[i],userInfoMap[msg.sender].acceleratedBalance[minePoolList[i]],oldPeriod);
            }
            emit ChangePeriod(msg.sender,maxLockedPeriod);
        }
    }
    function unstakeAll()external nonReentrant notHalted periodExpired(msg.sender){
        uint nlen = vestTokens.length;
        for (uint i=0;i<nlen;i++){
            address token = vestTokens[i];
            uint256 amount = userInfoMap[msg.sender].tokenBalance[token];
            if (amount>0){
                _redeem(msg.sender, token, amount);
                emit Unstake(msg.sender,token,amount);
                userInfoMap[msg.sender].tokenBalance[token] = 0;
            }
        }
        userInfoMap[msg.sender].vestingTokenBalance = 0;
        uint64 oldPeriod = userInfoMap[msg.sender].maxPeriodID;
        userInfoMap[msg.sender].maxPeriodID = 0;
        uint256 poolLen = minePoolList.length;
        for(uint256 i=0;i<poolLen;i++){
            address toMinePool = minePoolList[i];
            uint256 amount = userInfoMap[msg.sender].acceleratedBalance[toMinePool];
            userInfoMap[msg.sender].acceleratedBalance[toMinePool] = 0;
            changeAcceleratedInfo(toMinePool,amount,oldPeriod);
        }
    }
    /**
     * @dev withdraw PHX coin.
     * @param amount PHX amount that withdraw from mine pool.
     */
    function unstake(address token,uint256 amount,address toMinePool)public tokenPermission(token) nonReentrant notHalted periodExpired(msg.sender){
        require(amount > 0, 'unstake amount is zero');
        uint256 tokenBalance = userInfoMap[msg.sender].tokenBalance[token];
        require(tokenBalance>= amount,'unstake amount is greater than total user stakes');
        uint64 oldPeriod = userInfoMap[msg.sender].maxPeriodID;
        uint256 balance = amount.mul(vestingTokenRate[token]);
        uint256 oldBalance = userInfoMap[msg.sender].acceleratedBalance[toMinePool];
        require(oldBalance>=balance,'mine pool vesting balance is insufficient');
        userInfoMap[msg.sender].vestingTokenBalance = userInfoMap[msg.sender].vestingTokenBalance.sub(balance);
        userInfoMap[msg.sender].tokenBalance[token] = tokenBalance-amount;
        userInfoMap[msg.sender].acceleratedBalance[toMinePool] = oldBalance - balance;
        if(userInfoMap[msg.sender].vestingTokenBalance == 0){
           userInfoMap[msg.sender].maxPeriodID = 0;
        }
        _redeem(msg.sender, token, amount);
        emit Unstake(msg.sender,token,amount);
        changeAcceleratedInfo(toMinePool,oldBalance,oldPeriod);
    }
    function transferAcceleratedBalance(address fromMinePool,address toMinePool,uint256 amount) public{
        _removeFromMinoPool(fromMinePool,amount);
        _accelerateMinePool(toMinePool,amount,userInfoMap[msg.sender].maxPeriodID);
    }
    function changeAcceleratedInfo(address minePool,uint256 oldStake,uint64 oldPeriod)internal {
        if (minePool != address(0)){
            uint64 curPeriod = getCurrentPeriodID();
            uint256[] memory oldRates = calculateAccelerateRates(oldStake,oldPeriod,curPeriod);
            uint256[] memory newRates = calculateAccelerateRates(userInfoMap[msg.sender].acceleratedBalance[minePool],
                userInfoMap[msg.sender].maxPeriodID,curPeriod);
            if (oldRates.length !=0 || newRates.length != 0){
                IAcceleratedMinePool(minePool).changeAcceleratedInfo(msg.sender,newRates,userInfoMap[msg.sender].maxPeriodID);
            }
        }
    }
    function _removeFromMinoPool(address minePool,uint256 amount) internal{
        require(userInfoMap[msg.sender].acceleratedBalance[minePool]>=amount,"mine pool accelerated balance is unsufficient");
        uint256 oldBalance = userInfoMap[msg.sender].acceleratedBalance[minePool];
        userInfoMap[msg.sender].acceleratedBalance[minePool] = oldBalance-amount;
        changeAcceleratedInfo(minePool,oldBalance,userInfoMap[msg.sender].maxPeriodID);
    }
    function _accelerateMinePool(address minePool,uint256 amount,uint64 oldPeriod) internal{
        uint256 oldBalance = userInfoMap[msg.sender].acceleratedBalance[minePool];
        userInfoMap[msg.sender].acceleratedBalance[minePool] = oldBalance.add(amount);
        changeAcceleratedInfo(minePool,oldBalance,oldPeriod); 
    }
    /**
     * @dev getting user's maximium locked period ID.
     * @param account user's account
     */
    function getUserMaxPeriodId(address account)public view returns (uint64) {
        return userInfoMap[account].maxPeriodID;
    }
    /**
     * @dev getting user's locked expired time. After this time user can unstake PHX coins.
     * @param account user's account
     */
    function getUserExpired(address account)public view returns (uint256) {
        return userInfoMap[account].lockedExpired;
    }
    /**
     * @dev getting current mine period ID.
     */
    function getCurrentPeriodID()public view returns (uint64) {
        return getPeriodIndex(currentTime());
    }
    /**
     * @dev convert timestamp to period ID.
     * @param _time timestamp. 
     */ 
    function getPeriodIndex(uint256 _time) public view returns (uint64) {
        if (_time<startTime){
            return 0;
        }
        return uint64(_time.sub(startTime).div(period)+1);
    }
    function setUserLockedPeriod(address account,uint64 lockedPeriod) internal{
        uint64 curPeriod = getPeriodIndex(currentTime());
        uint64 userMaxPeriod = curPeriod+lockedPeriod-1;
        require(userMaxPeriod>=userInfoMap[account].maxPeriodID, "lockedPeriod cannot be smaller than current locked period");
        userInfoMap[account].maxPeriodID = userMaxPeriod;
        userInfoMap[account].lockedExpired = uint128(getPeriodFinishTime(curPeriod+lockedPeriod-1));
    }
    /**
     * @dev convert period ID to period's finish timestamp.
     * @param periodID period ID. 
     */
    function getPeriodFinishTime(uint64 periodID)public view returns (uint256) {
        return period.mul(periodID).add(startTime);
    }
        /**
     * @dev Throws if input period number is greater than _maxPeriod.
     */
    modifier validPeriod(uint64 period){
        require(period > 0 && period <= maxPeriodLimit, 'locked period must be in valid range');
        _;
    }
    /**
     * @dev get now timestamp.
     */
    function currentTime() internal view returns (uint256){
        return now;
    }
    modifier tokenPermission(address token){
        require(vestingTokenRate[token]>0 && vestTokens.isEligibleAddress(token),'Token is not allowed to vest');

        _;
    }    
    /**
     * @dev Throws if user's locked expired timestamp is less than now.
     */
    modifier periodExpired(address account){
        require(userInfoMap[account].lockedExpired < currentTime(),'locked period is not expired');

        _;
    }
    function calculateAccelerateRates(uint256 stakeNum,uint64 maxPeriod,uint64 currentPreiod) public pure returns(uint256[] memory){
        if (maxPeriod<currentPreiod || stakeNum<5e23){
            uint256[] memory rates = new uint256[](0);
            return rates;
        }
        maxPeriod = maxPeriod - currentPreiod + 1;
        uint256[] memory rates = new uint256[](maxPeriod);
        require(stakeNum<1e40, "input stakeNum overflow");
        //t=(amount/500)^0.05
        //0.05<<32 = 214748365
        uint256 t = (SmallNumbers.pow((stakeNum<<32)/5e23,214748365)*rateDecimals)>>32;
        uint256 tt = t*t/rateDecimals;
        tt = tt*tt/rateDecimals;
        uint256 t5 = tt*t/rateDecimals;
        uint256 t6 = t5*t/rateDecimals;
        uint256 slope = (t6*400000 + t5*670000)/rateDecimals;
        for (uint256 i=0;i<maxPeriod;i++){
            rates[i] = slope*i+t;
        }
        return rates;
        //rate=(t^6*0.004+t^5*0.0067)*(Period-1)+t
        
    }
}