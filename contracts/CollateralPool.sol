
pragma solidity ^0.4.26;
import "./modules/SafeMath.sol";
import "./modules/ReentrancyGuard.sol";
import "./FPOCoin.sol";
import "./modules/underlyingAssets.sol";
import "./modules/TransactionFee.sol";
import "./interfaces/IOptionsPool.sol";
import "./interfaces/IFNXOracle.sol";
import "./modules/Operator.sol";

contract CollateralPool is ReentrancyGuard,TransactionFee,FPOCoin,ImportOracle,ImportOptionsPool,Operator {
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
    event RedeemCollateral(address indexed from,address collateral,uint256 allRedeem);

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
    function getUserTotalWorth(address account)public view returns (uint256){
        return getTokenNetworth().mul(balances[account]).add(lockedTotalWorth[account]);
    }
    function getTokenNetworth() public view returns (uint256){
        if (_totalSupply == 0){
            return 1e8;
        }
        return getUnlockedCollateral()/_totalSupply;
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
        require(checkAddressRedeemOut(collateral) , "settlement is unsupported token");
        require(balances[msg.sender]+lockedBalances[msg.sender]>=tokenAmount,"SCoin balance is insufficient!");
        if (tokenAmount == 0){
            return;
        }
        uint256 leftColateral = getLeftCollateral();
        (uint256 burnAmount,uint256 redeemWorth) = _redeemLockedCollateral(tokenAmount,leftColateral);
        tokenAmount -= burnAmount;
        if (tokenAmount > 0){
            leftColateral -= redeemWorth;
            (uint256 newRedeem,uint256 newWorth) = _redeemCollateral(tokenAmount,leftColateral);
            if(newRedeem>0){
                _burn(msg.sender, newRedeem);
                burnAmount += newRedeem;
                redeemWorth += newWorth;
            }
        }
        emit DebugEvent(22222,redeemWorth,burnAmount);
        _redeemCollateralWorth(collateral,redeemWorth);
    }
    function _redeemLockedCollateral(uint256 tokenAmount,uint256 leftColateral)internal returns (uint256,uint256){
        (uint256 lockedAmount,uint256 lockedWorth) = getLockedBalance(msg.sender);
        if (lockedAmount == 0){
            return (0,0);
        }
        uint256 redeemWorth = 0;
        uint256 lockedBurn = 0;
        uint256 lockedPrice = lockedWorth/lockedAmount;
        if (lockedAmount >= tokenAmount){
            lockedBurn = tokenAmount;
            redeemWorth = tokenAmount.mul(lockedPrice);
        }else{
            lockedBurn = lockedAmount;
            redeemWorth = lockedWorth;
        }
        if (redeemWorth > leftColateral) {
            lockedBurn = leftColateral.div(lockedPrice);
            redeemWorth = lockedBurn.mul(lockedPrice);
        }
        if (lockedBurn > 0){
            _burnLocked(msg.sender,lockedBurn);
            return (lockedBurn,redeemWorth);
        }
        return (0,0);
    }
    function _redeemCollateral(uint256 leftAmount,uint256 leftColateral)internal returns (uint256,uint256){
        uint256 tokenNetWorth = getTokenNetworth();
        uint256 leftWorth = leftAmount.mul(tokenNetWorth);        
        if (leftWorth > leftColateral){
            uint256 newRedeem = leftColateral.div(tokenNetWorth);
            uint256 newWorth = newRedeem.mul(tokenNetWorth);
            uint256 locked = leftAmount - newRedeem;
            addlockBalance(msg.sender,locked,locked.mul(tokenNetWorth));
            return (newRedeem,newWorth);
        }
        return (leftAmount,leftWorth);
    }
    function _redeemCollateralWorth(address collateral,uint256 redeemWorth) internal {
        uint256 allRedeem = redeemWorth;
        (uint256[] memory colBalances,uint256[] memory PremiumBalances,uint256[] memory prices) = _getCollateralAndPremiumBalances(msg.sender,collateral);
        address[] memory tmpWhiteList = whiteList;
        uint256 ln = whiteListAddress._getEligibleIndexAddress(tmpWhiteList,collateral);
        if (ln != 0){
            tmpWhiteList[ln] = tmpWhiteList[0];
            tmpWhiteList[0] = collateral;
        }
        ln = tmpWhiteList.length;
        uint256[] memory PaybackBalances = new uint256[](ln);
        for (uint256 i=0; i<ln && redeemWorth>0;i++){
            address addr = tmpWhiteList[i];
            uint256 totalWorth = prices[i].mul(colBalances[i]);
            emit DebugEvent(1111,redeemWorth,totalWorth);
            if (redeemWorth < totalWorth){
                uint256 amount = redeemWorth.div(prices[i]);
                userInputCollateral[msg.sender][addr] = userInputCollateral[msg.sender][addr].mul(totalWorth-redeemWorth).div(totalWorth);
                PaybackBalances[i] = amount;
                redeemWorth = 0;
                break;
            }else{
                userInputCollateral[msg.sender][addr] = 0;
                PaybackBalances[i] = colBalances[i];
                redeemWorth = redeemWorth - totalWorth;
            }
        }
        if (redeemWorth>0) {
           totalWorth = 0;
            for (i=0; i<ln;i++){
                totalWorth = totalWorth.add(PremiumBalances[i].mul(prices[i]));
            }
            for (i=0; i<ln;i++){
                PaybackBalances[i] = PaybackBalances[i].add(PremiumBalances[i].mul(redeemWorth).div(totalWorth));
            }
        }
        i = whiteListAddress._getEligibleIndexAddress(whiteList,collateral);
        if (i!= 0) {
            amount = PaybackBalances[i];
            PaybackBalances[i] = PaybackBalances[0];
            PaybackBalances[0] = amount;
        }
        for (i=0;i<ln;i++){ 
            emit DebugEvent(1111,allRedeem,PaybackBalances[i]);
            _transferPaybackAndFee(msg.sender,whiteList[i],PaybackBalances[i],redeemColFee);
        } 
        emit RedeemCollateral(msg.sender,collateral,allRedeem);
    }
    /*
    function _redeemCollateralWorth(address account,address collateral,uint256 redeemWorth)public view returns(uint256[]){
        uint256[] memory colBalances = new uint256[](whiteLen);
        uint256[] memory PremiumBalances = new uint256[](whiteLen);
        uint256 totalWorth = 0;
        uint256 PremiumWorth = 0;
        uint256 worth = getUserTotalWorth(account);
        for (uint256 i=0; i<whiteLen;i++){
            address addr = whiteList[i];
            uint256 amount = userInputCollateral[msg.sender][addr];
            colBalances[i] = collateralBalances[addr].mul(amount).div(netWorthBalances[addr]);
            PremiumBalances[i] = netWorthBalances[addr].sub(colBalances[i]);
            uint256 price = _oracle.getPrice(addr);
            totalWorth = totalWorth.add(price.mul(colBalances[i]));
            PremiumWorth = PremiumWorth.add(price.mul(PremiumBalances[i]));
        }
        if (totalWorth >= worth){
            for (uint256 i=0; i<whiteLen;i++){
                colBalances[i] = colBalances[i].mul(worth).div(totalWorth);
            }
            worth = 0;
        }else{
            worth = worth - totalWorth;
        }

        {
            for (uint256 i=0; i<whiteLen;i++){
                PremiumBalances[i] = PremiumBalances[i].mul(worth).div(totalWorth);
            }
        }
        return colBalances;
    }
    function _redeemCollateralTrans(address collateral,uint256 redeemWorth,uint256 limitAmount){
        uint256 price = _oracle.getPrice(collateral);
        uint256 payback = limitAmount.mul(price);
        if (payback > collateral){
            
        }

    }
    function _redeemCollateralWorth(uint256 tokenAmount,address collateral,uint256 redeemWorth,uint256 tokenNetWorth) internal {
        uint256 allRedeem = redeemWorth;
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
        emit RedeemCollateral(msg.sender,tokenAmount,allRedeem);
    }
    */
    function calCollateralWorth(address account)public view returns(uint256[]){
        (uint256[] memory colBalances,uint256[] memory PremiumBalances,) = _getCollateralAndPremiumBalances(account,whiteList[0]);
        uint256 whiteLen = whiteList.length;
        for (uint256 i=0; i<whiteLen;i++){
            colBalances[i] = colBalances[i].add(PremiumBalances[i]);
        }
        return colBalances;
    }
    function _getCollateralAndPremiumBalances(address account,address priorCollateral) internal view returns(uint256[],uint256[],uint256[]){
        address[] memory tmpWhiteList = whiteList;
        uint256 ln = whiteListAddress._getEligibleIndexAddress(tmpWhiteList,priorCollateral);
        if (ln != 0){
            tmpWhiteList[ln] = tmpWhiteList[0];
            tmpWhiteList[0] = priorCollateral;
        }
        ln = tmpWhiteList.length;
        uint256[] memory colBalances = new uint256[](ln);
        uint256[] memory PremiumBalances = new uint256[](ln);
        uint256[] memory prices = new uint256[](ln);
        uint256 totalWorth = 0;
        uint256 PremiumWorth = 0;
        uint256 worth = getUserTotalWorth(account);
        for (uint256 i=0; i<ln;i++){
            (colBalances[i],PremiumBalances[i]) = _calBalanceRate(collateralBalances[tmpWhiteList[i]],netWorthBalances[tmpWhiteList[i]],userInputCollateral[msg.sender][tmpWhiteList[i]]);
            prices[i] = _oracle.getPrice(tmpWhiteList[i]);
            totalWorth = totalWorth.add(prices[i].mul(colBalances[i]));
            PremiumWorth = PremiumWorth.add(prices[i].mul(PremiumBalances[i]));
        }
        if (totalWorth >= worth){
            for (i=0; i<ln;i++){
                colBalances[i] = colBalances[i].mul(worth).div(totalWorth);
            }
        }else{
            worth = worth - totalWorth;
            for (i=0; i<ln;i++){
                PremiumBalances[i] = PremiumBalances[i].mul(worth).div(PremiumWorth);
            }
        }
        return (colBalances,PremiumBalances,prices);
    } 
    function _calBalanceRate(uint256 collateralBalance,uint256 netWorthBalance,uint256 amount)internal pure returns(uint256,uint256){
        uint256 curAmount = netWorthBalance.mul(amount).div(collateralBalance);
        return (curAmount,netWorthBalance.sub(curAmount));
    }
    /*
    function _calPremiumPayback(uint256 worth,uint256 whiteLen,uint256[] memory paybackcal)internal view returns(uint256[] memory){
        uint256 totalPrice = 0;
        uint256[] memory PremiumBalances = new uint256[](whiteLen);
        for (uint256 i=0; i<whiteLen;i++){
            address addr = whiteList[i];
            uint256 amount = userInputCollateral[msg.sender][collateral];
            amount = collateralBalances[collateral].mul(amount).div(netWorthBalances[collateral]);
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
        */
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
        return getTotalCollateral().sub(_totalLockedWorth);
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
            totalPrice = totalPrice.add(price.mul(balances[i]));
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
        require(checkAddressPayIn(settlement) , "settlement is unsupported token");
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