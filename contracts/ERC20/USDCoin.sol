pragma solidity =0.5.16;
import "./FNXCoin.sol";

contract USDCoin is FNXCoin {

    constructor () public{
        name = "USDC Coin";
        symbol = "USDC";
        decimals = 6;
    }
}
