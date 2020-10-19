pragma solidity =0.5.16;
import "./IERC20.sol";
import "./Erc20Data.sol";
import "./Erc20BaseProxy.sol";
/**
 * @title  Erc20Delegator Contract

 */
contract Erc20Proxy is Erc20Data,Erc20BaseProxy {
    constructor(address implementation_) Erc20BaseProxy(implementation_) public  {
    }
}
