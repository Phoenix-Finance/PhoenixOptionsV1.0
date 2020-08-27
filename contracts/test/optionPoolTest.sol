pragma solidity ^0.5.1;
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
    /*
    function calTimeSharedPrice()public view returns(uint256){
        uint256 timeValue;
        if (begin>=optionPhaseInfo_Share[1] || preTime<optionEx.createdTime){
            timeValue = _calculateFirstTimePrice(optionEx.fullPrice,tempValue,info.strikePrice,
                optionEx.ivNumerator,optionEx.ivDenominator,info.optType);
        }else{
            timeValue = _calculateTimePrice(preTime,tempValue,info.strikePrice,
                optionEx.ivNumerator,optionEx.ivDenominator,info.optType);
        }
    }
    function _calculateFirstTimePrice(uint256 fullPrice,uint256 expiration,uint256 curTime,
            uint256 strikePrice,uint256 ivNumerator,uint256 ivDenominator,uint8 optType)internal view returns (uint256){
        uint256 nowValue = _calculateCurrentPrice(expiration,curTime,strikePrice,ivNumerator,
            ivDenominator,optType);
        return (fullPrice>nowValue)? fullPrice-nowValue : 0;
    }
    function _calculateTimePrice(uint256 preTime,uint256 expiration,uint256 curTime,
            uint256 strikePrice,uint256 ivNumerator,uint256 ivDenominator,uint8 optType)internal view returns (uint256){
        uint256 preValue = _optionsPrice.getOptionsPrice_iv(strikePrice,strikePrice,expiration-preTime,ivNumerator,
            ivDenominator,optType);
        uint256 nowValue = _calculateCurrentPrice(expiration,curTime,strikePrice,ivNumerator,
            ivDenominator,optType);
        return (preValue>nowValue)? preValue-nowValue : 0;
    }
    function _calculateCurrentPrice(uint256 expiration,uint256 curTime,uint256 strikePrice,uint256 ivNumerator,uint256 ivDenominator,uint8 optType)internal view returns (uint256){
        if (expiration > curTime){
        return _optionsPrice.getOptionsPrice_iv(strikePrice,strikePrice,expiration-curTime,ivNumerator,
            ivDenominator,optType);
        }
        return 0;
    }
    */
}

