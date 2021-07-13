pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */
import "../modules/SafeMath.sol";
import "./acceleratedMinePoolData.sol";
import "../ERC20/IERC20.sol";
import "../ERC20/safeErc20.sol";
/**
 * @title PPT period mine pool.
 * @dev A smart-contract which distribute some mine coins when user stake PPT coins.
 *
 */
contract acceleratedMinePool is acceleratedMinePoolData {
    using SafeMath for uint256;
    /**
     * @dev constructor.
     */
    constructor (address multiSignature) proxyOwner(multiSignature) public{
    }
    function () payable external {
        
    }
    function update() external versionUpdate {
    }
    function setPoolStartTime(uint256 _startTime) external onlyOrigin {
        startTime = _startTime;
    }
    function setPHXVestingPool(address _PHXVestingPool) external onlyOwner {
        vestingPool = IPHXVestingPool(_PHXVestingPool);
        (acceleratorStart,acceleratorPeriod) = vestingPool.getAcceleratorPeriodInfo();
    }
    /**
     * @dev getting user's staking PPT balance.
     * @param account user's account
     */
    function getUserPPTBalance(address account)public view returns (uint256) {
        return userInfoMap[account].pptBalance;
    }
    /**
     * @dev getting whole pool's mine shared distribution. All these distributions will share base mine production.
     */
    function getTotalDistribution() public view returns (uint256){
        return totalDistribution;
    }
    /**
     * @dev foundation redeem out mine coins.
     * @param mineCoin mineCoin address
     * @param amount redeem amount.
     */
    function redeemOut(address mineCoin,uint256 amount)public nonReentrant onlyOrigin{
        _redeem(msg.sender,mineCoin,amount);
    }
    /**
     * @dev retrieve minecoin distributed informations.
     * @param mineCoin mineCoin address
     * @return distributed amount and distributed time interval.
     */
    function getMineInfo(address mineCoin)public view returns(uint256,uint256){
        return (mineInfoMap[mineCoin].mineAmount,mineInfoMap[mineCoin].mineInterval);
    }
    /**
     * @dev retrieve user's mine balance.
     * @param account user's account
     * @param mineCoin mineCoin address
     */
    function getMinerBalance(address account,address mineCoin)public view returns(uint256){
        return userInfoMap[account].minerBalances[mineCoin].add(_getUserLatestMined(mineCoin,account));
    }
    /**
     * @dev Set mineCoin mine info, only foundation owner can invoked.
     * @param mineCoin mineCoin address
     * @param _mineAmount mineCoin distributed amount
     * @param _mineInterval mineCoin distributied time interval
     */
    function setMineCoinInfo(address mineCoin,uint256 _mineAmount,uint256 _mineInterval)public onlyOrigin {
        require(_mineAmount<1e30,"input mine amount is too large");
        require(_mineInterval>0,"input mine Interval must larger than zero");
        _mineSettlement(mineCoin);
        mineInfoMap[mineCoin].mineAmount = _mineAmount;
        mineInfoMap[mineCoin].mineInterval = _mineInterval;
        if (mineInfoMap[mineCoin].startPeriod == 0){
            mineInfoMap[mineCoin].startPeriod = getPeriodIndex(currentTime());
        }
        whiteList.addWhiteListAddress(mineCoin);
    }

    /**
     * @dev user redeem mine rewards.
     * @param mineCoin mine coin address
     */
    function redeemMinerCoin(address mineCoin)public nonReentrant notHalted {
        _mineSettlement(mineCoin);
        _settleUserMine(mineCoin,msg.sender);
        _redeemMineCoin(mineCoin,msg.sender);
    }
    /**
     * @dev subfunction for user redeem mine rewards.
     * @param mineCoin mine coin address
     * @param recieptor recieptor's account
     */
    function _redeemMineCoin(address mineCoin,address payable recieptor) internal {
        uint256 mineBalance = userInfoMap[recieptor].minerBalances[mineCoin];
        require (mineBalance>0,"mine balance is zero!");
        userInfoMap[recieptor].minerBalances[mineCoin] = 0;
        _redeem(recieptor,mineCoin,mineBalance);
        emit RedeemMineCoin(recieptor,mineCoin,mineBalance);
    }

    /**
     * @dev Calculate user's current APY.
     * @param account user's account.
     * @param mineCoin mine coin address
     */
    function getUserCurrentAPY(address account,address mineCoin)public view returns (uint256) {
        if (totalDistribution == 0 || mineInfoMap[mineCoin].mineInterval == 0){
            return 0;
        }
        uint256 baseMine = mineInfoMap[mineCoin].mineAmount.mul(365 days).mul(
                userInfoMap[account].distribution)/totalDistribution/mineInfoMap[mineCoin].mineInterval;
        return baseMine.mul(getPeriodWeight(account,getPeriodIndex(currentTime()),userInfoMap[account].maxPeriodID))/rateDecimal;
    }
    /**
     * @dev the auxiliary function for _mineSettlementAll.
     * @param mineCoin mine coin address
     */    
    function _mineSettlement(address mineCoin)internal{
        uint256 latestTime = mineInfoMap[mineCoin].latestSettleTime;
        uint256 curIndex = getPeriodIndex(latestTime);
        if (curIndex == 0){
            latestTime = startTime;
            curIndex = 1;
        }
        uint256 nowIndex = getPeriodIndex(currentTime());
        if (nowIndex == 0){
            return;
        }
        for (uint256 i=0;i<_maxLoop;i++){
            // If the fixed distribution is zero, we only need calculate 
            uint256 finishTime = getPeriodFinishTime(curIndex);
            if (finishTime < currentTime()){
                _mineSettlementPeriod(mineCoin,curIndex,finishTime.sub(latestTime));
                latestTime = finishTime;
            }else{
                _mineSettlementPeriod(mineCoin,curIndex,currentTime().sub(latestTime));
                latestTime = currentTime();
                break;
            }
            curIndex++;
            if (curIndex > nowIndex){
                break;
            }
        }
        uint256 _mineInterval = mineInfoMap[mineCoin].mineInterval;
        if (_mineInterval>0){
            mineInfoMap[mineCoin].latestSettleTime = latestTime/_mineInterval*_mineInterval;
        }else{
            mineInfoMap[mineCoin].latestSettleTime = currentTime();
        }
    }
    /**
     * @dev the auxiliary function for _mineSettlement. Calculate and record a period mine production. 
     * @param mineCoin mine coin address
     * @param periodID period time
     * @param mineTime covered time.
     */  
    function _mineSettlementPeriod(address mineCoin,uint256 periodID,uint256 mineTime)internal{
        uint256 totalDistri = totalDistribution;
        if (totalDistri > 0){
            uint256 latestMined = _getPeriodMined(mineCoin,mineTime);
            if (latestMined>0){
                mineInfoMap[mineCoin].minedNetWorth = mineInfoMap[mineCoin].minedNetWorth.add(latestMined.mul(calDecimals)/totalDistri);
            }
        }
        mineInfoMap[mineCoin].periodMinedNetWorth[periodID] = mineInfoMap[mineCoin].minedNetWorth;
    }
    /**
     * @dev Calculate and record user's mine production. 
     * @param mineCoin mine coin address
     * @param account user's account
     */  
    function _settleUserMine(address mineCoin,address account) internal {
        uint256 nowIndex = getPeriodIndex(currentTime());
        if (nowIndex == 0){
            return;
        }
        if(userInfoMap[account].distribution>0){
            uint256 userPeriod = userInfoMap[account].settlePeriod[mineCoin];
            if(userPeriod == 0){
                userPeriod = 1;
            }
            if (userPeriod < mineInfoMap[mineCoin].startPeriod){
                userPeriod = mineInfoMap[mineCoin].startPeriod;
            }
            for (uint256 i = 0;i<_maxLoop;i++){
                _settlementPeriod(mineCoin,account,userPeriod);
                if (userPeriod >= nowIndex){
                    break;
                }
                userPeriod++;
            }
        }
        userInfoMap[account].minerOrigins[mineCoin] = _getTokenNetWorth(mineCoin,nowIndex);
        userInfoMap[account].settlePeriod[mineCoin] = nowIndex;
    }
    /**
     * @dev the auxiliary function for _settleUserMine. Calculate and record a period mine production. 
     * @param mineCoin mine coin address
     * @param account user's account
     * @param periodID period time
     */ 
    function _settlementPeriod(address mineCoin,address account,uint256 periodID) internal {
        uint256 tokenNetWorth = _getTokenNetWorth(mineCoin,periodID);
        if (totalDistribution > 0){
            userInfoMap[account].minerBalances[mineCoin] = userInfoMap[account].minerBalances[mineCoin].add(
                _settlement(mineCoin,account,periodID,tokenNetWorth));
        }
        userInfoMap[account].minerOrigins[mineCoin] = tokenNetWorth;
    }
    /**
     * @dev retrieve each period's networth. 
     * @param mineCoin mine coin address
     * @param periodID period time
     */ 
    function _getTokenNetWorth(address mineCoin,uint256 periodID)internal view returns(uint256){
        return mineInfoMap[mineCoin].periodMinedNetWorth[periodID];
    }

    /**
     * @dev the auxiliary function for getMinerBalance. Calculate mine amount during latest time phase.
     * @param mineCoin mine coin address
     * @param account user's account
     */ 
    function _getUserLatestMined(address mineCoin,address account)internal view returns(uint256){
        uint256 userDistri = userInfoMap[account].distribution;
        if (userDistri == 0){
            return 0;
        }
        uint256 userperiod = userInfoMap[account].settlePeriod[mineCoin];
        if (userperiod < mineInfoMap[mineCoin].startPeriod){
            userperiod = mineInfoMap[mineCoin].startPeriod;
        }
        uint256 origin = userInfoMap[account].minerOrigins[mineCoin];
        uint256 latestMined = 0;
        uint256 nowIndex = getPeriodIndex(currentTime());
        uint256 netWorth = _getTokenNetWorth(mineCoin,userperiod);
        uint256 maxPeriodID = userInfoMap[account].maxPeriodID;
        for (uint256 i=0;i<_maxLoop;i++){
            if(userperiod > nowIndex){
                break;
            }
            if (totalDistribution == 0){
                break;
            }
            netWorth = getPeriodNetWorth(mineCoin,userperiod,netWorth);
            latestMined = latestMined.add(userDistri.mul(netWorth.sub(origin)).mul(getPeriodWeight(account,userperiod,maxPeriodID))/rateDecimal/calDecimals);
            origin = netWorth;
            userperiod++;
        }
        return latestMined;
    }
    /**
     * @dev the auxiliary function for _getUserLatestMined. Calculate token net worth in each period.
     * @param mineCoin mine coin address
     * @param periodID Period ID
     * @param preNetWorth The previous period's net worth.
     */ 
    function getPeriodNetWorth(address mineCoin,uint256 periodID,uint256 preNetWorth) internal view returns(uint256) {
        uint256 latestTime = mineInfoMap[mineCoin].latestSettleTime;
        uint256 curPeriod = getPeriodIndex(latestTime);
        if(periodID < curPeriod){
            return mineInfoMap[mineCoin].periodMinedNetWorth[periodID];
        }else{
            if (preNetWorth<mineInfoMap[mineCoin].periodMinedNetWorth[periodID]){
                preNetWorth = mineInfoMap[mineCoin].periodMinedNetWorth[periodID];
            }
            uint256 finishTime = getPeriodFinishTime(periodID);
            if (finishTime >= currentTime()){
                finishTime = currentTime();
            }
            if(periodID > curPeriod){
                latestTime = getPeriodFinishTime(periodID-1);
            }
            if (totalDistribution == 0){
                return preNetWorth;
            }
            uint256 periodMined = _getPeriodMined(mineCoin,finishTime.sub(latestTime));
            return preNetWorth.add(periodMined.mul(calDecimals)/totalDistribution);
        }
    }
    /**
     * @dev Calculate mine amount
     * @param mineCoin mine coin address
     * @param mintTime mine duration.
     */ 
    function _getPeriodMined(address mineCoin,uint256 mintTime)internal view returns(uint256){
        uint256 _mineInterval = mineInfoMap[mineCoin].mineInterval;
        if (totalDistribution > 0 && _mineInterval>0){
            return mineInfoMap[mineCoin].mineAmount.mul(mintTime/_mineInterval);
        }
        return 0;
    }
    /**
     * @dev Auxiliary function, calculate user's latest mine amount.
     * @param mineCoin the mine coin address
     * @param account user's account
     * @param tokenNetWorth the latest token net worth
     */
    function _settlement(address mineCoin,address account,uint256 periodID,uint256 tokenNetWorth)internal view returns (uint256) {
        uint256 origin = userInfoMap[account].minerOrigins[mineCoin];
        require(tokenNetWorth>=origin,"error: tokenNetWorth logic error!");
        return userInfoMap[account].distribution.mul(tokenNetWorth-origin).mul(getPeriodWeight(account,periodID,userInfoMap[account].maxPeriodID))/rateDecimal/calDecimals;
    }
        /**
     * @dev transfer mineCoin to recieptor when account transfer amount PPTCoin to recieptor, only manager contract can modify database.
     * @param account the account transfer from
     * @param recieptor the account transfer to
     */
    function transferPPTCoin(address account,address recieptor) public onlyManager {
        changePPTBalance(account);
        changePPTBalance(recieptor);
    }
        /**
     * @dev mint mineCoin to account when account add collateral to collateral pool, only manager contract can modify database.
     * @param account user's account
     */
    function changePPTStake(address account) public onlyManager {
        changePPTBalance(account);
    }

    function changePPTBalance(address account) internal {
        removeDistribution(account);
        userInfoMap[account].pptBalance = IERC20(_operators[managerIndex]).balanceOf(account);
        addDistribution(account);
    }
    function getUserAccelerateInfo(address account)public view returns(uint256[] memory,uint256){
        return (userInfoMap[account].periodRates,userInfoMap[account].maxPeriodID);
    }
    function changeAcceleratedInfo(address account,uint256[] memory newRates,uint256 maxLockedPeriod) public onlyAccelerator{
        removeDistribution(account);
        userInfoMap[account].periodRates = newRates;
        userInfoMap[account].maxPeriodID = maxLockedPeriod;
        addDistribution(account);
    }
    /**
     * @dev Auxiliary function. Clear user's distribution amount.
     * @param account user's account.
     */
    function removeDistribution(address account) internal {
        uint256 addrLen = whiteList.length;
        for(uint256 i=0;i<addrLen;i++){
            _mineSettlement(whiteList[i]);
            _settleUserMine(whiteList[i],account);
        }
        uint256 distri = calculateDistribution(account);
        totalDistribution = totalDistribution.sub(distri);
        userInfoMap[account].distribution =  0;
//        userInfoMap[account].maxPeriodID =  0;
    }
    /**
     * @dev Auxiliary function. Add user's distribution amount.
     * @param account user's account.
     */
    function addDistribution(address account) internal {
        uint256 distri = calculateDistribution(account);
        userInfoMap[account].distribution =  distri;
        totalDistribution = totalDistribution.add(distri);
    }
    /**
     * @dev Auxiliary function. calculate user's distribution.
     * @param account user's account.
     */
    function calculateDistribution(address account) internal view returns (uint256){
        return userInfoMap[account].pptBalance;
    }

    /**
     * @dev Auxiliary function. get mine weight ratio from current period to one's maximium period.
     * @param currentID current period ID.
     * @param maxPeriod user's maximium period ID.
     */
    function getPeriodWeight(address account,uint256 currentID,uint256 maxPeriod) public view returns (uint256) {
        if (maxPeriod == 0 || currentID > maxPeriod){
            return rateDecimal;
        }
        uint256 curLocked = maxPeriod-currentID;
        if(userInfoMap[account].periodRates.length > curLocked){
            return userInfoMap[account].periodRates[curLocked];
        }
        return rateDecimal;
    }
    /**
     * @dev Throws if minePool is not start.
     */
    modifier minePoolStarted(){
        require(currentTime()>=startTime, 'mine pool is not start');
        _;
    }
    /**
     * @dev get now timestamp.
     */
    function currentTime() internal view returns (uint256){
        return now;
    }
    function getCurrentPeriodID()public view returns (uint256) {
        return getPeriodIndex(currentTime());
    }
    /**
     * @dev convert timestamp to period ID.
     * @param _time timestamp. 
     */ 
    function getPeriodIndex(uint256 _time) public view returns (uint256) {
        if (acceleratorPeriod == 0 || _time<acceleratorStart){
            return 0;
        }
        return _time.sub(acceleratorStart)/acceleratorPeriod+1;
    }
        /**
     * @dev convert period ID to period's finish timestamp.
     * @param periodID period ID. 
     */
    function getPeriodFinishTime(uint256 periodID)public view returns (uint256) {
        if (acceleratorPeriod == 0){
            return uint64(-1);
        }
        return periodID.mul(acceleratorPeriod).add(acceleratorStart);
    }  
    modifier onlyAccelerator() {
        require(address(vestingPool) == msg.sender, "vestingPool: caller is not the vestingPool");
        _;
    }
}