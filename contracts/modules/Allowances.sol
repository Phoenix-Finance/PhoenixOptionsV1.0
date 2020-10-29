pragma solidity =0.5.16;
import './Ownable.sol';
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * each operator can be granted exclusive access to specific functions.
 *
 */
contract Allowances is Ownable {
    mapping (address => uint256) internal allowances;
    bool internal bValid = false;
    /**
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public onlyOwner{
        allowances[spender] = amount;
    }
    function allowance(address spender) public view returns (uint256) {
        return allowances[spender];
    }
    function setValid(bool _bValid) public onlyOwner{
        bValid = _bValid;
    }
    function checkAllowance(address spender, uint256 amount) public view returns(bool){
        return (!bValid) || (allowances[spender] >= amount);
    }
    modifier sufficientAllowance(address spender, uint256 amount){
        require((!bValid) || (allowances[spender] >= amount),"Allowances : user's allowance is unsufficient!");
        _;
    }
}