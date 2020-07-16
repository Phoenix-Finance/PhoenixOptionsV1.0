pragma solidity ^0.4.26;
import './Ownable.sol';
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
        uint256 index = _getEligibleUnderlyingIndex(underlying);
        if (index==underlyingAssets.length){
            underlyingAssets.push(underlying);
        }
    }
    /**
     * @dev Implementation of revoke an invalid underlying from the underlyingAssets.
     * @param removeUnderlying revoked underlying.
     */
    function removeunderlyingAssets(uint32 removeUnderlying)public onlyOwner {
        uint256 index = _getEligibleUnderlyingIndex(removeUnderlying);
        if (index<underlyingAssets.length){
            if (index!=underlyingAssets.length-1) {
                underlyingAssets[index] = underlyingAssets[underlyingAssets.length-1];
            }
            underlyingAssets.length--;
        }
    }
    /**
     * @dev Implementation of getting the eligible underlyingAssets.
     */
    function getunderlyingAssets()public view returns (uint32[]){
        return underlyingAssets;
    }
    /**
     * @dev Implementation of testing whether the input underlying is eligible.
     * @param underlying input underlying for testing.
     */    
    function isEligibleUnderlyingAsset(uint32 underlying) public view returns (bool){
        uint256 index = _getEligibleUnderlyingIndex(underlying);
        return index<underlyingAssets.length;
    }
    function _getEligibleUnderlyingIndex(uint32 underlying) internal view returns (uint256){
        for (uint256 i=0;i<underlyingAssets.length;i++){
            if (underlyingAssets[i] == underlying)
                break;
        }
        return i;
    }
}