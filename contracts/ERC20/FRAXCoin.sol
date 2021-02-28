pragma solidity =0.5.16;
import "./FNXCoin.sol";

contract FRAXCoin is FNXCoin {

    constructor () public{
        name = "FRAX Coin";
        symbol = "FRAX";
    }
}
