pragma solidity ^0.4.26;
import "./modules/Ownable.sol";
contract ImpliedVolatility is Ownable {
    uint256 private ValidUntil = 1200;
    uint256 constant private _calDecimal = 1e8;
    uint256 private inptutTime;
    mapping(uint256=>uint256[][]) private ivMatrixMap;
    function setValidUntil(uint256 timeLimit) public onlyOwner {
        ValidUntil = timeLimit;
    }
    //ivType == underlying << 16 + optType
    function setIvMatrix(uint32 underlying,uint8 optType,uint32[]expirationAry,uint32[] childlen,uint64[] priceAry,uint64[] ivAry) public onlyOwner{
        uint index = getKey(underlying,optType);
        require(priceAry.length == ivAry.length,"intput arrays must be same length");
        require(expirationAry.length == childlen.length,"intput arrays must be same length");
        uint256[][] storage ivMatrix = ivMatrixMap[index];
        ivMatrix.length = 0;
        index = 0;
        for (uint i=0;i<expirationAry.length;i++){
            uint256 expiration = uint256(expirationAry[i]);
            uint len1 = childlen[i];
            uint256[] memory childAry = new uint256[](len1);
            for (uint j=0;j<len1;j++){
                uint256 price = uint256(priceAry[index]);
                uint256 iv = uint256(ivAry[index]);
                childAry[j] = expiration+(price<<64)+(iv<<128);
                index++;
            }
            ivMatrix.push(childAry);
        }
    }
    function getKey(uint32 underlying,uint8 optType) internal pure returns(uint256){
        return (uint256(underlying) << 16)+ uint256(optType);
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
        uint256 ivType = getKey(underlying,optType);
        uint256[][] storage ivMatrix = ivMatrixMap[ivType];
        uint256 mxLen = ivMatrix.length;
        require(mxLen>=2,"price iv list is less than 2");
        for (uint256 i=0;i<mxLen;i++){
            if (expiration<=uint256(getTime(ivMatrix[i][0]))){
                break;
            }
        }
        if (i == 0){
            return (calculateTimeIv(ivMatrix[0],price),_calDecimal);
        }else if (i >= mxLen){
            i = mxLen - 1;
        }
        uint256 ivLow = calculateTimeIv(ivMatrix[i-1],price);
        uint256 ivHigh = calculateTimeIv(ivMatrix[i],price);
        int iv = insertValue(getTime(ivMatrix[i-1][0]),getTime(ivMatrix[i][0]),
            int256(ivLow),int256(ivHigh),int256(expiration));
        if (iv<=0){
            return (1,_calDecimal);
        }else{
            return (uint256(iv),_calDecimal);
        }
    }
    function calculateTimeIv(uint256[] memory _matrix,uint256 price)internal pure returns (uint256){
        uint256 mxLen = _matrix.length;
        require(mxLen>=2,"price iv list is less than 2");
        uint256 index = binarySearch(_matrix,int256(price));
        if (index >= mxLen){
            index = mxLen-1;
        }else{
            int256 highPrice = getPrice(_matrix[index]);
            if (uint256(highPrice) == price) {
                return uint256(getIv(_matrix[index]));
            }            
        }
        if(index == 0){
            index = 1;
        }
        int iv = insertValue(getPrice(_matrix[index-1]),getPrice(_matrix[index]),
            getIv(_matrix[index-1]),getIv(_matrix[index]),int256(price));
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
    function binarySearch(uint256[] memory _matrix,int256 price)internal pure returns (uint256) {
        uint256 low = 0;
        uint256 high = _matrix.length - 1;
        while (low <= high) {
            uint256 mid = (high + low) / 2;
            int256 midPrice = getPrice(_matrix[mid]);
            if (midPrice == price){
                return mid;
            }else if (midPrice < price){
                low = mid + 1;
            } 
            else{
                if (mid == 0){
                    return 0;
                }
                high = mid - 1;
            } 
        }
        return low;
    }
}
