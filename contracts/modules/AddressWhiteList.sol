pragma solidity =0.5.16;
import "./Halt.sol";
import "./whiteList.sol";
    /**
     * @dev Implementation of a whitelist filters a eligible address.
     */
contract AddressWhiteList is Halt {

    using whiteListAddress for address[];
    uint256 constant internal allPermission = 0xffffffff;
    uint256 constant internal allowBuyOptions = 1;
    uint256 constant internal allowSellOptions = 1<<1;
    uint256 constant internal allowExerciseOptions = 1<<2;
    uint256 constant internal allowAddCollateral = 1<<3;
    uint256 constant internal allowRedeemCollateral = 1<<4;
    // The eligible adress list
    address[] internal whiteList;
    mapping(address => uint256) internal addressPermission;
    /**
     * @dev Implementation of add an eligible address into the whitelist.
     * @param addAddress new eligible address.
     */
    function addWhiteList(address addAddress)public onlyOwner{
        whiteList.addWhiteListAddress(addAddress);
        addressPermission[addAddress] = allPermission;
    }
    function modifyPermission(address addAddress,uint256 permission)public onlyOwner{
        addressPermission[addAddress] = permission;
    }
    /**
     * @dev Implementation of revoke an invalid address from the whitelist.
     * @param removeAddress revoked address.
     */
    function removeWhiteList(address removeAddress)public onlyOwner returns (bool){
        addressPermission[removeAddress] = 0;
        return whiteList.removeWhiteListAddress(removeAddress);
    }
    /**
     * @dev Implementation of getting the eligible whitelist.
     */
    function getWhiteList()public view returns (address[] memory){
        return whiteList;
    }
    /**
     * @dev Implementation of testing whether the input address is eligible.
     * @param tmpAddress input address for testing.
     */    
    function isEligibleAddress(address tmpAddress) public view returns (bool){
        return whiteList.isEligibleAddress(tmpAddress);
    }
    function checkAddressPermission(address tmpAddress,uint256 state) public view returns (bool){
        return  (addressPermission[tmpAddress]&state) == state;
    }
    modifier addressPermissionAllowed(address tmpAddress,uint256 state){
        require(checkAddressPermission(tmpAddress,state) , "Input address is not allowed");
        _;
    }
}