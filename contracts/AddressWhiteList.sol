pragma solidity ^0.4.26;
import "./Halt.sol";
    /**
     * @dev Implementation of a whitelist filters a eligible address.
     */
contract AddressWhiteList is Halt {

    // The eligible adress list
    address[] public whiteList;
    /**
     * @dev Implementation of add an eligible address into the whitelist.
     * @param addAddress new eligible address.
     */
    function addWhiteList(address addAddress)public onlyOwner{
        uint256 index = _getEligibleAddressIndex(addAddress);
        if (index==whiteList.length){
            whiteList.push(addAddress);
        }
    }
    /**
     * @dev Implementation of revoke an invalid address from the whitelist.
     * @param removeAddress revoked address.
     */
    function removeWhiteList(address removeAddress)public onlyOwner{
        uint256 index = _getEligibleAddressIndex(removeAddress);
        if (index<whiteList.length){
            if (index!=whiteList.length-1) {
                whiteList[index] = whiteList[whiteList.length-1];
            }
            whiteList.length--;
        }
    }
    /**
     * @dev Implementation of getting the eligible whitelist.
     */
    function getWhiteList()public view returns (address[]){
        return whiteList;
    }
    /**
     * @dev Implementation of testing whether the input address is eligible.
     * @param tmpAddress input address for testing.
     */    
    function isEligibleAddress(address tmpAddress) public view returns (bool){
        uint256 index = _getEligibleAddressIndex(tmpAddress);
        return index<whiteList.length;
    }
    function _getEligibleAddressIndex(address tmpAddress) internal view returns (uint256){
        for (uint256 i=0;i<whiteList.length;i++){
            if (whiteList[i] == tmpAddress)
                break;
        }
        return i;
    }
}