pragma solidity ^0.5.1;
library SafeInt256 {
    /*
    uint256 constant private maxInt256 = (1<<255)-1;
    function toInt256(uint256 a)internal pure returns (int256){
        require(a <= maxInt256, "SafeMath: toInt256 overflow");
        return int256(a);
    }
    */
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        return _add(a,b,"SafeInt256: addition overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return _add(a, -b, "SafeMath: subtraction overflow");
    }
    function _add(int256 a, int256 b, string memory errorMessage) internal pure returns (int256){
            int256 c = a + b;
        if ((a>=0) != (b>=0)){
            return c;
        }else if(a>=0){
            require(c >= a, errorMessage);
            return c;
        }else{
            require(c <= a, errorMessage);
            return c;
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        int256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

}
