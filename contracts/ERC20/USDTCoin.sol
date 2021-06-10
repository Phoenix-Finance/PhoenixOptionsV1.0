pragma solidity =0.5.16;
import "./PHXCoin.sol";

contract USDTCoin is PHXCoin {

    constructor () public{
        name = "USDT Coin";
        symbol = "USDT";
        decimals = 6;
    }
}
