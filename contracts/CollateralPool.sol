pragma solidity ^0.4.26;
import "./modules/SafeMath.sol";
import "./modules/Managerable.sol";
import "./modules/TransactionFee.sol";
contract CollateralPool is Managerable,TransactionFee{
    using SafeMath for uint256;
       //token net worth
    mapping (address => uint256) public netWorthBalances;
    //address collaterel
    mapping (address => uint256) public collateralBalances;
    //user paying for collateral usd;
    mapping (address => uint256) public userCollateralPaying;
    //account -> collateral -> amount
    mapping (address => mapping (address => uint256)) public userInputCollateral;

    function () public payable onlyManager{

    }
    function getUserPayingUsd(address user)public view returns (uint256){
        return userCollateralPaying[user];
    }
    function userInputCollateral(address user,address collateral)public view returns (uint256){
        return userInputCollateral[user][collateral];
    }

    function getNetWorthBalance(address collateral)public view returns (uint256){
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

    function addNetWorthBalance(address collateral,uint256 amount)public onlyManager{
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

    function subNetWorthBalance(address collateral,uint256 amount)public onlyManager{
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

    function setNetWorthBalance(address collateral,uint256 amount)public onlyManager{
        netWorthBalances[collateral] = amount;
    }
    function setCollateralBalance(address collateral,uint256 amount)public onlyManager{
        collateralBalances[collateral] = amount;
    }
    function transferPaybackAndFee(address recieptor,address settleMent,uint256 payback,
            uint256 feeType)public onlyManager{
        _transferPaybackAndFee(recieptor,settleMent,payback,feeType);
        netWorthBalances[settleMent] = netWorthBalances[settleMent].sub(payback);
    }
    function transferPayback(address recieptor,address settlement,uint256 payback)public onlyManager{
        _transferPayback(recieptor,settlement,payback);
    }
    //collateralBalances[tmpWhiteList[i]],netWorthBalances[tmpWhiteList[i]],userInputCollateral[msg.sender][tmpWhiteList[i]]
    function calUserNetWorthBalanceRate(address settlement,address user)public view returns(uint256,uint256){
        uint256 collateralBalance = collateralBalances[settlement];
        uint256 netWorthBalance = netWorthBalances[settlement];
        uint256 amount = userInputCollateral[user][settlement];
        if (collateralBalance > 0){
            uint256 curAmount = netWorthBalance.mul(amount).div(collateralBalance);
            return (curAmount,netWorthBalance.sub(curAmount));
        }else{
            return (0,netWorthBalance);
        }
    }
}