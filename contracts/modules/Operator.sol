pragma solidity ^0.4.11;
import './Ownable.sol';
contract Operator is Ownable {

    address private _operator;

    modifier onlyOperator() {
        require(_operator == msg.sender,"Managerable: caller is not the Operator");
        _;
    }
    /// @notice function Emergency situation that requires
    /// @notice contribution period to stop or not.
    function setOperator(address operator)
    public
    onlyOwner
    {
        _operator = operator;
    }
    function getOperator()public view returns (address) {
        return _operator;
    }
}