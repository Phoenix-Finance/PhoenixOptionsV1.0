pragma solidity ^0.5.1;
import "./modules/Erc20Proxy.sol";
contract FPTProxy is Proxy{
    address public implementation;
    constructor(address implementation_,address minePoolAddr) public {
        implementation = implementation_; 
        delegateToViewImplementation(abi.encodeWithSignature("initialize(address)",minePoolAddr));
//        (bool success,) = implementation.delegatecall(abi.encodeWithSignature("initialize(address)",minePoolAddr));
//        require(success);
    }
 
}