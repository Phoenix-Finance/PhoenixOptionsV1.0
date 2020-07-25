pragma solidity ^0.4.26;
import "./modules/Ownable.sol";
import "./modules/tuple.sol";
contract ImpliedVol is Ownable {
    uint256 public ValidUntil = 1200;
    uint256 constant _calDecimal = 1e8;
    uint256 public inptutTime;
    mapping(uint256=>uint256)public ivMatrixMap;
    function setValidUntil(uint256 timeLimit) public onlyOwner {
        ValidUntil = timeLimit;
    }
    function setIvMatrix(uint32 underlying,uint8 optType,uint32[] childlen,uint256[] ivAry) public{
        uint256 iter = 0;
        uint nLen0 = childlen.length;
        for (uint i=0;i<nLen0;i++){
            uint256 index = getKey(underlying,optType,i*1000);
            uint len1 = childlen[i];
            for (uint j=0;j<len1;j++){
                ivMatrixMap[index+j] = ivAry[iter];
                iter++;
            }
            ivMatrixMap[index+len1] = 0;
        }
    }
    function getKey(uint256 underlying,uint256 optType,uint256 index) internal pure returns(uint256){
        return tuple64.getTuple3(index,underlying,optType);
    }
    /**
    /**
  * @notice retrieves implied volatility of an asset
  * @dev function to get implied volatility for an asset
  * @param expiration the option expiration which has been created in option manger contract
  * @param price the option underlying strikePrice which has been created in option manger contract
  * @return uint mantissa of asset implied volatility (scaled by 1e18) or zero if unset or contract paused
  */
    function calculateIv(uint32 underlying,uint8 optType,uint256 expiration,uint256 price)public view returns (uint256,uint256){
        uint256 index = getTimeIndex(underlying,optType,expiration);
        if (index == 0){
            return (calculateTimeIv(underlying,optType,index,price),_calDecimal);
        }
        uint256 ivLow = calculateTimeIv(underlying,optType,index-1,price);
        uint256 ivHigh = calculateTimeIv(underlying,optType,index,price);
        uint256 key0 = getKey(underlying,optType,(index-1)*1000);
        uint256 key1 = getKey(underlying,optType,index*1000);
        int iv = insertValue(getTime(ivMatrixMap[key0]),getTime(ivMatrixMap[key1]),
            int256(ivLow),int256(ivHigh),int256(expiration));
        if (iv<=0){
            return (1,_calDecimal);
        }else{
            return (uint256(iv),_calDecimal);
        }
    }
    function getTimeIndex(uint32 underlying,uint8 optType,uint256 expiration) internal view returns(uint256){
        for (uint i=0;true;i++){
            uint256 key = getKey(underlying,optType,i*1000);
            uint256 value = ivMatrixMap[key];
            if (value == 0){
                i--;
                break;
            }
            if (expiration<=uint256(getTime(value))){
                break;
            }
        }
        return i;   
    }
    function calculateTimeIv(uint32 underlying,uint8 optType,uint256 index,uint256 price)internal view returns (uint256){
        uint256 key = getKey(underlying,optType,index*1000);
        for (uint i=0;true;i++){
            uint256 value = ivMatrixMap[key+i];
            if (value == 0){
                i--;
                break;
            }
            if (price<=uint256(getPrice(value))){
                break;                
            }
        }
        if (i == 0) {
            i == 1;
        }
        int256 highPrice = getPrice(ivMatrixMap[key+i]);
        if (uint256(highPrice) == price) {
            return uint256(getIv(ivMatrixMap[key+i]));
        }            
        int iv = insertValue(getPrice(ivMatrixMap[key+i-1]),getPrice(ivMatrixMap[key+i]),
            getIv(ivMatrixMap[key+i-1]),getIv(ivMatrixMap[key+i]),int256(price));
        if (iv<=0){
            return 1;
        }else{
            return uint256(iv);
        }
    }
    function insertValue(int256 x0,int256 x1,int256 y0, int256 y1,int256 x)internal pure returns (int256){
        require(x1 != x0,"input values are duplicated!");
        return y0 + (y1-y0)*(x-x0)/(x1-x0);
    }
    function getTime(uint256 value)internal pure returns (int256) {
        return int256(uint64(value));
    }
    function getPrice(uint256 value)internal pure returns (int256) {
        return int256(uint64(value>>64));
    }
    function getIv(uint256 value)internal pure returns (int256) {
        return int256(value>>128);
    }
}
