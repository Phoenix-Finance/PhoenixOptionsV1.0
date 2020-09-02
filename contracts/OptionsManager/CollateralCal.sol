pragma solidity ^0.5.1;
import "../modules/SafeMath.sol";
import "../modules/SafeInt256.sol";
import "./ManagerData.sol";
/**
 * @title collateral calculate module
 * @dev A smart-contract which has operations of collateral and methods of calculate collateral occupation.
 *
 */
contract CollateralCal is ManagerData {
    using SafeMath for uint256;
    using SafeInt256 for int256;

    /**
     * @dev get the valid range of input amount
     */
    function getInputAmountRange() public view returns(uint256,uint256) {
        return (minAmount,maxAmount);
    }
    /**
     * @dev set the valid range of input amount
     * @param _minAmount the minimum input amount limit
     * @param _maxAmount the maximum input amount limit
     */
    function setInputAmountRange(uint256 _minAmount,uint256 _maxAmount) public onlyOwner{
        minAmount = _minAmount;
        maxAmount = _maxAmount;
    }
    /**
     * @dev Determine whether the input amount is within the valid range
     * @param Amount Test value which is user input
     */
    function checkInputAmount(uint256 Amount)internal view{
        require(maxAmount>=Amount && minAmount<=Amount,"input amount is out of input amount range");
    }
    /**
     * @dev  The foundation operator want to add some coin to netbalance, which can increase the FPTCoin net worth.
     * @param settlement the settlement coin address which the foundation operator want to transfer in this contract address.
     * @param amount the amount of the settlement coin which the foundation operator want to transfer in this contract address.
     */
    function addNetBalance(address settlement,uint256 amount) public payable onlyOperatorIndex(1) {
        amount = getPayableAmount(settlement,amount);
        _collateralPool.addNetWorthBalance(settlement,int256(amount));
//        netWorthBalances[settlement] = netWorthBalances[settlement].add(amount);
    }
    /**
     * @dev  The foundation owner want to set the minimum collateral occupation rate.
     * @param collateral collateral coin address
     * @param colRate The thousandths of the minimum collateral occupation rate.
     */
    function setCollateralRate(address collateral,uint256 colRate) public onlyOwner {
        addWhiteList(collateral);
        collateralRate[collateral] = colRate;
//        collateralRate = colRate;

    }
    /**
     * @dev Get the minimum collateral occupation rate.
     */
    function getCollateralRate(address collateral)public view returns (uint256) {
        return collateralRate[collateral];
    }
    /**
     * @dev Retrieve user's cost of collateral, priced in USD.
     * @param user input retrieved account 
     */
    function getUserPayingUsd(address user)public view returns (uint256){
        return _collateralPool.getUserPayingUsd(user);
        //userCollateralPaying[user];
    }
    /**
     * @dev Retrieve user's amount of the specified collateral.
     * @param user input retrieved account 
     * @param collateral input retrieved collateral coin address 
     */
    function userInputCollateral(address user,address collateral)public view returns (uint256){
        return _collateralPool.getUserInputCollateral(user,collateral);
        //return userInputCollateral[user][collateral];
    }
    /**
     * @dev Calculate the collateral pool shared worth.
     * The foundation operator will invoke this function frequently
     */
    function calSharedPayment() public onlyOperatorIndex(0) {
        address[] memory tmpWhiteList = whiteList;
        (uint256 firstOption,int256[] memory latestShared) = _optionsPool.getNetWrothCalInfo(tmpWhiteList);
        uint256 lastOption = _optionsPool.getOptionInfoLength();
        (int256[] memory newNetworth,uint256[] memory sharedBalance,uint256 newFirst) =
                     _optionsPool.calRangeSharedPayment(lastOption,firstOption,lastOption,tmpWhiteList);
        int256[] memory fallBalance = _optionsPool.calculatePhaseOptionsFall(lastOption,newFirst,lastOption,tmpWhiteList);
        for (uint256 i= 0;i<fallBalance.length;i++){
            fallBalance[i] = int256(sharedBalance[i])-latestShared[i]+fallBalance[i];
        }
        setSharedPayment(newNetworth,fallBalance,newFirst);
    }
    /**
     * @dev Set the calculation results of the collateral pool shared worth.
     * The foundation operator will invoke this function frequently
     * @param newNetworth Current expired options' net worth 
     * @param sharedBalances All unexpired options' shared balance distributed by time.
     * @param firstOption The new first unexpired option's index.
     */
    function setSharedPayment(int256[] memory newNetworth,int256[] memory sharedBalances,uint256 firstOption) public onlyOperatorIndex(0){
        _optionsPool.setSharedState(firstOption,sharedBalances,whiteList);
        _collateralPool.addNetWorthBalances(whiteList,newNetworth);
    }
    /**
     * @dev Retrieve user's current total worth, priced in USD.
     * @param account input retrieve account
     */
    function getUserTotalWorth(address account)public view returns (uint256){
        return getTokenNetworth().mul(_FPTCoin.balanceOf(account)).add(_FPTCoin.lockedWorthOf(account));
    }
    /**
     * @dev Retrieve FPTCoin's net worth, priced in USD.
     */
    function getTokenNetworth() public view returns (uint256){
        uint256 _totalSupply = _FPTCoin.totalSupply();
        if (_totalSupply == 0){
            return 1e8;
        }
        uint256 netWorth = getUnlockedCollateral()/_totalSupply;
        return netWorth>100 ? netWorth : 100;
    }
    /**
     * @dev Deposit collateral in this pool from user.
     * @param collateral The collateral coin address which is in whitelist.
     * @param amount the amount of collateral to deposit.
     */
    function addCollateral(address collateral,uint256 amount) nonReentrant notHalted public payable {
        amount = getPayableAmount(collateral,amount);
        uint256 fee = _collateralPool.addTransactionFee(collateral,amount,3);
        amount = amount-fee;
        uint256 price = _oracle.getPrice(collateral);
        uint256 userPaying = price*amount;
        uint256 mintAmount = userPaying/getTokenNetworth();
        _collateralPool.addUserPayingUsd(msg.sender,userPaying);
        _collateralPool.addCollateralBalance(collateral,amount);
        _collateralPool.addUserInputCollateral(msg.sender,collateral,amount);
         _collateralPool.addNetWorthBalance(collateral,int256(amount));
        emit AddCollateral(msg.sender,collateral,amount,mintAmount);
        _FPTCoin.mint(msg.sender,mintAmount);
    }
    /**
     * @dev redeem collateral from this pool, user can input the prioritized collateral,he will get this coin,
     * if this coin is unsufficient, he will get others collateral which in whitelist.
     * @param tokenAmount the amount of FPTCoin want to redeem.
     * @param collateral The prioritized collateral coin address.
     */
    function redeemCollateral(uint256 tokenAmount,address collateral) nonReentrant notHalted public {
        checkInputAmount(tokenAmount);
        require(checkAddressRedeemOut(collateral) , "settlement is unsupported token");
        uint256 lockedAmount = _FPTCoin.lockedBalanceOf(msg.sender);
        require(_FPTCoin.balanceOf(msg.sender)+lockedAmount>=tokenAmount,"SCoin balance is insufficient!");
        uint256 userTotalWorth = getUserTotalWorth(msg.sender);
        uint256 leftCollateral = getLeftCollateral();
        (uint256 burnAmount,uint256 redeemWorth) = _FPTCoin.redeemLockedCollateral(msg.sender,tokenAmount,leftCollateral);
        tokenAmount -= burnAmount;
        burnAmount = 0;
        if (tokenAmount > 0){
            leftCollateral -= redeemWorth;
            
            if (lockedAmount > 0){
                tokenAmount = tokenAmount > lockedAmount ? tokenAmount - lockedAmount : 0;
            }
            (uint256 newRedeem,uint256 newWorth) = _redeemCollateral(tokenAmount,leftCollateral);
            if(newRedeem>0){
                burnAmount = newRedeem;
                redeemWorth += newWorth;
            }
        }
        _redeemCollateralWorth(collateral,redeemWorth,userTotalWorth);
        if (burnAmount>0){
            _FPTCoin.burn(msg.sender, burnAmount);
        }
    }
    /**
     * @dev The subfunction of redeem collateral.
     * @param leftAmount the left amount of FPTCoin want to redeem.
     * @param leftCollateral The left collateral which can be redeemed, priced in USD.
     */
    function _redeemCollateral(uint256 leftAmount,uint256 leftCollateral)internal returns (uint256,uint256){
        uint256 tokenNetWorth = getTokenNetworth();
        uint256 leftWorth = leftAmount*tokenNetWorth;        
        if (leftWorth > leftCollateral){
            uint256 newRedeem = leftCollateral/tokenNetWorth;
            uint256 newWorth = newRedeem*tokenNetWorth;
            uint256 locked = leftAmount - newRedeem;
            _FPTCoin.addlockBalance(msg.sender,locked,locked*tokenNetWorth);
            return (newRedeem,newWorth);
        }
        return (leftAmount,leftWorth);
    }
    /**
     * @dev The auxiliary function of collateral calculation.
     * @param collateral the prioritized collateral which user input.
     * @return the collateral whitelist, in which the prioritized collateral is at the front.
     */
    function getTempWhiteList(address collateral) internal view returns (address[] memory) {
        address[] memory tmpWhiteList = whiteList;
        uint256 index = whiteListAddress._getEligibleIndexAddress(tmpWhiteList,collateral);
        if (index != 0){
            tmpWhiteList[index] = tmpWhiteList[0];
            tmpWhiteList[0] = collateral;
        }
        return tmpWhiteList;
    }
    /**
     * @dev The subfunction of redeem collateral. Calculate all redeem count and tranfer.
     * @param collateral the prioritized collateral which user input.
     * @param redeemWorth user redeem worth, priced in USD.
     * @param userTotalWorth user total worth, priced in USD.
     */
    function _redeemCollateralWorth(address collateral,uint256 redeemWorth,uint256 userTotalWorth) internal {
        if (redeemWorth == 0){
            return;
        }
        emit RedeemCollateral(msg.sender,collateral,redeemWorth);
        address[] memory tmpWhiteList = getTempWhiteList(collateral);
        (uint256[] memory colBalances,uint256[] memory PremiumBalances,uint256[] memory prices) = 
                _getCollateralAndPremiumBalances(msg.sender,userTotalWorth,tmpWhiteList);
        _collateralPool.transferPaybackBalances(msg.sender,redeemWorth,tmpWhiteList,colBalances,
                PremiumBalances,prices);
    }
    /**
     * @dev Retrieve user's collateral worth in all collateral coin. 
     * If user want to redeem all his collateral,and the vacant collateral is sufficient,
     * He can redeem each collateral amount in return list.
     * @param account the retrieve user's account;
     */
    function calCollateralWorth(address account)public view returns(uint256[] memory){
        uint256 worth = getUserTotalWorth(account);
        (uint256[] memory colBalances,uint256[] memory PremiumBalances,) = 
        _getCollateralAndPremiumBalances(account,worth,whiteList);
        uint256 whiteLen = whiteList.length;
        for (uint256 i=0; i<whiteLen;i++){
            colBalances[i] = colBalances[i].add(PremiumBalances[i]);
        }
        return colBalances;
    }
    /**
     * @dev The auxiliary function for redeem collateral calculation. 
     * @param account the retrieve user's account;
     * @param userTotalWorth user's total worth, priced in USD.
     * @param tmpWhiteList the collateral white list.
     * @return user's total worth in each collateral, priced in USD.
     */
    function _getCollateralAndPremiumBalances(address account,uint256 userTotalWorth,address[] memory tmpWhiteList) internal view returns(uint256[] memory,uint256[] memory,uint256[] memory){
        uint256[] memory prices = new uint256[](tmpWhiteList.length);
        uint256[] memory netWorthBalances = new uint256[](tmpWhiteList.length);
        for (uint256 i=0; i<tmpWhiteList.length;i++){
            if (checkAddressPermission(tmpWhiteList[i],0x0002)){
                netWorthBalances[i] = getNetWorthBalance(tmpWhiteList[i]);
            }
            prices[i] = _oracle.getPrice(tmpWhiteList[i]);
        }
        (uint256[] memory colBalances,uint256[] memory PremiumBalances) = _collateralPool.getCollateralAndPremiumBalances(account,userTotalWorth,tmpWhiteList,
                netWorthBalances,prices);
        return (colBalances,PremiumBalances,prices);
    } 
    /**
     * @dev Retrieve the occupied collateral worth, multiplied by minimum collateral rate, priced in USD. 
     */
    function getOccupiedCollateral() public view returns(uint256){
        uint256 totalOccupied = _optionsPool.getTotalOccupiedCollateral();
        return calculateCollateral(totalOccupied);
    }
    /**
     * @dev Retrieve the available collateral worth, the worth of collateral which can used for buy options, priced in USD. 
     */
    function getAvailableCollateral()public view returns(uint256){
        return safeSubCollateral(getUnlockedCollateral(),getOccupiedCollateral());
    }
    /**
     * @dev Retrieve the left collateral worth, the worth of collateral which can used for redeem collateral, priced in USD. 
     */
    function getLeftCollateral()public view returns(uint256){
        return safeSubCollateral(getTotalCollateral(),getOccupiedCollateral());
    }
    /**
     * @dev Retrieve the unlocked collateral worth, the worth of collateral which currently used for options, priced in USD. 
     */
    function getUnlockedCollateral()public view returns(uint256){
        return safeSubCollateral(getTotalCollateral(),_FPTCoin.getTotalLockedWorth());
    }
    /**
     * @dev The auxiliary function for collateral worth subtraction. 
     */
    function safeSubCollateral(uint256 allCollateral,uint256 subCollateral)internal pure returns(uint256){
        return allCollateral > subCollateral ? allCollateral - subCollateral : 0;
    }
    /**
     * @dev The auxiliary function for calculate option occupied. 
     * @param strikePrice option's strike price
     * @param underlyingPrice option's underlying price
     * @param amount option's amount
     * @param optType option's type, 0 for call, 1 for put.
     */
    function calOptionsOccupied(uint256 strikePrice,uint256 underlyingPrice,uint256 amount,uint8 optType)public view returns(uint256){
        uint256 totalOccupied = 0;
        if ((optType == 0) == (strikePrice>underlyingPrice)){ // call
            totalOccupied = strikePrice*amount;
        } else {
            totalOccupied = underlyingPrice*amount;
        }
        return calculateCollateral(totalOccupied);
    }
    /**
     * @dev Retrieve the total collateral worth, priced in USD. 
     */
    function getTotalCollateral()public view returns(uint256){
        int256 totalNum = 0;
        uint whiteListLen = whiteList.length;
        for (uint256 i=0;i<whiteListLen;i++){
            address addr = whiteList[i];
            int256 price = int256(_oracle.getPrice(addr));
            int256 netWorth = getRealBalance(addr);
            if (netWorth != 0){
                totalNum = totalNum.add(price*netWorth);
            }
        }
        return totalNum>=0 ? uint256(totalNum) : 0;  
    }
    /**
     * @dev Retrieve the balance of collateral, the auxiliary function for the total collateral calculation. 
     */
    function getRealBalance(address settlement)public view returns(int256){
        int256 netWorth = _collateralPool.getNetWorthBalance(settlement);
        int256 latestWorth = _optionsPool.getNetWrothLatestWorth(settlement);
        return netWorth.add(latestWorth);
    }
    function getNetWorthBalance(address settlement)public view returns(uint256){
        int256 netWorth = _collateralPool.getNetWorthBalance(settlement);
        int256 latestWorth = _optionsPool.getNetWrothLatestWorth(settlement);
        netWorth = netWorth.add(latestWorth);
        if (netWorth>0){
            return uint256(netWorth);
        }
        return 0;
    }
    /**
     * @dev the auxiliary function for payback. 
     */
    function _paybackWorth(uint256 worth,uint256 feeType) internal {
        uint256 totalPrice = 0;
        uint whiteLen = whiteList.length;
        uint256[] memory balances = new uint256[](whiteLen);
        uint256 i=0;
        for(;i<whiteLen;i++){
            address addr = whiteList[i];
            if (checkAddressPermission(addr,allowSellOut)){
                uint256 price = _oracle.getPrice(addr);
                balances[i] = getNetWorthBalance(addr);
                //balances[i] = netWorthBalances[addr];
                totalPrice = totalPrice.add(price*balances[i]);
            }
        }
        require(totalPrice>=worth && worth > 0,"payback settlement is insufficient!");
        for (i=0;i<whiteLen;i++){
            uint256 _payBack = balances[i].mul(worth)/totalPrice;
            _collateralPool.transferPaybackAndFee(msg.sender,whiteList[i],_payBack,feeType);
            //addr = whiteList[i];
            //netWorthBalances[addr] = balances[i].sub(_payBack);
            //_transferPaybackAndFee(msg.sender,addr,_payBack,feeType);
        } 
    }
    /**
     * @dev the auxiliary function for getting user's transer
     */
    function getPayableAmount(address settlement,uint256 settlementAmount) internal returns (uint256) {
        require(checkAddressPayIn(settlement) , "settlement is unsupported token");
        uint256 colAmount = 0;
        if (settlement == address(0)){
            colAmount = msg.value;
            address payable poolAddr = address(uint160(address(_collateralPool)));
            poolAddr.transfer(msg.value);
        }else if (settlementAmount > 0){
            IERC20 oToken = IERC20(settlement);
            uint256 preBalance = oToken.balanceOf(address(this));
            oToken.transferFrom(msg.sender, address(this), settlementAmount);
            uint256 afterBalance = oToken.balanceOf(address(this));
            require(afterBalance-preBalance==settlementAmount,"settlement token transfer error!");
            colAmount = settlementAmount;
            oToken.transfer(address(_collateralPool),settlementAmount);
        }
        checkInputAmount(colAmount);
        return colAmount;
    }
    /**
     * @dev collateral occupation rate calculation
     *      collateral occupation rate = sum(collateral Rate * collateral balance) / sum(collateral balance)
     */
    function calculateCollateralRate()public view returns (uint256){
        uint256 totalCollateral = 0;
        uint256 totalRate = 0;
        uint whiteLen = whiteList.length;
        uint256 i=0;
        for(;i<whiteLen;i++){
            address addr = whiteList[i];
             uint256 balance = getNetWorthBalance(addr);
             totalCollateral = totalCollateral.add(balance);
             totalRate = totalRate.add(collateralRate[addr].mul(balance));
        }
        if (totalCollateral > 0){
            return totalRate / totalCollateral;
        }else{
            return 5000;
        }
    }
    /**
     * @dev the auxiliary function for collateral calculation
     */
    function calculateCollateral(uint256 amount)internal view returns (uint256){
        return calculateCollateralRate()*amount/1000;
    }
}