pragma solidity =0.5.16;
import "./PHXCoin.sol";

contract WETH is PHXCoin {

    constructor () public{
        name = "Wrabed ETH";
        symbol = "WETH";
    }
}
