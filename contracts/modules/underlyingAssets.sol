pragma solidity =0.5.16;
import './Ownable.sol';
import "./whiteList.sol";
    /**
     * @dev Implementation of a underlyingAssets filters a eligible underlying.
     */
contract UnderlyingAssets is Ownable {
    using whiteListUint32 for uint32[];
    // The eligible underlying list
    uint32[] internal underlyingAssets;
    /**
     * @dev Implementation of add an eligible underlying into the underlyingAssets.
     * @param underlying new eligible underlying.
     */
    function addUnderlyingAsset(uint32 underlying)public onlyOwner{
        underlyingAssets.addWhiteListUint32(underlying);
    }
    function setUnderlyingAsset(uint32[] memory underlyings)public onlyOwner{
        underlyingAssets = underlyings;
    }
    /**
     * @dev Implementation of revoke an invalid underlying from the underlyingAssets.
     * @param removeUnderlying revoked underlying.
     */
    function removeUnderlyingAssets(uint32 removeUnderlying)public onlyOwner returns(bool) {
        return underlyingAssets.removeWhiteListUint32(removeUnderlying);
    }
    /**
     * @dev Implementation of getting the eligible underlyingAssets.
     */
    function getUnderlyingAssets()public view returns (uint32[] memory){
        return underlyingAssets;
    }
    /**
     * @dev Implementation of testing whether the input underlying is eligible.
     * @param underlying input underlying for testing.
     */    
    function isEligibleUnderlyingAsset(uint32 underlying) public view returns (bool){
        return underlyingAssets.isEligibleUint32(underlying);
    }
    function _getEligibleUnderlyingIndex(uint32 underlying) internal view returns (uint256){
        return underlyingAssets._getEligibleIndexUint32(underlying);
    }
}