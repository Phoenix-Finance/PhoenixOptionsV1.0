pragma solidity =0.5.16;
import "./FNXCoin.sol";

contract USDTCoin is FNXCoin {

    constructor () public{
        name = "USDT Coin";
        symbol = "USDT";
        decimals = 6;
    }
}
