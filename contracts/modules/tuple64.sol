pragma solidity =0.5.16;
library tuple64 {
    // add whiteList
    function getValue0(uint256 input) internal pure returns (uint256){
        return uint256(uint64(input));
    }
    function getValue1(uint256 input) internal pure returns (uint256){
        return uint256(uint64(input>>64));
    }
    function getValue2(uint256 input) internal pure returns (uint256){
        return uint256(uint64(input>>128));
    }
    function getValue3(uint256 input) internal pure returns (uint256){
        return uint256(uint64(input>>192));
    }
    function getTuple(uint256 input0,uint256 input1,uint256 input2,uint256 input3) internal pure returns (uint256){
        return input0+(input1<<64)+(input2<<128)+(input3<<192);
    }
    function getTuple3(uint256 input0,uint256 input1,uint256 input2) internal pure returns (uint256){
        return input0+(input1<<64)+(input2<<128);
    }
    function getTuple2(uint256 input0,uint256 input1) internal pure returns (uint256){
        return input0+(input1<<64);
    }
}