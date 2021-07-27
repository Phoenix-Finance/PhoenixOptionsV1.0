pragma solidity =0.5.16;
import "./PHXCoin.sol";

contract cPHX is PHXCoin {

    constructor () public{
        name = "convert PHX Coin";
        symbol = "cPHX";
    }
}
