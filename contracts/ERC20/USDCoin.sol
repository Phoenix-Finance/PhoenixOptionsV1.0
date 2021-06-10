pragma solidity =0.5.16;
import "./PHXCoin.sol";

contract USDCoin is PHXCoin {

    constructor () public{
        name = "USDC Coin";
        symbol = "USDC";
        decimals = 6;
    }
}
