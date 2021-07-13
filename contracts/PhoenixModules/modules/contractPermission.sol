pragma solidity =0.5.16;

contract contractPermission {
    
    modifier onlyContract() {
        require(isContract(msg.sender),"caller is not a contract!");
        _;
    }

    modifier notContract() {
        require(!isContract(msg.sender),"caller is a contract!");
        _;
    }
    
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}