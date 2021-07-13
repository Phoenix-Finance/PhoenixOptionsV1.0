pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */
/**
 * @title  phxProxy Contract

 */
import "../proxyModules/proxyOwner.sol";
contract phxProxy is proxyOwner {
    bytes32 private constant implementPositon = keccak256("org.Phoenix.implementation.storage");
    event Upgraded(address indexed implementation,uint256 indexed version);
    constructor(address implementation_,address multiSignature) proxyOwner(multiSignature) public {

        // Creator of the contract is admin during initialization
        (bool success,) = implementation_.delegatecall(abi.encodeWithSignature("initialize()"));
        _setImplementation(implementation_);
        require(success);
    }
    function proxyType() public pure returns (uint256){
        return 2;
    }
    /**
     * @dev Tells the address of the current implementation
     * @return address of the current implementation
     */
    function implementation() public view returns (address impl) {
        bytes32 position = implementPositon;
        assembly {
            impl := sload(position)
        }
    }
    function _setImplementation(address _newImplementation) internal 
    {
        (bool success, bytes memory returnData) = _newImplementation.delegatecall(abi.encodeWithSignature("implementationVersion()"));
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize)
            }
        }
        uint256 version_ = abi.decode(returnData, (uint256));
        require (version_>version(),"upgrade version number must be greater than current version");
        bytes32 position = implementPositon;
        assembly {
            sstore(position, _newImplementation)
        }
        _setVersion(version_);
        emit Upgraded(_newImplementation,version_);
    }
    function upgradeTo(address _newImplementation)public OwnerOrOrigin{
        address currentImplementation = implementation();
        require(currentImplementation != _newImplementation,"upgrade implementation is not changed!");
        (bool success,) = _newImplementation.delegatecall(abi.encodeWithSignature("update()"));
        _setImplementation(_newImplementation);
        require(success);
    }
    function () payable external {
        address _impl = implementation();
        require(_impl != address(0));

        assembly {
        let ptr := mload(0x40)
        calldatacopy(ptr, 0, calldatasize)
        let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
        let size := returndatasize
        returndatacopy(ptr, 0, size)

        switch result
        case 0 { revert(ptr, size) }
        default { return(ptr, size) }
        }
    }
}
