pragma solidity ^0.4.26;
import "./imVolatility32.sol";
contract imVolatilityTest is imVolatility32 {
    function getTimeMapLen(uint32 underlying,uint8 optType)public view returns(uint256){
        uint256 saveKey = getKey(underlying,optType);
        return ArraySave32.getArrayLen(timeSaveMap,saveKey);
    }
    function getTimeAllBufferLen(uint32 underlying,uint8 optType)public view returns(uint256){
        uint256 saveKey = getKey(underlying,optType);
        uint256[] memory buffer = ArraySave32.readAllBuffer(timeSaveMap,saveKey);
        return buffer.length;
    }
    function getTimeAllBuffer(uint32 underlying,uint8 optType)public view returns(uint256[]){
        uint256 saveKey = getKey(underlying,optType);
        uint256[] memory buffer = ArraySave32.readAllBuffer(timeSaveMap,saveKey);
        return buffer;
    }
    function getValueFromBuffer(uint256[] buffer,uint256 index)public pure returns(uint256){
        return ArraySave32.getValueFromBuffer(buffer,index);
    }
    function getTimeRangeIndex(uint32 underlying,uint8 optType,uint256 expiration)public view returns(uint256){
        uint256 saveKey = getKey(underlying,optType);
        uint256[] memory buffer = ArraySave32.readAllBuffer(timeSaveMap,saveKey);
        return getTimeRange(buffer,expiration);
    }
}