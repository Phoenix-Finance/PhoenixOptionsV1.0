pragma solidity ^0.4.26;
import "../modules/Ownable.sol";
interface IFNXOracle {
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
contract ImportOracle is Ownable{
    IFNXOracle internal _oracle;
    function getOracleAddress() public view returns(address){
        return address(_oracle);
    }
    function setOracleAddress(address oracle)public onlyOwner{
        _oracle = IFNXOracle(oracle);
    }
}
