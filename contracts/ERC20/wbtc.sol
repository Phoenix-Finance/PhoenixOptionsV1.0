pragma solidity =0.5.16;
import "./PHXCoin.sol";

contract WBTC is PHXCoin {

    constructor () public{
        name = "Wrabed BTC";
        symbol = "WBTC";
        decimals = 8;
    }
}
