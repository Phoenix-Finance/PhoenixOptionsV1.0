pragma solidity ^0.5.1;
import "../FNXOracle.sol";

contract TestFNXOracle is FNXOracle {
    /**
  * @notice retrieves price of an asset
  * @dev function to get price for an asset
  * @param asset Asset for which to get the price
  * @return uint mantissa of asset price (scaled by 1e8) or zero if unset or contract paused
  */
    function getPrice(address asset) public view returns (uint){
        uint256 price = FNXOracle.getPrice(asset);
        if (price != 0) {
            return price;
        }
        return 50*1e8;
    }
    function getUnderlyingPrice(uint256 cToken) public view returns (uint){
        uint256 price = FNXOracle.getUnderlyingPrice(cToken);
        if (price != 0) {
            return price;
        }
        return 9250*1e8;
    }

    function getSellOptionsPrice(address oToken) public view returns (uint){
        uint256 price = FNXOracle.getSellOptionsPrice(oToken);
        if (price != 0) {
            return price;
        }
        return 90*1e8;
    }
    function getBuyOptionsPrice(address oToken) public view returns (uint){
        uint256 price = FNXOracle.getBuyOptionsPrice(oToken);
        if (price != 0) {
            return price;
        }
        return 110*1e8;
    }
    function getEthBalance(address account) public view returns (uint) {
        return account.balance;
    }
}
