pragma solidity =0.5.16;
import "./PHXCoin.sol";

contract AVAXCoin is PHXCoin {

    constructor () public{
        name = "AVAX test coin";
        symbol = "AVAX";
    }
}
