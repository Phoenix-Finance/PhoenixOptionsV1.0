pragma solidity =0.5.16;
import "./PHXCoin.sol";

contract BUSDT is PHXCoin {

    constructor () public{
        name = "BSC USDT Token";
        symbol = "USDT";
        decimals = 18;
    }
}

