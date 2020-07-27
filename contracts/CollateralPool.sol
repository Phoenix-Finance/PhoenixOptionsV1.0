pragma solidity ^0.4.26;
import "./modules/SafeMath.sol";
import "./modules/ReentrancyGuard.sol";
import "./SharedCoin.sol";
import "./modules/underlyingAssets.sol";
import "./modules/TransactionFee.sol";
import "./interfaces/IOptionsPool.sol";
import "./interfaces/IFNXOracle.sol";
import "./modules/Operator.sol";
contract CollateralPool is ReentrancyGuard,TransactionFee,SharedCoin,ImportOracle,ImportOptionsPool,Operator {
    using SafeMath for uint256;
    fraction public collateralRate = fraction(3, 1);
    //token net worth
    mapping (address => uint256) public netWorthBalances;
    //address collaterel
    mapping (address => uint256) public collateralBalances;
    //user paying for collateral usd;
    mapping (address => uint256) public userCollateralPaying;
    //account -> collateral -> amount
    mapping (address => mapping (address => uint256)) public userInputCollateral;

    event AddCollateral(address indexed from,address indexed collateral,uint256 amount,uint256 tokenAmount);
    event RedeemCollateral(address indexed from,uint256 tokenAmount);

    event DebugEvent(uint256 indexed value1,uint256 indexed value2,uint256 indexed value3);

    function setCollateralRate(uint256 numerator,uint256 denominator) public onlyOwner {
        collateralRate.numerator = numerator;
        collateralRate.denominator = denominator;
    }
    function getCollateralRate()public view returns (uint256,uint256) {
        return (collateralRate.numerator,collateralRate.denominator);
    }
    function getUserPayingUsd(address user)public view returns (uint256){
        return userCollateralPaying[user];
    }
    function userInputCollateral(address user,address collateral)public view returns (uint256){
        return userInputCollateral[user][collateral];
    }
    function setPhaseSharedPayment(uint256 calInfo) public onlyOperator {
        (uint256[] memory sharedBalances,uint256 firstOption,bool success) =
             _optionsPool.calculatePhaseSharedPayment(calInfo,whiteList);
        if (success){
            (int256[] memory fallBalance,uint256[] memory prices) = _optionsPool.calculatePhaseOptionsFall(calInfo,whiteList);
            for (uint256 i= 0;i<fallBalance.length;i++){
                fallBalance[i] += int256(sharedBalances[i]);
            }
            setSharedPayment(calInfo,fallBalance,prices,firstOption,now);
        }
    }
    function setSharedPayment(uint256 calInfo,int256[] sharedBalances,uint256[] prices,uint256 firstOption,uint256 calTime) public onlyOperator{
        _optionsPool.setSharedState(calInfo,firstOption,prices,calTime);
        for (uint i=0;i<sharedBalances.length;i++){
            address addr = whiteList[i];
            if(sharedBalances[i]>=0){
                netWorthBalances[addr] = netWorthBalances[addr].add(uint256(sharedBalances[i]));
            }else{
                netWorthBalances[addr] = netWorthBalances[addr].sub(uint256(-sharedBalances[i]));
            }
        }
    }
    function getTokenNetworth() public view returns (uint256){
        if (_totalSupply == 0){
            return 1e8;
        }
        return getTotalCollateral()/_totalSupply;
    }
    function addCollateral(address collateral,uint256 amount)public payable {
        amount = getPayableAmount(collateral,amount);
        require(amount>0 , "settlement amount is zero!");
        uint256 fee = calculateFee(addColFee,amount);
        _addTransactionFee(collateral,fee);
        amount = amount.sub(fee);
        uint256 price = _oracle.getPrice(collateral);
        uint256 userPaying = price.mul(amount);
        uint256 mintAmount = userPaying.div(getTokenNetworth());
        userCollateralPaying[msg.sender] = userCollateralPaying[msg.sender].add(userPaying);
        collateralBalances[collateral] = collateralBalances[collateral].add(amount);
        userInputCollateral[msg.sender][collateral] = userInputCollateral[msg.sender][collateral].add(amount);
        netWorthBalances[collateral] = netWorthBalances[collateral].add(amount);
        emit AddCollateral(msg.sender,collateral,amount,mintAmount);
        _mint(msg.sender,mintAmount);
    }
    //calculate token
    function redeemCollateral(uint256 tokenAmount,address collateral)public {
        require(isEligibleAddress(collateral) , "settlement is unsupported token");
        require(balances[msg.sender]>=tokenAmount,"SCoin balance is insufficient!");
        if (tokenAmount == 0){
            return;
        }
        uint256 leftColateral = getLeftCollateral();
        uint256 tokenNetWorth = getTokenNetworth();
        uint256 redeemWorth = tokenAmount.mul(tokenNetWorth);
        uint256 locked = redeemWorth > leftColateral ? redeemWorth - leftColateral : 0;
        emit DebugEvent(1111,leftColateral,tokenNetWorth);
        emit DebugEvent(1111,redeemWorth,locked);
        return;
        if (locked > 0){
            locked = tokenAmount.sub(leftColateral.div(tokenNetWorth));
            tokenAmount = tokenAmount.sub(locked);
            redeemWorth = tokenAmount.mul(tokenNetWorth);
        }
        _redeemCollateral(tokenAmount,collateral,redeemWorth,tokenNetWorth);
        lockBalance(msg.sender,locked);
    }
    function _redeemCollateral(uint256 tokenAmount,address collateral,uint256 redeemWorth,uint256 tokenNetWorth) internal {
        uint256 redeemPaying = userCollateralPaying[msg.sender].mul(tokenAmount).div(balances[msg.sender]);
        userCollateralPaying[msg.sender] = userCollateralPaying[msg.sender].sub(redeemPaying);
        _burn(msg.sender, tokenAmount);
        uint whiteLen = whiteList.length;
        uint256[] memory paybackcal = new uint256[](whiteLen);
        uint256 payBack;
        (redeemWorth,payBack) = _calPayBackCollateral(redeemWorth,collateral,tokenNetWorth);
        uint256 index = whiteListAddress._getEligibleIndexAddress(whiteList,collateral);
        paybackcal[index] = payBack;
        for (uint256 i=0;redeemWorth>0 && i<whiteLen;i++){
            (redeemWorth,payBack) = _calPayBackCollateral(redeemWorth,whiteList[i],tokenNetWorth);  
            paybackcal[i] += payBack;
        } 
        if (redeemWorth > 0){
            paybackcal = _calPremiumPayback(redeemWorth,whiteLen,paybackcal);
        }
        for (i=0;i<whiteLen;i++){
            _transferPaybackAndFee(msg.sender,whiteList[i],paybackcal[i],redeemColFee);
        } 
        emit RedeemCollateral(msg.sender,tokenAmount);
    }
    function _calPremiumPayback(uint256 worth,uint256 whiteLen,uint256[] memory paybackcal)internal view returns(uint256[] memory){
        uint256 totalPrice = 0;
        uint256[] memory PremiumBalances = new uint256[](whiteLen);
        for (uint256 i=0; i<whiteLen;i++){
            address addr = whiteList[i];
            PremiumBalances[i] = netWorthBalances[addr].sub(paybackcal[i]);
            uint256 price = _oracle.getPrice(addr);
            totalPrice.add(price.mul(PremiumBalances[i]));
        } 
                
        if (totalPrice == 0){
            return;
        }
        for (i=0;i<whiteLen;i++){
            paybackcal[i] = paybackcal[i].add(PremiumBalances[i].mul(worth).div(totalPrice));
        } 
        return paybackcal;
    }
    function _calPayBackCollateral(uint256 worth,address collateral,uint256 tokenNetWorth)internal view returns (uint256,uint256){
        uint256 amount = userInputCollateral[msg.sender][collateral];
        if (amount == 0){
            return (worth,0);
        }
        uint netAmount = tokenNetWorth.mul(amount);
        amount = collateralBalances[collateral].mul(amount).div(netWorthBalances[collateral]);
        if (netAmount<amount){
            amount = netAmount;
        }
        if (amount == 0){
            return (worth,0);
        }
        uint256 price = _oracle.getPrice(collateral);
        uint256 redeemAmount = worth.div(price);
        if (redeemAmount == 0){
            return (0,0);
        }
        uint256 transferAmount = (redeemAmount>amount) ? amount : redeemAmount;
        if (redeemAmount>amount){
            return (worth.sub(transferAmount.mul(price)),transferAmount);
        }
        return (0,transferAmount);
    }
    function getOccupiedCollateral() public view returns(uint256){
        uint256 totalOccupied = _optionsPool.getTotalOccupiedCollateral();
        return calculateCollateral(totalOccupied);
    }
    function getAvailableCollateral()public view returns(uint256){
        return getUnlockedCollateral().sub(getOccupiedCollateral());
    }
    function getLeftCollateral()public view returns(uint256){
        return getTotalCollateral().sub(getOccupiedCollateral());
    }
    function calOptionsOccupied(uint256 strikePrice,uint256 underlyingPrice,uint256 amount,uint8 optType)public view returns(uint256){
        uint256 totalOccupied = 0;
        if ((optType == 0) == (strikePrice>underlyingPrice)){ // call
            totalOccupied = strikePrice.mul(amount);
        } else {
            totalOccupied = underlyingPrice.mul(amount);
        }
        return calculateCollateral(totalOccupied);
    }
    function getUnlockedCollateral()public view returns(uint256){
        return (_totalSupply.sub(_totalLocked)).mul(getTotalCollateral()).div(_totalSupply);
    }
    function getTotalCollateral()public view returns(uint256){
        uint256 totalNum = 0;
        uint whiteListLen = whiteList.length;
        for (uint256 i=0;i<whiteListLen;i++){
            address addr = whiteList[i];
            uint256 price = _oracle.getPrice(addr);
            totalNum = totalNum.add(price.mul(netWorthBalances[addr]));
        }
        return totalNum;  
    }

    function _paybackWorth(uint256 worth,uint256 feeType) internal {
        uint256 totalPrice = 0;
        uint whiteLen = whiteList.length;
        uint256[] memory balances = new uint256[](whiteLen);
        for (uint256 i=0;i<whiteLen;i++){
            address addr = whiteList[i];
            uint256 price = _oracle.getPrice(addr);
            balances[i] = netWorthBalances[addr];
            totalPrice.add(price.mul(balances[i]));
        }
        if (totalPrice == 0){
            return;
        }
        for (i=0;i<whiteLen;i++){
            uint256 _payBack = balances[i].mul(worth).div(totalPrice);
            netWorthBalances[addr] = balances[i].sub(_payBack);
            _transferPaybackAndFee(msg.sender,addr,_payBack,feeType);
        } 
    }
    function getPayableAmount(address settlement,uint256 settlementAmount) internal returns (uint256) {
        require(isEligibleAddress(settlement) , "settlement is unsupported token");
        uint256 colAmount = 0;
        if (settlement == address(0)){
            colAmount = msg.value;
        }else if (settlementAmount > 0){
            IERC20 oToken = IERC20(settlement);
            oToken.transferFrom(msg.sender, address(this), settlementAmount);
            colAmount = settlementAmount;
        }
        return colAmount;
    }
    function calculateCollateral(uint256 amount)internal view returns (uint256){
        uint256 result = collateralRate.numerator.mul(amount);
        return result.div(collateralRate.denominator);
    }

}