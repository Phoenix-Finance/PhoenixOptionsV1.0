pragma solidity =0.5.16;
import "./PHXCoin.sol";

contract DAICoin is PHXCoin {

    constructor () public{
        name = "Dai Stablecoin";
        symbol = "DAI";
    }
}
