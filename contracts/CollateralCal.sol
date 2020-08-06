pragma solidity ^0.4.26;
import "./modules/SafeMath.sol";
import "./modules/SafeInt256.sol";
import "./modules/AddressWhiteList.sol";
import "./modules/ReentrancyGuard.sol";
import "./interfaces/IOptionsPool.sol";
import "./interfaces/IFNXOracle.sol";
import "./interfaces/ICollateralPool.sol";
import "./interfaces/IFPTCoin.sol";
import "./modules/Operator.sol";
import "./interfaces/IERC20.sol";
contract CollateralCal is ReentrancyGuard,AddressWhiteList,ImportIFPTCoin,ImportOracle,ImportOptionsPool,ImportCollateralPool,Operator {
    using SafeMath for uint256;
    using SafeInt256 for int256;
    uint256 private collateralRate = 5000;

    event AddCollateral(address indexed from,address indexed collateral,uint256 amount,uint256 tokenAmount);
    event RedeemCollateral(address indexed from,address collateral,uint256 allRedeem);
    event DebugEvent(int256 value1,uint256 value2,int256 value3);
    uint256 internal maxAmount = 1e30;
    uint256 internal minAmount = 1e9;
    function getInputAmountRange() public view returns(uint256,uint256) {
        return (minAmount,maxAmount);
    }
    function setInputAmountRange(uint256 _minAmount,uint256 _maxAmount) public onlyOwner{
        minAmount = _minAmount;
        maxAmount = _maxAmount;
    }
    function checkInputAmount(uint256 Amount)internal view{
        require(maxAmount>=Amount && minAmount<=Amount,"input amount is out of input amount range");
    }
    function addNetBalance(address settlement,uint256 amount) public payable onlyOperatorIndex(1) {
        amount = getPayableAmount(settlement,amount);
        _collateralPool.addNetWorthBalance(settlement,int256(amount));
//        netWorthBalances[settlement] = netWorthBalances[settlement].add(amount);
    }

    function setCollateralRate(uint256 colRate) public onlyOwner {
        collateralRate = colRate;

    }
    function getCollateralRate()public view returns (uint256) {
        return collateralRate;
    }
    function getUserPayingUsd(address user)public view returns (uint256){
        return _collateralPool.getUserPayingUsd(user);
        //userCollateralPaying[user];
    }
    function userInputCollateral(address user,address collateral)public view returns (uint256){
        _collateralPool.getUserInputCollateral(user,collateral);
        //return userInputCollateral[user][collateral];
    }
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
    function setSharedPayment(int256[] newNetworth,int256[] sharedBalances,uint256 firstOption) public onlyOperatorIndex(0){
        _optionsPool.setSharedState(firstOption,sharedBalances,whiteList);
        _collateralPool.addNetWorthBalances(whiteList,newNetworth);
    }
    function getUserTotalWorth(address account)public view returns (uint256){
        return getTokenNetworth().mul(_FPTCoin.balanceOf(account)).add(_FPTCoin.lockedWorthOf(account));
    }
    function getTokenNetworth() public view returns (uint256){
        uint256 _totalSupply = _FPTCoin.totalSupply();
        if (_totalSupply == 0){
            return 1e8;
        }
        uint256 netWorth = getUnlockedCollateral()/_totalSupply;
        return netWorth>100 ? netWorth : 100;
    }
    function addCollateral(address collateral,uint256 amount) nonReentrant notHalted public payable {
        amount = getPayableAmount(collateral,amount);
        uint256 fee = _collateralPool.addTransactionFee(collateral,amount,3);
        amount = amount-fee;
        uint256 price = _oracle.getPrice(collateral);
        uint256 userPaying = price*amount;
        uint256 mintAmount = userPaying/getTokenNetworth();
        _collateralPool.addUserPayingUsd(msg.sender,userPaying);
        //userCollateralPaying[msg.sender] = userCollateralPaying[msg.sender].add(userPaying);
        _collateralPool.addCollateralBalance(collateral,amount);
        //collateralBalances[collateral] = collateralBalances[collateral].add(amount);
        _collateralPool.addUserInputCollateral(msg.sender,collateral,amount);
        //userInputCollateral[msg.sender][collateral] = userInputCollateral[msg.sender][collateral].add(amount);
        _collateralPool.addNetWorthBalance(collateral,int256(amount));
        //netWorthBalances[collateral] = netWorthBalances[collateral].add(amount);
        emit AddCollateral(msg.sender,collateral,amount,mintAmount);
        _FPTCoin.mint(msg.sender,mintAmount);
    }
    //calculate token
    function redeemCollateral(uint256 tokenAmount,address collateral) nonReentrant notHalted public {
        checkInputAmount(tokenAmount);
        require(checkAddressRedeemOut(collateral) , "settlement is unsupported token");
        uint256 lockedAmount = _FPTCoin.lockedBalanceOf(msg.sender);
        require(_FPTCoin.balanceOf(msg.sender)+lockedAmount>=tokenAmount,"SCoin balance is insufficient!");
        uint256 userTotalWorth = getUserTotalWorth(msg.sender);
        uint256 leftColateral = getLeftCollateral();
        (uint256 burnAmount,uint256 redeemWorth) = _FPTCoin.redeemLockedCollateral(msg.sender,tokenAmount,leftColateral);
        tokenAmount -= burnAmount;
        burnAmount = 0;
        if (tokenAmount > 0){
            leftColateral -= redeemWorth;
            
            if (lockedAmount > 0){
                tokenAmount = tokenAmount > lockedAmount ? tokenAmount - lockedAmount : 0;
            }
            (uint256 newRedeem,uint256 newWorth) = _redeemCollateral(tokenAmount,leftColateral);
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
    function _redeemCollateral(uint256 leftAmount,uint256 leftColateral)internal returns (uint256,uint256){
        uint256 tokenNetWorth = getTokenNetworth();
        uint256 leftWorth = leftAmount*tokenNetWorth;        
        if (leftWorth > leftColateral){
            uint256 newRedeem = leftColateral/tokenNetWorth;
            uint256 newWorth = newRedeem*tokenNetWorth;
            uint256 locked = leftAmount - newRedeem;
            _FPTCoin.addlockBalance(msg.sender,locked,locked/tokenNetWorth);
            return (newRedeem,newWorth);
        }
        return (leftAmount,leftWorth);
    }
    function getTempWhiteList(address collateral) internal view returns (address[] memory) {
        address[] memory tmpWhiteList = whiteList;
        uint256 index = whiteListAddress._getEligibleIndexAddress(tmpWhiteList,collateral);
        if (index != 0){
            tmpWhiteList[index] = tmpWhiteList[0];
            tmpWhiteList[0] = collateral;
        }
        return tmpWhiteList;
    }
    function _redeemCollateralWorth(address collateral,uint256 redeemWorth,uint256 userTotalWorth) internal {
        if (redeemWorth == 0){
            return;
        }
        emit RedeemCollateral(msg.sender,collateral,redeemWorth);
        (uint256[] memory colBalances,uint256[] memory PremiumBalances,uint256[] memory prices) = _getCollateralAndPremiumBalances(msg.sender,collateral,userTotalWorth);
        address[] memory tmpWhiteList = getTempWhiteList(collateral);
        _collateralPool.transferPaybackBalances(msg.sender,redeemWorth,tmpWhiteList,colBalances,
                PremiumBalances,prices);
    }

    function calCollateralWorth(address account)public view returns(uint256[]){
        uint256 worth = getUserTotalWorth(account);
        (uint256[] memory colBalances,uint256[] memory PremiumBalances,) = _getCollateralAndPremiumBalances(account,whiteList[0],worth);
        uint256 whiteLen = whiteList.length;
        for (uint256 i=0; i<whiteLen;i++){
            colBalances[i] = colBalances[i].add(PremiumBalances[i]);
        }
        return colBalances;
    }
    function _getCollateralAndPremiumBalances(address account,address priorCollateral,uint256 userTotalWorth) internal view returns(uint256[],uint256[],uint256[]){
        address[] memory tmpWhiteList = getTempWhiteList(priorCollateral);
        uint256[] memory prices = new uint256[](tmpWhiteList.length);
        uint256[] memory netWorthBalances = new uint256[](tmpWhiteList.length);
        for (uint256 i=0; i<tmpWhiteList.length;i++){
            netWorthBalances[i] = getNetWorthBalance(tmpWhiteList[i]);
            prices[i] = _oracle.getPrice(tmpWhiteList[i]);
        }
        (uint256[] memory colBalances,uint256[] memory PremiumBalances) = _collateralPool.getCollateralAndPremiumBalances(account,userTotalWorth,tmpWhiteList,
                netWorthBalances,prices);
        return (colBalances,PremiumBalances,prices);
    } 
    /*
    function _calBalanceRate(uint256 collateralBalance,uint256 netWorthBalance,uint256 amount)internal pure returns(uint256,uint256){
        if (collateralBalance > 0){
            uint256 curAmount = netWorthBalance.mul(amount).div(collateralBalance);
            return (curAmount,netWorthBalance.sub(curAmount));
        }else{
            return (0,netWorthBalance);
        }
    }
*/
    function getOccupiedCollateral() public view returns(uint256){
        uint256 totalOccupied = _optionsPool.getTotalOccupiedCollateral();
        return calculateCollateral(totalOccupied);
    }
    function getAvailableCollateral()public view returns(uint256){
        return safeSubCollateral(getUnlockedCollateral(),getOccupiedCollateral());
    }
    function getLeftCollateral()public view returns(uint256){
        return safeSubCollateral(getTotalCollateral(),getOccupiedCollateral());
    }
    function getUnlockedCollateral()public view returns(uint256){
        return safeSubCollateral(getTotalCollateral(),_FPTCoin.getTotalLockedWorth());
    }
    function safeSubCollateral(uint256 allCollateral,uint256 subCollateral)internal pure returns(uint256){
        return allCollateral > subCollateral ? allCollateral - subCollateral : 0;
    }
    function calOptionsOccupied(uint256 strikePrice,uint256 underlyingPrice,uint256 amount,uint8 optType)public view returns(uint256){
        uint256 totalOccupied = 0;
        if ((optType == 0) == (strikePrice>underlyingPrice)){ // call
            totalOccupied = strikePrice*amount;
        } else {
            totalOccupied = underlyingPrice*amount;
        }
        return calculateCollateral(totalOccupied);
    }
    function getTotalCollateral()public view returns(uint256){
        int256 totalNum = 0;
        uint whiteListLen = whiteList.length;
        for (uint256 i=0;i<whiteListLen;i++){
            address addr = whiteList[i];
            int256 price = int256(_oracle.getPrice(addr));
            int256 netWorth = getRealBalance(addr);
            if (netWorth != 0){
                totalNum = totalNum.add(price.mul(netWorth));
            }
            //totalNum = totalNum.add(price.mul(netWorthBalances[addr]));
        }
        return totalNum>=0 ? uint256(totalNum) : 0;  
    }
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
    function _paybackWorth(uint256 worth,uint256 feeType) internal {
        uint256 totalPrice = 0;
        uint whiteLen = whiteList.length;
        uint256[] memory balances = new uint256[](whiteLen);
        for (uint256 i=0;i<whiteLen;i++){
            address addr = whiteList[i];
            uint256 price = _oracle.getPrice(addr);
            balances[i] = getNetWorthBalance(addr);
            //balances[i] = netWorthBalances[addr];
            totalPrice = totalPrice.add(price.mul(balances[i]));
        }
        if (totalPrice == 0){
            return;
        }
        for (i=0;i<whiteLen;i++){
            uint256 _payBack = balances[i].mul(worth)/totalPrice;
            _collateralPool.transferPaybackAndFee(msg.sender,whiteList[i],_payBack,feeType);
            //addr = whiteList[i];
            //netWorthBalances[addr] = balances[i].sub(_payBack);
            //_transferPaybackAndFee(msg.sender,addr,_payBack,feeType);
        } 
    }
    function getPayableAmount(address settlement,uint256 settlementAmount) internal returns (uint256) {
        require(checkAddressPayIn(settlement) , "settlement is unsupported token");
        uint256 colAmount = 0;
        if (settlement == address(0)){
            colAmount = msg.value;
            address(_collateralPool).transfer(msg.value);
        }else if (settlementAmount > 0){
            IERC20 oToken = IERC20(settlement);
            oToken.transferFrom(msg.sender, address(this), settlementAmount);
            colAmount = settlementAmount;
             oToken.transfer(address(_collateralPool),settlementAmount);
        }
        checkInputAmount(colAmount);
        return colAmount;
    }
    function calculateCollateral(uint256 amount)internal view returns (uint256){
        return collateralRate.mul(amount)/1000;
    }
}