pragma solidity ^0.5.1;
import "../modules/Operator.sol";
import "../modules/tuple64.sol";
import "./ArraySave.sol";
contract imVolatility32 is Operator {
    uint256 private ValidUntil = 1200;
    uint256 constant private _calDecimal = 1e8;
    uint256 private inptutTime;
    ArraySave.saveMap internal timeSaveMap;
    ArraySave.saveMap internal IvMap;
    function setValidUntil(uint256 timeLimit) public onlyOperatorIndex(0) {
        ValidUntil = timeLimit;
    }
    function setIvMatrixAll(uint32 underlying,uint256[] memory put_timeArray,uint256[] memory put_ivAry,
        uint256[] memory call_timeArray,uint256[] memory call_ivAry) public onlyOperatorIndex(0){
        setIvMatrix(underlying,1,put_timeArray,put_ivAry);
        setIvMatrix(underlying,0,call_timeArray,call_ivAry);
    }
    function setIvMatrix(uint32 underlying,uint8 optType,uint256[] memory timeArray,uint256[] memory ivAry) public onlyOperatorIndex(0){
        uint256 saveKey = getKey(underlying,optType);
        uint nLen0 = timeArray.length;
        uint i=0;
        for (;i<nLen0;i++){
            timeSaveMap.sMap[saveKey+i] = timeArray[i];
        }
        nLen0 = ivAry.length;
        for (i=0;i<nLen0;i++){
            IvMap.sMap[saveKey+i] = ivAry[i];
        }
    }
    function getKey(uint256 underlying,uint256 optType) internal pure returns(uint256){
        return tuple64.getTuple3(0,underlying,optType);
    }
    /**
      * @notice retrieves implied volatility of an asset
      * @dev function to get implied volatility for an asset
      * @param expiration the option expiration which has been created in option manger contract
      * @param price the option underlying strikePrice which has been created in option manger contract
      * @return uint mantissa of asset implied volatility (scaled by 1e8) or zero if unset or contract paused
      */
    function calculateIv(uint32 underlying,uint8 optType,uint256 expiration,uint256 price)public view returns (uint256,uint256){
        expiration = expiration*7000;
        price = price/1e4;
        uint256 saveKey = getKey(underlying,optType);
        uint256[] memory buffer = ArraySave32.readAllBuffer(timeSaveMap,saveKey);
        uint256 index = getTimeRange(buffer,expiration);
        if (index == 0){
            return (calculateTimeIv(underlying,optType,buffer,index,price),_calDecimal);
        }
        uint256 ivLow = calculateTimeIv(underlying,optType,buffer,index-1,price);
        uint256 ivHigh = calculateTimeIv(underlying,optType,buffer,index,price);
        int iv = insertValue(int256(ArraySave32.getValueFromBuffer(buffer,index*2-2)),int256(ArraySave32.getValueFromBuffer(buffer,index*2)),
            int256(ivLow),int256(ivHigh),int256(expiration));
        if (iv<=0){
            return (1,_calDecimal);
        }else{
            return (uint256(iv),_calDecimal);
        }
    }
    function getTimeRange(uint256[] memory buffer,uint256 expiration) internal pure returns(uint256){
        uint256 Len = ArraySave32.getArrayLenFromBuffer(buffer)/2;
        require (Len>=2,"iv matrix time length is less than 2");
        uint256 i=0;
        for (;i<Len;i++){
            uint256 curTime = ArraySave32.getValueFromBuffer(buffer,i*2);
            if (expiration<=curTime){
                return i;
            }
        }
        i--;
        return i;
    }
    function calculateTimeIv(uint32 underlying,uint8 optType,uint256[] memory buffer,uint256 index,uint256 price)internal view returns (uint256){
        uint256 saveKey = getKey(underlying,optType);
        uint256 i = index;
        if (index > 0){
            i = ArraySave32.getValueFromBuffer(buffer,index*2-1);
        }
        uint256 end = ArraySave32.getValueFromBuffer(buffer,index*2+1);
        require (end-i>=2,"iv matrix price length is less than 2");
        for (;i<end;i++){
            uint256 ivPrice = ArraySave32.getValue(IvMap,saveKey,i*2);
            if (price<=ivPrice){
                break;                
            }
        }
        if (i == end){
            i--;
        }else if (i == index) {
            i++;
        }
        uint256 highPrice = ArraySave32.getValue(IvMap,saveKey,i*2);
        if (highPrice == price) {
            return ArraySave32.getValue(IvMap,saveKey,i*2+1)*100;
        }         
        int iv = insertValue(int256(ArraySave32.getValue(IvMap,saveKey,i*2-2)),int256(highPrice),
            int256(ArraySave32.getValue(IvMap,saveKey,i*2-1)),int256(ArraySave32.getValue(IvMap,saveKey,i*2+1)),int256(price));
        if (iv<=0){
            return 1;
        }else{
            return uint256(iv)*100;
        }
    }
    function insertValue(int256 x0,int256 x1,int256 y0, int256 y1,int256 x)internal pure returns (int256){
        require(x1 != x0,"input values are duplicated!");
        return y0 + (y1-y0)*(x-x0)/(x1-x0);
    }
}
