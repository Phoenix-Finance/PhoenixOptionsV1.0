pragma solidity =0.5.16;
import "./FNXCoin.sol";

contract USDCoin is FNXCoin {

    constructor () public{
        name = "USDT Coin";
        symbol = "USDT";
        decimals = 6;
    }
}
