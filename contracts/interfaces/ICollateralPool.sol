pragma solidity ^0.4.26;
import "../modules/Ownable.sol";
interface ICollateralPool {
    function getUserPayingUsd(address user)external view returns (uint256);
    function getUserInputCollateral(address user,address collateral)external view returns (uint256);
    function getNetWorthBalance(address collateral)external view returns (int256);
    function getCollateralBalance(address collateral)external view returns (uint256);

    //add
    function addUserPayingUsd(address user,uint256 amount)external;
    function addUserInputCollateral(address user,address collateral,uint256 amount)external;
    function addNetWorthBalance(address collateral,int256 amount)external;
    function addCollateralBalance(address collateral,uint256 amount)external;
    function addNetWorthBalances(address[] whiteList,int256[] newNetworth)external;
    //sub
    function subUserPayingUsd(address user,uint256 amount)external;
    function subUserInputCollateral(address user,address collateral,uint256 amount)external;
    function subNetWorthBalance(address collateral,int256 amount)external;
    function subCollateralBalance(address collateral,uint256 amount)external;
        //set
    function setUserPayingUsd(address user,uint256 amount)external;
    function setUserInputCollateral(address user,address collateral,uint256 amount)external;
    function setNetWorthBalance(address collateral,int256 amount)external;
    function setCollateralBalance(address collateral,uint256 amount)external;
    function transferPaybackAndFee(address recieptor,address settleMent,uint256 payback,uint256 feeType)external;

    function transferPayback(address recieptor,address settlement,uint256 payback)external;
    function transferPaybackBalances(address account,uint256 redeemWorth,address[] tmpWhiteList,uint256[] colBalances,
        uint256[] PremiumBalances,uint256[] prices)external;
    function getCollateralAndPremiumBalances(address account,uint256 userTotalWorth,address[] tmpWhiteList,
        uint256[] _RealBalances,uint256[] prices) external view returns(uint256[],uint256[]);
}
contract ImportCollateralPool is Ownable{
    ICollateralPool internal _collateralPool;
    function getCollateralPoolAddress() public view returns(address){
        return address(_collateralPool);
    }
    function setCollateralPoolAddress(address collateralPool)public onlyOwner{
        _collateralPool = ICollateralPool(collateralPool);
    }
}