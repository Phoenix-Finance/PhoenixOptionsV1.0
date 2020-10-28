pragma solidity =0.5.16;
import "../FNXOracle.sol";

contract TestFNXOracle is FNXOracle {
    constructor () public{
        priceMap[1] = 9250*1e8;
        priceMap[2] = 9250*1e8;
    }
    function getPrices(uint256[]memory assets) public view returns (uint256[]memory) {
        uint256 len = assets.length;
        uint256[] memory prices = FNXOracle.getPrices(assets);
        for (uint i=0;i<len;i){
            if (prices[i] == 0){
                prices[i] = 50e8;
            }
        }
        return prices;
    }
    function getAssetAndUnderlyingPrice(address asset,uint256 underlying) public view returns (uint256,uint256) {
        return (getPrice(asset),getUnderlyingPrice(underlying));
    }
    /**
  * @notice retrieves price of an asset
  * @dev function to get price for an asset
  * @param asset Asset for which to get the price
  * @return uint mantissa of asset price (scaled by 1e8) or zero if unset or contract paused
  */
    uint256 fakeSellOptionPrice = 0;
    uint256 fakeBuyOptionPrice = 0;
    uint256 fakeUnderlyingPrice = 0;
    uint256 fakeAssetPrice = 0;
    function getPrice(address asset) public view returns (uint){
        if (fakeAssetPrice != 0) {
            return fakeAssetPrice;
        }

        uint256 price = FNXOracle.getPrice(asset);
        if (price != 0) {
            return price;
        }

        return 50*1e8;

    }
    function getUnderlyingPrice(uint256 cToken) public view returns (uint){

        if (fakeUnderlyingPrice != 0) {
            return fakeUnderlyingPrice;
        }

        uint256 price = FNXOracle.getUnderlyingPrice(cToken);
        if (price != 0) {
            return price;
        }
        return 9250*1e8;
    }

    function getSellOptionsPrice(address oToken) public view returns (uint){
        if (fakeSellOptionPrice != 0) {
            return fakeSellOptionPrice;
        }

        uint256 price = FNXOracle.getSellOptionsPrice(oToken);
        if (price != 0) {
            return price;
        }
        return 90*1e8;
    }

    function getBuyOptionsPrice(address oToken) public view returns (uint){
        if (fakeBuyOptionPrice != 0) {
            return fakeBuyOptionPrice;
        }

        uint256 price = FNXOracle.getBuyOptionsPrice(oToken);
        if (price != 0) {
            return price;
        }
        return 110*1e8;
    }

    function getEthBalance(address account) public view returns (uint) {
        return account.balance;
    }

    function setFakeAssetPrice(uint256 assetPrice) public {
        fakeAssetPrice = assetPrice;
    }

     function setFakeUnderlyingPrice(uint256 underlyingPrice) public {
         fakeUnderlyingPrice = underlyingPrice;
     }

     function setFakeOptionBuyPrice (uint256 buyPrice) public {
         fakeBuyOptionPrice = buyPrice;
     }

    function setFakeOptionSellPrice(uint256 sellPrice) public {
        fakeSellOptionPrice = sellPrice;
    }

}
