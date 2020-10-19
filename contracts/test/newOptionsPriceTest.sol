pragma solidity =0.5.16;
import "../OptionsPrice.sol";
import "../OptionsPriceNew.sol";

contract newOptionsPriceTest {
    uint256 private test1;
    int256 private test2;
    event DebugEvent(address indexed sender,uint256 _test1,int256 _test2);
    function testNew(address price) public{
        test1 = OptionsPriceNew(price).getOptionsPrice(123000000,145000000,864000,1,0);
    } 
    function testOld(address price) public{
        test1 = OptionsPrice(price).getOptionsPrice(123000000,145000000,864000,1,0);
    } 
}