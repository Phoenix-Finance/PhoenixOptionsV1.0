pragma solidity ^0.4.11;
import './Ownable.sol';
contract Managerable is Ownable {

    address private _managerAddress;

    modifier onlyManager() {
        require(_managerAddress == msg.sender,"Managerable: caller is not the Manager");
        _;
    }
    /// @notice function Emergency situation that requires
    /// @notice contribution period to stop or not.
    function setManager(address managerAddress)
    public
    onlyOwner
    {
        _managerAddress = managerAddress;
    }
    function getManager()public view returns (address) {
        return _managerAddress;
    }
}