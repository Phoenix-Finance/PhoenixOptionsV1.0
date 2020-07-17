pragma solidity ^0.4.26;
import './Ownable.sol';
import "./whiteList.sol";
    /**
     * @dev Implementation of a underlyingAssets filters a eligible underlying.
     */
contract UnderlyingAssets is Ownable {
    // The eligible underlying list
    uint32[] public underlyingAssets;
    /**
     * @dev Implementation of add an eligible underlying into the underlyingAssets.
     * @param underlying new eligible underlying.
     */
    function addUnderlyingAsset(uint32 underlying)public onlyOwner{
        whiteListUint32.addWhiteListUint32(underlyingAssets,underlying);
    }
    /**
     * @dev Implementation of revoke an invalid underlying from the underlyingAssets.
     * @param removeUnderlying revoked underlying.
     */
    function removeUnderlyingAssets(uint32 removeUnderlying)public onlyOwner returns(bool) {
        return whiteListUint32.removeWhiteListUint32(underlyingAssets,removeUnderlying);
    }
    /**
     * @dev Implementation of getting the eligible underlyingAssets.
     */
    function getUnderlyingAssets()public view returns (uint32[]){
        return underlyingAssets;
    }
    /**
     * @dev Implementation of testing whether the input underlying is eligible.
     * @param underlying input underlying for testing.
     */    
    function isEligibleUnderlyingAsset(uint32 underlying) public view returns (bool){
        return whiteListUint32.isEligibleUint32(underlyingAssets,underlying);
    }
    function checkUnderlyingAsset(uint32 underlying) public view{
        return whiteListUint32.checkEligibleUint32(underlyingAssets,underlying);
    }
    function _getEligibleUnderlyingIndex(uint32 underlying) internal view returns (uint256){
        return whiteListUint32._getEligibleIndexUint32(underlyingAssets,underlying);
    }
}