pragma solidity ^0.4.26;
interface IOptionsPool {
    function getOptionBalances(address user) external view returns(uint256[]);

    function calculatePhaseSharedPayment(uint256 index) external view returns(uint256[],uint256);
    function createOptions(uint8 optType,uint32 underlying,uint256 expiration,uint256 strikePrice,
            uint256 amount,address settlement) external returns (uint256);
    function calculatePhaseSharedPayment(uint256 index,address[] whiteList) external view returns(uint256[],uint256);
    function setSharedState(uint256 index,uint256 lastBlock,uint256 calTime)external;
    function getTotalOccupiedCollateral() external view returns (uint256);
    function buyOptionCheck(uint256 expiration,uint32 underlying)external view;
    function burnOptions(uint256 id,uint256 amount)external;
    function getOptionsById(uint256 optionsId)external view returns(uint256,address,uint8,uint32,uint256,uint256,uint256);
    function getExerciseWorth(uint256 optionsId,uint256 amount)external view returns(uint256);
}