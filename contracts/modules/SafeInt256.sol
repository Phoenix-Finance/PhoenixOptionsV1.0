pragma solidity =0.5.16;
library SafeInt256 {
    function add(int256 x, int256 y) internal pure returns (int256 z) {
        require(((z = x + y) >= x) == (y >= 0), 'SafeInt256: addition overflow');
    }

    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        require(((z = x - y) <= x) == (y >= 0), 'SafeInt256: substraction underflow');
    }

    function mul(int256 x, int256 y) internal pure returns (int256 z) {
        require(y == 0 || (z = x * y) / y == x, 'SafeInt256: multiplication overflow');
    }
}
