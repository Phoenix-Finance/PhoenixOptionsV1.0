pragma solidity ^0.4.26;
library ArraySave{
    struct saveMap{
        mapping(uint256 => uint256) sMap;
    }
    function getRawValue(saveMap storage curMap,uint256 key,uint256 index,uint256 _saveNum,uint256 _BinarayLen,uint256 _mark) internal view returns (uint256){
        uint256 no = index/_saveNum;
        uint256 buffer = curMap.sMap[key+no];
        uint256 move = (index%_saveNum)*_BinarayLen;
        return (buffer >> move)&_mark;
    }
    function readAllBuffer(saveMap storage curMap,uint256 key,uint256 _saveNum,uint256 _mark)internal view returns (uint256[]){
        uint256 buffer0 = curMap.sMap[key];
        uint256 len = buffer0&_mark;
        if (len == 0){
            return;
        }
        uint256 bufferLen = (len+1)/_saveNum;
        if((len+1)%_saveNum != 0){
            bufferLen++;
        }
        uint256[] memory buffer = new uint256[](bufferLen);
        buffer[0] = buffer0;
        for (uint256 i=1;i<bufferLen;i++){
            buffer[i] = curMap.sMap[key+i];
        }
        return buffer;
    }
    function getRawValueFromBuffer(uint256[] memory buffer,uint256 index,uint256 _saveNum,uint256 _BinarayLen,uint256 _mark) internal pure returns (uint256){
        uint256 no = index/_saveNum;
        uint256 move = (index%_saveNum)*_BinarayLen;
        return (buffer[no] >> move)&_mark;
    } 
}
library ArraySave32 {
    // add whiteList
    uint256 constant mark = 0xffffffff;
    uint256 constant BinarayLen = 32;
    uint256 constant saveNum = 8;
    function getValue(ArraySave.saveMap storage curMap,uint256 key,uint256 index) internal view returns (uint256){
        return ArraySave.getRawValue(curMap,key,index+1,saveNum,BinarayLen,mark);
    }
    function getArrayLen(ArraySave.saveMap storage curMap,uint256 key) internal view returns (uint256){
        return ArraySave.getRawValue(curMap,key,0,saveNum,BinarayLen,mark);
    }
    function readAllBuffer(ArraySave.saveMap storage curMap,uint256 key)internal view returns (uint256[]){
        return ArraySave.readAllBuffer(curMap,key,saveNum,mark);
    }
    function getValueFromBuffer(uint256[] memory buffer,uint256 index) internal pure returns (uint256){
        return ArraySave.getRawValueFromBuffer(buffer,index+1,saveNum,BinarayLen,mark);
    }
    function getArrayLenFromBuffer(uint256[] memory buffer) internal pure returns (uint256){
        if (buffer.length == 0){
            return 0;
        }
        return ArraySave.getRawValueFromBuffer(buffer,0,saveNum,BinarayLen,mark);
    }
}
library ArraySave64 {
    // add whiteList
    uint256 constant mark = 0xffffffffffffffff;
    uint256 constant BinarayLen = 64;
    uint256 constant saveNum = 4;
    function getValue(ArraySave.saveMap storage curMap,uint256 key,uint256 index) internal view returns (uint256){
        return ArraySave.getRawValue(curMap,key,index+1,saveNum,BinarayLen,mark);
    }
    function getArrayLen(ArraySave.saveMap storage curMap,uint256 key) internal view returns (uint256){
        return ArraySave.getRawValue(curMap,key,0,saveNum,BinarayLen,mark);
    }
    function readAllBuffer(ArraySave.saveMap storage curMap,uint256 key)internal view returns (uint256[]){
        return ArraySave.readAllBuffer(curMap,key,saveNum,mark);
    }
    function getValueFromBuffer(uint256[] memory buffer,uint256 index) internal pure returns (uint256){
        return ArraySave.getRawValueFromBuffer(buffer,index+1,saveNum,BinarayLen,mark);
    }
    function getArrayLenFromBuffer(uint256[] memory buffer) internal pure returns (uint256){
        if (buffer.length == 0){
            return 0;
        }
        return ArraySave.getRawValueFromBuffer(buffer,0,saveNum,BinarayLen,mark);
    }
}