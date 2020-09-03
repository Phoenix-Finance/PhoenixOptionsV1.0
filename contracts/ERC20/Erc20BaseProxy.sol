pragma solidity =0.5.16;
import "./Erc20Data.sol";
import "../Proxy/baseProxy.sol";
/**
 * @title  Erc20Delegator Contract

 */
contract Erc20BaseProxy is baseProxy{
    constructor(address implementation_) baseProxy(implementation_) public  {
    }
    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     *  dst  The address of the destination account
     *  amount  The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
     function totalSupply() external view returns (uint256){
         delegateToViewAndReturn();
     }
    function transfer(address /*dst*/, uint /*amount*/) external returns (bool) {
        delegateAndReturn();
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     */
    function transferFrom(address /*src*/, address /*dst*/, uint256 /*amount*/) external returns (bool) {
        delegateAndReturn();
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     * @return Whether or not the approval succeeded
     */
    function approve(address /*spender*/, uint256 /*amount*/) external returns (bool) {
        delegateAndReturn();
    }

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * owner The address of the account which owns the tokens to be spent
     * spender The address of the account which may transfer tokens
     * @return The number of tokens allowed to be spent (-1 means infinite)
     */
    function allowance(address /*owner*/, address /*spender*/) external view returns (uint) {
        delegateToViewAndReturn();
    }

    /**
     * @notice Get the token balance of the `owner`
     * owner The address of the account to query
     * @return The number of tokens owned by `owner`
     */
    function balanceOf(address /*owner*/) external view returns (uint) {
        delegateToViewAndReturn();
    }
}
