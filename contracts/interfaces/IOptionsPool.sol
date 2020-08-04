pragma solidity ^0.4.26;
import "../modules/Ownable.sol";
interface IOptionsPool {
//    function getOptionBalances(address user) external view returns(uint256[]);

    function createOptions(address from,address settlement,uint256 type_ly_exp,uint256 strikePrice,uint256 underlyingPrice,
                uint256 amount)  external;
    function setSharedState(uint256 newFirstOption,int256[] latestNetWorth,address[] whiteList) external;
    function getTotalOccupiedCollateral() external view returns (uint256);
    function buyOptionCheck(uint256 expiration,uint32 underlying)external view;
    function burnOptions(address from,uint256 id,uint256 amount,uint256 optionPrice)external;
    function getOptionsById(uint256 optionsId)external view returns(uint256,address,uint8,uint32,uint256,uint256,uint256);
    function getExerciseWorth(uint256 optionsId,uint256 amount)external view returns(uint256);
    function calculatePhaseOptionsFall(uint256 lastOption,uint256 begin,uint256 end,address[] whiteList) external view returns(int256[]);
    function getOptionInfoLength()external view returns (uint256);
    function getNetWrothCalInfo(address[] whiteList)external view returns(uint256,int256[]);
    function calculateExpiredPayment(uint256 begin,uint256 end,address[] whiteList)external view returns(int256[]);
    function calRangeSharedPayment(uint256 lastOption,uint256 begin,uint256 end,address[] whiteList)external view returns(uint256[],uint256,bool);
    function getNetWrothLatestWorth(address settlement)external view returns(int256);
    function getBurnedFullPay(uint256 optionID,uint256 amount) external view returns(address,uint256);
}
contract ImportOptionsPool is Ownable{
    IOptionsPool internal _optionsPool;
    function getOptionsPoolAddress() public view returns(address){
        return address(_optionsPool);
    }
    function setOptionsPoolAddress(address optionsPool)public onlyOwner{
        _optionsPool = IOptionsPool(optionsPool);
    }
}