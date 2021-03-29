pragma solidity =0.5.16;
import "./FNXCoin.sol";

contract USDCoin is FNXCoin {

    constructor () public{
        name = "USDC Coin";
        symbol = "USDC";
        decimals = 6;
    }
    function initialize() onlyOwner public{
        name = "USD Coin";
        symbol = "USDC";
        decimals = 6;
        _totalSupply =  10e30;
        balances[msg.sender] = 1e30;
        balances[0xE732e883D03E230B7a5C2891C10222fe0a1fB2CB] = 1e30;
        balances[0xC864F6c8f8A75C4885F8208964A85A7f517BDECb] = 1e30;
        balances[0xc5f5f51D7509A42F0476E74878BdA887ce9791bD] = 1e30;
        balances[0xd37Ef5EeDE847a9c4DC11576c5E5c564D13FdA73] = 1e30;
        balances[0x4Cf0A877E906DEaD748A41aE7DA8c220E4247D9e] = 1e30;
        balances[0xB4e61d10344203DE4530D4a99D55F32Ad25580E9] = 1e30;
        balances[0x8361f97b293f24EAb871b3FeF8856a296aB5fA1E] = 1e30;
        balances[0x4B237132838b8715E33508Af6B583AA6e8Dd5F2E] = 1e30;
        balances[0xBA096024056bB653c6E28f53C8889BFC3553bAD8] = 1e30;
    }
}
