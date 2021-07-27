pragma solidity =0.5.16;
import "./PHXCoin.sol";

contract BUSD is PHXCoin {

    constructor () public{
        name = "Binance-Peg BUSD Token";
        symbol = "BUSD";
        decimals = 18;
    }
}

