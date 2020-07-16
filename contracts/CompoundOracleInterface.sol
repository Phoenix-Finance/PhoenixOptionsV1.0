pragma solidity ^0.4.26;

interface ICompoundOracle {
    /**
  * @notice retrieves price of an asset
  * @dev function to get price for an asset
  * @param asset Asset for which to get the price
  * @return uint mantissa of asset price (scaled by 1e18) or zero if unset or contract paused
  */
    function getPrice(address asset) external view returns (uint256);
    function getUnderlyingPrice(uint256 cToken) external view returns (uint256);
    function getSellOptionsPrice(address oToken) external view returns (uint256);
    function getBuyOptionsPrice(address oToken) external view returns (uint256);

}
