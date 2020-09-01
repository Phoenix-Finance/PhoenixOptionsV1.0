pragma solidity ^0.5.1;
import "../interfaces/IERC20.sol";
import "./Proxy.sol";
contract Erc20Proxy is IERC20,Proxy {

    function transfer(address recipient, uint256 amount)public returns (bool){
        (bool success, bytes memory returnData) = implementation.delegatecall(
            abi.encodeWithSignature("transfer(address,uint256)",recipient,amount));
        require(success);
        return abi.decode(returnData, (bool));
    }
    /**
     * @dev Move sender's FPT to 'recipient' balance, a interface in ERC20. 
     * @param sender sender's account.
     * @param recipient recipient's account.
     * @param amount amount of FPT.
     */ 
    function transferFrom(address sender, address recipient, uint256 amount)public returns (bool){
        (bool success, bytes memory returnData) = implementation.delegatecall(
            abi.encodeWithSignature("transferFrom(address,address,uint256)",sender,recipient,amount));
        require(success);
        return abi.decode(returnData, (bool));
    }
    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        delegateToViewAndReturn();
    }
    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        delegateToViewAndReturn();
    }
        /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        (bool success, bytes memory returnData) = implementation.delegatecall(
            abi.encodeWithSignature("approve(address,address)",spender,amount));
        require(success);
        return abi.decode(returnData, (bool));
    }
    function allowance(address owner, address spender) public view returns (uint256){
        delegateToViewAndReturn();
    }
}