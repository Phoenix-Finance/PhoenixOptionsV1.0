pragma solidity ^0.4.26;
import "./modules/SafeMath.sol";
import "./modules/SafeInt256.sol";
import "./modules/Managerable.sol";
import "./modules/TransactionFee.sol";
contract CollateralPool is Managerable,TransactionFee{
    using SafeMath for uint256;
    using SafeInt256 for int256;
       //token net worth
    mapping (address => int256) internal netWorthBalances;
    //address collaterel
    mapping (address => uint256) internal collateralBalances;
    //user paying for collateral usd;
    mapping (address => uint256) internal userCollateralPaying;
    //account -> collateral -> amount
    mapping (address => mapping (address => uint256)) internal userInputCollateral;

    function () public payable onlyManager{

    }
    function addTransactionFee(address collateral,uint256 amount,uint256 feeType)public onlyManager returns (uint256) {
        uint256 fee = calculateFee(feeType,amount);
        _addTransactionFee(collateral,fee);
        return fee;
    }
    function getUserPayingUsd(address user)public view returns (uint256){
        return userCollateralPaying[user];
    }
    function getUserInputCollateral(address user,address collateral)public view returns (uint256){
        return userInputCollateral[user][collateral];
    }

    function getNetWorthBalance(address collateral)public view returns (int256){
        return netWorthBalances[collateral];
    }
    function getCollateralBalance(address collateral)public view returns (uint256){
        return collateralBalances[collateral];
    }

    //add
    function addUserPayingUsd(address user,uint256 amount)public onlyManager{
        userCollateralPaying[user] = userCollateralPaying[user].add(amount);
    }
    function addUserInputCollateral(address user,address collateral,uint256 amount)public onlyManager{
        userInputCollateral[user][collateral] = userInputCollateral[user][collateral].add(amount);
    }
    function addNetWorthBalances(address[] memory whiteList,int256[] memory newNetworth)public onlyManager{
        for (uint i=0;i<newNetworth.length;i++){
            netWorthBalances[whiteList[i]] = netWorthBalances[whiteList[i]].add(newNetworth[i]);
        }
    }
    function addNetWorthBalance(address collateral,int256 amount)public onlyManager{
        netWorthBalances[collateral] = netWorthBalances[collateral].add(amount);
    }
    function addCollateralBalance(address collateral,uint256 amount)public onlyManager{
        collateralBalances[collateral] = collateralBalances[collateral].add(amount);
    }
    //sub
    function subUserPayingUsd(address user,uint256 amount)public onlyManager{
        userCollateralPaying[user] = userCollateralPaying[user].sub(amount);
    }
    function subUserInputCollateral(address user,address collateral,uint256 amount)public onlyManager{
        userInputCollateral[user][collateral] = userInputCollateral[user][collateral].sub(amount);
    }

    function subNetWorthBalance(address collateral,int256 amount)public onlyManager{
        netWorthBalances[collateral] = netWorthBalances[collateral].sub(amount);
    }
    function subCollateralBalance(address collateral,uint256 amount)public onlyManager{
        collateralBalances[collateral] = collateralBalances[collateral].sub(amount);
    }
    //set
    function setUserPayingUsd(address user,uint256 amount)public onlyManager{
        userCollateralPaying[user] = amount;
    }
    function setUserInputCollateral(address user,address collateral,uint256 amount)public onlyManager{
        userInputCollateral[user][collateral] = amount;
    }

    function setNetWorthBalance(address collateral,int256 amount)public onlyManager{
        netWorthBalances[collateral] = amount;
    }
    function setCollateralBalance(address collateral,uint256 amount)public onlyManager{
        collateralBalances[collateral] = amount;
    }
    function transferPaybackAndFee(address recieptor,address settleMent,uint256 payback,
            uint256 feeType)public onlyManager{
        _transferPaybackAndFee(recieptor,settleMent,payback,feeType);
        netWorthBalances[settleMent] = netWorthBalances[settleMent]-int256(payback);
    }
    function transferPayback(address recieptor,address settlement,uint256 payback)public onlyManager{
        _transferPayback(recieptor,settlement,payback);
    }
    function transferPaybackBalances(address account,uint256 redeemWorth,address[] memory tmpWhiteList,uint256[] memory colBalances,
        uint256[] memory PremiumBalances,uint256[] memory prices)public onlyManager {
        uint256 ln = tmpWhiteList.length;
        uint256[] memory PaybackBalances = new uint256[](ln);
        for (uint256 i=0; i<ln && redeemWorth>0;i++){
            //address addr = tmpWhiteList[i];
            if (colBalances[i] > 0){
                uint256 totalWorth = prices[i].mul(colBalances[i]);
                if (redeemWorth < totalWorth){
    //                setUserInputCollateral(account,tmpWhiteList[i],
    //                    getUserInputCollateral(account,tmpWhiteList[i]).mul(totalWorth-redeemWorth).div(totalWorth));
                    userInputCollateral[account][tmpWhiteList[i]] = userInputCollateral[account][tmpWhiteList[i]].mul(totalWorth-redeemWorth).div(totalWorth);
                    PaybackBalances[i] = redeemWorth/prices[i];
                    redeemWorth = 0;
                    break;
                }else{
                    //_collateralPool.setUserInputCollateral(msg.sender,tmpWhiteList[i],0);
                    userInputCollateral[account][tmpWhiteList[i]] = 0;
                    PaybackBalances[i] = colBalances[i];
                    redeemWorth = redeemWorth - totalWorth;
                }
            }
        }
        if (redeemWorth>0) {
           totalWorth = 0;
            for (i=0; i<ln;i++){
                totalWorth = totalWorth.add(PremiumBalances[i]*prices[i]);
            }
            require(totalWorth >= redeemWorth ,"redeem collateral is insufficient");
            for (i=0; i<ln;i++){
                PaybackBalances[i] = PaybackBalances[i].add(PremiumBalances[i].mul(redeemWorth)/totalWorth);
            }
        }
        for (i=0;i<ln;i++){ 
            transferPaybackAndFee(account,tmpWhiteList[i],PaybackBalances[i],redeemColFee);
//            addr = whiteList[i];
//            netWorthBalances[addr] = netWorthBalances[addr].sub(PaybackBalances[i]);
//            _transferPaybackAndFee(msg.sender,addr,PaybackBalances[i],redeemColFee);
        } 
    }
    function getCollateralAndPremiumBalances(address account,uint256 userTotalWorth,address[] memory tmpWhiteList,
        uint256[] memory _RealBalances,uint256[] memory prices) public view returns(uint256[],uint256[]){
//        uint256 ln = tmpWhiteList.length;
        uint256[] memory colBalances = new uint256[](tmpWhiteList.length);
        uint256[] memory PremiumBalances = new uint256[](tmpWhiteList.length);
        uint256 totalWorth = 0;
        uint256 PremiumWorth = 0;
        for (uint256 i=0; i<tmpWhiteList.length;i++){
            (colBalances[i],PremiumBalances[i]) = calUserNetWorthBalanceRate(tmpWhiteList[i],account,_RealBalances[i]);
            totalWorth = totalWorth.add(prices[i]*colBalances[i]);
            PremiumWorth = PremiumWorth.add(prices[i]*PremiumBalances[i]);
        }
        if (totalWorth >= userTotalWorth){
            for (i=0; i<tmpWhiteList.length;i++){
                colBalances[i] = colBalances[i].mul(userTotalWorth)/totalWorth;
            }
        }else if (PremiumWorth>0){
            userTotalWorth = userTotalWorth - totalWorth;
            for (i=0; i<tmpWhiteList.length;i++){
                PremiumBalances[i] = PremiumBalances[i].mul(userTotalWorth)/PremiumWorth;
            }
        }
        return (colBalances,PremiumBalances);
    } 
    function calUserNetWorthBalanceRate(address settlement,address user,uint256 netWorthBalance)internal view returns(uint256,uint256){
        uint256 collateralBalance = collateralBalances[settlement];
        uint256 amount = userInputCollateral[user][settlement];
        if (collateralBalance > 0){
            uint256 curAmount = netWorthBalance.mul(amount)/collateralBalance;
            return (curAmount,netWorthBalance.sub(curAmount));
        }else{
            return (0,netWorthBalance);
        }
    }
}