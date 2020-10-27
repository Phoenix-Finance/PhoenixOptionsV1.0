pragma solidity =0.5.16;
import "../modules/Ownable.sol";
interface IFNXOracle {
    /**
  * @notice retrieves price of an asset
  * @dev function to get price for an asset
  * @param asset Asset for which to get the price
  * @return uint mantissa of asset price (scaled by 1e8) or zero if unset or contract paused
  */
    function getPrice(address asset) external view returns (uint256);
    function getUnderlyingPrice(uint256 cToken) external view returns (uint256);
    function getPrices(uint256[] calldata assets) external view returns (uint256[]memory);
    function getAssetAndUnderlyingPrice(address asset,uint256 underlying) external view returns (uint256,uint256);
//    function getSellOptionsPrice(address oToken) external view returns (uint256);
//    function getBuyOptionsPrice(address oToken) external view returns (uint256);
}
contract ImportOracle is Ownable{
    IFNXOracle internal _oracle;
    function oraclegetPrices(uint256[] memory assets) internal view returns (uint256[]memory){
        uint256[] memory prices = _oracle.getPrices(assets);
        uint256 len = assets.length;
        for (uint i=0;i<len;i++){
        require(prices[i] >= 100 && prices[i] <= 1e30);
        }
        return prices;
    }
    function oraclePrice(address asset) internal view returns (uint256){
        uint256 price = _oracle.getPrice(asset);
        require(price >= 100 && price <= 1e30);
        return price;
    }
    function oracleUnderlyingPrice(uint256 cToken) internal view returns (uint256){
        uint256 price = _oracle.getUnderlyingPrice(cToken);
        require(price >= 100 && price <= 1e30);
        return price;
    }
    function oracleAssetAndUnderlyingPrice(address asset,uint256 cToken) internal view returns (uint256,uint256){
        (uint256 price1,uint256 price2) = _oracle.getAssetAndUnderlyingPrice(asset,cToken);
        require(price1 >= 100 && price1 <= 1e30);
        require(price2 >= 100 && price2 <= 1e30);
        return (price1,price2);
    }
    function getOracleAddress() public view returns(address){
        return address(_oracle);
    }
    function setOracleAddress(address oracle)public onlyOwner{
        _oracle = IFNXOracle(oracle);
    }
}
