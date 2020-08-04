pragma solidity ^0.4.26;
import "./OptionsNetWorthCal.sol";
import "./modules/tuple.sol";

contract OptionsPool is OptionsNetWorthCal {

    constructor (address oracleAddr,address optionsPriceAddr,address ivAddress)public{
        setOracleAddress(oracleAddr);
        setOptionsPriceAddress(optionsPriceAddr);
        setVolatilityAddress(ivAddress);
    }
    function getOptionCalRangeAll(address[] whiteList)public view returns(uint256,int256,uint256,int256[],uint256,uint256){
        (uint256 occupiedFirst,int256 occupiedlatest) = getOccupiedCalInfo();
        (uint256 netFirst,int256[] memory netLatest) = getNetWrothCalInfo(whiteList);
        return (occupiedFirst,occupiedlatest,netFirst,netLatest,allOptions.length,block.number);
    }
    function createOptions(address from,address settlement,uint256 type_ly_exp,uint256 strikePrice,uint256 optionPrice,
                uint256 amount) onlyManager public {
        _createOptions(from,settlement,type_ly_exp,strikePrice,optionPrice,amount);
        OptionsInfo memory info = _getOptionsById(allOptions.length);
        _addOptionsCollateral(info);
        _addNewOptionsNetworth(info);
    }
    function burnOptions(address from,uint256 id,uint256 amount,uint256 optionPrice)public onlyManager{
        _burnOptions(from,id,amount);
        OptionsInfo memory info = _getOptionsById(id);
        uint256 currentPrice = _oracle.getUnderlyingPrice(info.underlying);
        _burnOptionsCollateral(info,amount,currentPrice);
        _burnOptionsNetworth(info,amount,currentPrice,optionPrice);
    }
}