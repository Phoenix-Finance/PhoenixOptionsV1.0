pragma solidity ^0.4.26;
import "./CompoundOracleInterface.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
contract CompoundOracle is ICompoundOracle,Ownable {
    using SafeMath for uint256;
    uint256 public ValidUntil = 600;
    struct priceInfo {
        uint256 inptutTime;
        uint256 price;
    }
    mapping(uint256 => priceInfo) private priceMap;
    function setValidUntil(uint256 timeLimit) public onlyOwner {
        ValidUntil = timeLimit;
    }
    /**
      * @notice set price of an asset
      * @dev function to set price for an asset
      * @param asset Asset for which to set the price
      * @param price the Asset's price
      */    
    function setPrice(address asset,uint256 price) public onlyOwner {
        priceMap[uint256(asset)].price = price;
        priceMap[uint256(asset)].inptutTime = now;
    }
    /**
      * @notice set price of an underlying
      * @dev function to set price for an underlying
      * @param underlying underlying for which to set the price
      * @param price the underlying's price
      */  
    function setUnderlyingPrice(uint256 underlying,uint256 price) public onlyOwner {
        require(underlying>0 , "underlying cannot be zero");
        priceMap[underlying].price = price;
        priceMap[underlying].inptutTime = now;
    }
    /**
    * @notice set a group of prices for assets and a group of prices for underlying
    * @dev function to set a group of prices for assets and a group of prices for underlying
    * @param assets a set of asset for which to set the price
    * @param assetPrices  a set of the Asset's price
    * @param underlyings a set of underlyings for which to set the price
    * @param ulPrices  a set of the underlyings's price
    */    
    function setPriceAndUnderlyingPrice(address[] assets,uint256[] assetPrices,uint256[] underlyings,uint256[] ulPrices) public onlyOwner {
        require(assets.length == assetPrices.length,"assets and assetPrices are not of the same length");
        require(underlyings.length == ulPrices.length,"underlyings and ulPrices are not of the same length");
        for (uint i = 0;i<assets.length;i++) {
            priceMap[uint256(assets[i])].price = assetPrices[i];
            priceMap[uint256(assets[i])].inptutTime = now;
        }
        for (i = 0;i<underlyings.length;i++) {
            priceMap[underlyings[i]].price = ulPrices[i];
            priceMap[underlyings[i]].inptutTime = now;
        }
    }
    /**
      * @notice set price of an options token sell price
      * @dev function to set an options token sell price
      * @param optoken options token for which to set the sell price
      * @param price the options token sell price
      */     
    function setSellOptionsPrice(address optoken,uint256 price) public onlyOwner {
        uint256 key = uint256(optoken)*10+1;
        priceMap[key].price = price;
        priceMap[key].inptutTime = now;
    }
    /**
      * @notice set price of an options token buy price
      * @dev function to set an options token buy price
      * @param optoken options token for which to set the buy price
      * @param price the options token buy price
      */      
    function setBuyOptionsPrice(address optoken,uint256 price) public onlyOwner {
        uint256 key = uint256(optoken)*10+2;
        priceMap[key].price = price;
        priceMap[key].inptutTime = now;
    }
    /**
      * @notice set price of a group of option tokens buy and sell prices
      * @dev function to set price of a group of option tokens buy and sell prices
      * @param optokens a group of option tokens for which to set the buy and sell price
      * @param buyPrices a group of buy prices
      * @param SellPrices a group of sell prices
      */    
    function setOptionsBuyAndSellPrice(address[] optokens,uint256[] buyPrices,uint256[] SellPrices) public onlyOwner {
        require(optokens.length == buyPrices.length,"optokens and buyPrices are not of the same length");
        require(optokens.length == SellPrices.length,"optokens and SellPrices are not of the same length");
        for (uint i=0; i<optokens.length; i++) {
            uint256 sellkey = uint256(optokens[i])*10+1;
            priceMap[sellkey].price = SellPrices[i];
            priceMap[sellkey].inptutTime = now;
        }
        for (i=0; i<optokens.length; i++) {
            uint256 buykey = uint256(optokens[i])*10+2;
            priceMap[buykey].price = buyPrices[i];
            priceMap[buykey].inptutTime = now;
        }
    }
    /**
  * @notice retrieves price of an asset
  * @dev function to get price for an asset
  * @param asset Asset for which to get the price
  * @return uint mantissa of asset price (scaled by 1e18) or zero if unset or contract paused
  */
    function getPrice(address asset) public view returns (uint256) {
        return _getPriceInfo(uint256(asset));
    }
    function getUnderlyingPrice(uint256 underlying) public view returns (uint256) {
        return _getPriceInfo(underlying);
    }

    function getSellOptionsPrice(address oToken) public view returns (uint256) {
        uint256 key = uint256(oToken)*10+1;
        return _getPriceInfo(key);

    }
    function getBuyOptionsPrice(address oToken) public view returns (uint256) {
        uint256 key = uint256(oToken)*10+2;
        return _getPriceInfo(key);
    }
    function _getPriceInfo(uint256 key) internal view returns (uint256) {
        require(ValidUntil.add(priceMap[key].inptutTime)>now,"Price validity is expired");
        return priceMap[key].price;
    }


    function getPriceDetail(address asset) public view returns (uint256,uint256) {
        return _getPriceDetail(uint256(asset));
    }
    function getUnderlyingPriceDetail(uint256 underlying) public view returns (uint256,uint256) {
        return _getPriceDetail(underlying);
    }

    function getSellOptionsPriceDetail(address oToken) public view returns (uint256,uint256) {
        uint256 key = uint256(oToken)*10+1;
        return _getPriceDetail(key);

    }
    function getBuyOptionsPriceDetail(address oToken) public view returns (uint256,uint256) {
        uint256 key = uint256(oToken)*10+2;
        return _getPriceDetail(key);
    }
    function _getPriceDetail(uint256 key) internal view returns (uint256,uint256) {
        return (priceMap[key].price,priceMap[key].inptutTime);
    }
}
