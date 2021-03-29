pragma solidity =0.5.16;
import "../modules/Ownable.sol";
interface IOptionsPool {
//    function getOptionBalances(address user) external view returns(uint256[]);

    function getExpirationList()external view returns (uint32[] memory);
    function createOptions(address from,address settlement,uint256 type_ly_expiration,
        uint128 strikePrice,uint128 underlyingPrice,uint128 amount,uint128 settlePrice) external returns(uint256);
    function setSharedState(uint256 newFirstOption,int256[] calldata latestNetWorth,address[] calldata whiteList) external;
    function getAllTotalOccupiedCollateral() external view returns (uint256,uint256);
    function getCallTotalOccupiedCollateral() external view returns (uint256);
    function getPutTotalOccupiedCollateral() external view returns (uint256);
    function getTotalOccupiedCollateral() external view returns (uint256);
//    function buyOptionCheck(uint32 expiration,uint32 underlying)external view;
    function burnOptions(address from,uint256 id,uint256 amount,uint256 optionPrice)external;
    function getOptionsById(uint256 optionsId)external view returns(uint256,address,uint8,uint32,uint256,uint256,uint256);
    function getExerciseWorth(uint256 optionsId,uint256 amount)external view returns(uint256);
    function calculatePhaseOptionsFall(uint256 lastOption,uint256 begin,uint256 end,address[] calldata whiteList) external view returns(int256[] memory);
    function getOptionInfoLength()external view returns (uint256);
    function getNetWrothCalInfo(address[] calldata whiteList)external view returns(uint256,int256[] memory);
    function calRangeSharedPayment(uint256 lastOption,uint256 begin,uint256 end,address[] calldata whiteList)external view returns(int256[] memory,uint256[] memory,uint256);
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