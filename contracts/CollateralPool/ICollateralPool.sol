pragma solidity =0.5.16;
import "../modules/Ownable.sol";
interface ICollateralPool {
    function getFeeRateAll()external view returns (uint32[] memory);
    function getUserPayingUsd(address user)external view returns (uint256);
    function getUserInputCollateral(address user,address collateral)external view returns (uint256);
    //function getNetWorthBalance(address collateral)external view returns (int256);
    function getCollateralBalance(address collateral)external view returns (uint256);

    //add
    function addUserPayingUsd(address user,uint256 amount)external;
    function addUserInputCollateral(address user,address collateral,uint256 amount)external;
    function addNetWorthBalance(address collateral,int256 amount)external;
    function addCollateralBalance(address collateral,uint256 amount)external;
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
    function transferPaybackAndFee(address recieptor,address settlement,uint256 payback,uint256 feeType)external;

    function buyOptionsPayfor(address payable recieptor,address settlement,uint256 settlementAmount,uint256 allPay)external;
    function transferPayback(address recieptor,address settlement,uint256 payback)external;
    function transferPaybackBalances(address account,uint256 redeemWorth,address[] calldata tmpWhiteList,uint256[] calldata colBalances,
        uint256[] calldata PremiumBalances,uint256[] calldata prices)external;
    function getCollateralAndPremiumBalances(address account,uint256 userTotalWorth,address[] calldata tmpWhiteList,
        uint256[] calldata _RealBalances,uint256[] calldata prices) external view returns(uint256[] memory,uint256[] memory);
    function addTransactionFee(address collateral,uint256 amount,uint256 feeType)external returns (uint256);

    function getAllRealBalance(address[] calldata whiteList)external view returns(int256[] memory);
    function getRealBalance(address settlement)external view returns(int256);
    function getNetWorthBalance(address settlement)external view returns(uint256);
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