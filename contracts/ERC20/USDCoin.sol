pragma solidity =0.5.16;
import "./FNXCoin.sol";

contract USDCoin is FNXCoin {

    constructor () public{
        name = "USD Coin";
        symbol = "USDC";
        decimals = 6;
    }
}
