pragma solidity =0.5.16;
import "./PHXCoin.sol";

contract FRAXCoin is PHXCoin {

    constructor () public{
        name = "FRAX Coin";
        symbol = "FRAX";
    }
}
