pragma solidity ^0.4.26;
import "../OptionsPool.sol";
contract OptionsPoolTest is OptionsPool {
        constructor (address oracleAddr,address optionsPriceAddr,address ivAddress) OptionsPool(oracleAddr,optionsPriceAddr,ivAddress) public{
    }
    function getOptionsWorth(uint8 optType,uint256 strikePrice,uint256 underlyingPrice) public pure returns(uint256){
        return _getOptionsWorth(optType,strikePrice,underlyingPrice);
    }
    function getOptionsPayback(uint8 optType,uint256 strikePrice,uint256 underlyingPrice)public pure returns(uint256){
         return _getOptionsPayback(optType,strikePrice,underlyingPrice);
    }
}

