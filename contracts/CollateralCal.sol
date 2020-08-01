
pragma solidity ^0.4.26;
import "./modules/SafeMath.sol";
import "./modules/ReentrancyGuard.sol";
import "./modules/underlyingAssets.sol";
import "./modules/TransactionFee.sol";
import "./interfaces/IOptionsPool.sol";
import "./interfaces/IFNXOracle.sol";
import "./interfaces/ICollateralPool.sol";
import "./interfaces/IFPTCoin.sol";
import "./modules/Operator.sol";

contract CollateralCal is ReentrancyGuard,TransactionFee,ImportIFPTCoin,ImportOracle,ImportOptionsPool,ImportCollateralPool,Operator {
    using SafeMath for uint256;
    fraction public collateralRate = fraction(5, 1);
 
    event AddCollateral(address indexed from,address indexed collateral,uint256 amount,uint256 tokenAmount);
    event RedeemCollateral(address indexed from,address collateral,uint256 allRedeem);

    event DebugEvent(uint256 indexed value1,uint256 indexed value2,uint256 indexed value3);

    function addNetBalance(address settlement,uint256 amount) public payable onlyOperatorIndex(1) {
        _collateralPool.addNetWorthBalance(settlement,amount);
//        netWorthBalances[settlement] = netWorthBalances[settlement].add(amount);
    }
    function setCollateralRate(uint256 numerator,uint256 denominator) public onlyOwner {
        collateralRate.numerator = numerator;
        collateralRate.denominator = denominator;
    }
    function getCollateralRate()public view returns (uint256,uint256) {
        return (collateralRate.numerator,collateralRate.denominator);
    }
    function getUserPayingUsd(address user)public view returns (uint256){
        return _collateralPool.getUserPayingUsd(user);
        //userCollateralPaying[user];
    }
    function userInputCollateral(address user,address collateral)public view returns (uint256){
        _collateralPool.userInputCollateral(user,collateral);
        //return userInputCollateral[user][collateral];
    }
    function setPhaseSharedPayment(uint256 calInfo) public onlyOperatorIndex(0) {
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
    function setSharedPayment(uint256 calInfo,int256[] sharedBalances,uint256[] prices,uint256 firstOption,uint256 calTime) public onlyOperatorIndex(0){
        _optionsPool.setSharedState(calInfo,firstOption,prices,calTime);
        for (uint i=0;i<sharedBalances.length;i++){
            address addr = whiteList[i];
            if(sharedBalances[i]>=0){
                _collateralPool.addNetWorthBalance(addr,uint256(sharedBalances[i]));
//                netWorthBalances[addr] = netWorthBalances[addr].add(uint256(sharedBalances[i]));
            }else{
                _collateralPool.subNetWorthBalance(addr,uint256(-sharedBalances[i]));
//                netWorthBalances[addr] = netWorthBalances[addr].sub(uint256(-sharedBalances[i]));
            }
        }
    }
    function getUserTotalWorth(address account)public view returns (uint256){
        return getTokenNetworth().mul(_FPTCoin.balanceOf(account)).add(_FPTCoin.lockedWorthOf(account));
    }
    function getTokenNetworth() public view returns (uint256){
        uint256 _totalSupply = _FPTCoin.totalSupply();
        if (_totalSupply == 0){
            return 1e8;
        }
        return getUnlockedCollateral()/_totalSupply;
    }
    function addCollateral(address collateral,uint256 amount) nonReentrant notHalted public payable {
        amount = getPayableAmount(collateral,amount);
        require(amount>0 , "settlement amount is zero!");
        uint256 fee = calculateFee(addColFee,amount);
        _addTransactionFee(collateral,fee);
        amount = amount.sub(fee);
        uint256 price = _oracle.getPrice(collateral);
        uint256 userPaying = price.mul(amount);
        uint256 mintAmount = userPaying.div(getTokenNetworth());
        _collateralPool.addUserPayingUsd(msg.sender,userPaying);
        //userCollateralPaying[msg.sender] = userCollateralPaying[msg.sender].add(userPaying);
        _collateralPool.addCollateralBalance(collateral,amount);
        //collateralBalances[collateral] = collateralBalances[collateral].add(amount);
        _collateralPool.addUserInputCollateral(msg.sender,collateral,amount);
        //userInputCollateral[msg.sender][collateral] = userInputCollateral[msg.sender][collateral].add(amount);
        _collateralPool.addNetWorthBalance(collateral,amount);
        //netWorthBalances[collateral] = netWorthBalances[collateral].add(amount);
        emit AddCollateral(msg.sender,collateral,amount,mintAmount);
        _FPTCoin.mint(msg.sender,mintAmount);
    }
    //calculate token
    function redeemCollateral(uint256 tokenAmount,address collateral) nonReentrant notHalted public {
        require(checkAddressRedeemOut(collateral) , "settlement is unsupported token");
        uint256 lockedAmount = _FPTCoin.lockedBalanceOf(msg.sender);
        require(_FPTCoin.balanceOf(msg.sender)+lockedAmount>=tokenAmount,"SCoin balance is insufficient!");
        if (tokenAmount == 0){
            return;
        }
        uint256 userTotalWorth = getUserTotalWorth(msg.sender);
        uint256 leftColateral = getLeftCollateral();
        (uint256 burnAmount,uint256 redeemWorth) = _redeemLockedCollateral(tokenAmount,leftColateral);
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
    function _redeemLockedCollateral(uint256 tokenAmount,uint256 leftColateral)internal returns (uint256,uint256){
        if (leftColateral == 0){
            return;
        }
        (uint256 lockedAmount,uint256 lockedWorth) = _FPTCoin.getLockedBalance(msg.sender);
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
            _FPTCoin.burnLocked(msg.sender,lockedBurn);
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
            _FPTCoin.addlockBalance(msg.sender,locked,locked.mul(tokenNetWorth));
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
        emit DebugEvent(3333,colBalances[0],colBalances[1]);
        emit DebugEvent(3333,PremiumBalances[0],PremiumBalances[1]);
        _transferPaybackBalances(collateral,redeemWorth,colBalances,PremiumBalances,prices);
    }
    function _transferPaybackBalances(address collateral,uint256 redeemWorth,uint256[] memory colBalances,uint256[] memory PremiumBalances,uint256[] memory prices)internal {
        address[] memory tmpWhiteList = getTempWhiteList(collateral);
        uint256 ln = tmpWhiteList.length;
        uint256[] memory PaybackBalances = new uint256[](ln);
        for (uint256 i=0; i<ln && redeemWorth>0;i++){
            uint256 totalWorth = prices[i].mul(colBalances[i]);
            if (redeemWorth < totalWorth){
                _collateralPool.setUserInputCollateral(msg.sender,tmpWhiteList[i],
                    _collateralPool.userInputCollateral(msg.sender,tmpWhiteList[i]).mul(totalWorth-redeemWorth).div(totalWorth));
//                userInputCollateral[msg.sender][addr] = userInputCollateral[msg.sender][addr].mul(totalWorth-redeemWorth).div(totalWorth);
                PaybackBalances[i] = redeemWorth.div(prices[i]);
                redeemWorth = 0;
                break;
            }else{
                _collateralPool.setUserInputCollateral(msg.sender,tmpWhiteList[i],0);
                //userInputCollateral[msg.sender][addr] = 0;
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
        for (i=0;i<ln;i++){ 
            _collateralPool.transferPaybackAndFee(msg.sender,tmpWhiteList[i],PaybackBalances[i],redeemColFee);
//            addr = whiteList[i];
//            netWorthBalances[addr] = netWorthBalances[addr].sub(PaybackBalances[i]);
//            _transferPaybackAndFee(msg.sender,addr,PaybackBalances[i],redeemColFee);
        } 
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
//        uint256 ln = tmpWhiteList.length;
        uint256[] memory colBalances = new uint256[](tmpWhiteList.length);
        uint256[] memory PremiumBalances = new uint256[](tmpWhiteList.length);
        uint256[] memory prices = new uint256[](tmpWhiteList.length);
        uint256 totalWorth = 0;
        uint256 PremiumWorth = 0;
        for (uint256 i=0; i<tmpWhiteList.length;i++){
            (colBalances[i],PremiumBalances[i]) = _collateralPool.calUserNetWorthBalanceRate(tmpWhiteList[i],account);
            //(colBalances[i],PremiumBalances[i]) = _calBalanceRate(collateralBalances[tmpWhiteList[i]],netWorthBalances[tmpWhiteList[i]],userInputCollateral[msg.sender][tmpWhiteList[i]]);
            prices[i] = _oracle.getPrice(tmpWhiteList[i]);
            totalWorth = totalWorth.add(prices[i].mul(colBalances[i]));
            PremiumWorth = PremiumWorth.add(prices[i].mul(PremiumBalances[i]));
        }
        if (totalWorth >= userTotalWorth){
            for (i=0; i<tmpWhiteList.length;i++){
                colBalances[i] = colBalances[i].mul(userTotalWorth).div(totalWorth);
            }
        }else{
            userTotalWorth = userTotalWorth - totalWorth;
            for (i=0; i<tmpWhiteList.length;i++){
                PremiumBalances[i] = PremiumBalances[i].mul(userTotalWorth).div(PremiumWorth);
            }
        }
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
            totalOccupied = strikePrice.mul(amount);
        } else {
            totalOccupied = underlyingPrice.mul(amount);
        }
        return calculateCollateral(totalOccupied);
    }

    function getTotalCollateral()public view returns(uint256){
        uint256 totalNum = 0;
        uint whiteListLen = whiteList.length;
        for (uint256 i=0;i<whiteListLen;i++){
            address addr = whiteList[i];
            uint256 price = _oracle.getPrice(addr);
            totalNum = totalNum.add(price.mul(_collateralPool.getNetWorthBalance(addr)));
            //totalNum = totalNum.add(price.mul(netWorthBalances[addr]));
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
            balances[i] = _collateralPool.getNetWorthBalance(addr);
            //balances[i] = netWorthBalances[addr];
            totalPrice = totalPrice.add(price.mul(balances[i]));
        }
        if (totalPrice == 0){
            return;
        }
        for (i=0;i<whiteLen;i++){
            uint256 _payBack = balances[i].mul(worth).div(totalPrice);
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
        return colAmount;
    }
    function calculateCollateral(uint256 amount)internal view returns (uint256){
        uint256 result = collateralRate.numerator.mul(amount);
        return result.div(collateralRate.denominator);
    }

}