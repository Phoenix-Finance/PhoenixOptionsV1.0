pragma solidity ^0.4.26;
import "./modules/Ownable.sol";
contract ImpliedVolatility is Ownable {
    uint256 public ValidUntil = 1200;
    uint256 constant _calDecimal = 1e8;
    uint256 constant ivIndex = 2;
    uint256 constant priceIndex = 1;
    uint256 constant timeIndex = 0;
    uint256 public inptutTime;
    uint256[3][][] public ivMatrix;
    function setValidUntil(uint256 timeLimit) public onlyOwner {
        ValidUntil = timeLimit;
    }

    /**
    /**
  * @notice retrieves implied volatility of an asset
  * @dev function to get implied volatility for an asset
  * @param expiration the option expiration which has been created in option manger contract
  * @param price the option underlying strikePrice which has been created in option manger contract
  * @return uint mantissa of asset implied volatility (scaled by 1e18) or zero if unset or contract paused
  */
    function calculateIv(uint256 expiration,uint256 price)public view returns (uint256,uint256){
        uint256 mxLen = ivMatrix.length;
        require(mxLen>=2,"price iv list is less than 2");
        for (uint256 i=0;i<mxLen;i++){
            if (expiration<=ivMatrix[timeIndex][0][i]){
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
        int iv = insertValue(int256(ivMatrix[timeIndex][0][i-1]),int256(ivMatrix[timeIndex][0][i]),
            int256(ivLow),int256(ivHigh),int256(expiration));
        if (iv<=0){
            return (1,_calDecimal);
        }else{
            return (uint256(iv),_calDecimal);
        }
    }
    function calculateTimeIv(uint256 [3][] storage _matrix,uint256 price)internal view returns (uint256){
        uint256 mxLen = _matrix.length;
        require(mxLen>=2,"price iv list is less than 2");
        uint256 index = binarySearch(_matrix,price);
        if (_matrix[priceIndex][index] == price) {
            return _matrix[ivIndex][index];
        }
        if (index >= mxLen){
            index = mxLen;
        }else if(index == 0){
            index = 1;
        }
        int iv = insertValue(int256(_matrix[priceIndex][index-1]),int256(_matrix[priceIndex][index]),
            int256( _matrix[ivIndex][index-1]),int256(_matrix[ivIndex][index]),int256(price));
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
    function binarySearch(uint256 [3][] storage _matrix,uint256 price)internal view returns (uint256) {
        uint256 low = 0;
        uint256 high = _matrix.length - 1;
        while (low <= high) {
            uint256 mid = (high + low) / 2;
            uint256 midPrice = _matrix[priceIndex][mid];
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
