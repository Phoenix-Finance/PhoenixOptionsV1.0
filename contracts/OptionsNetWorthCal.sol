pragma solidity ^0.4.26;
import "./OptionsBase.sol";
import "./modules/tuple.sol";
import "./OptionsOccupiedCal.sol";
import "./interfaces/IOptionsPrice.sol";
import "./modules/SafeInt256.sol";
contract OptionsNetWorthCal is OptionsOccupiedCal,ImportOptionsPrice {

    uint256 private firstOption;    //firstOption,lastOption,lastBurn
    mapping(address=>int256) private optionsLatestNetWorth;
    using SafeInt256 for int256;
    
    function getNetWrothCalInfo(address[] memory whiteList)public view returns(uint256,int256[]){
        uint256 len = whiteList.length;
        int256[] memory latestNetWorth = new int256[](len);
            for (uint256 i = 0;i<len;i++){
            latestNetWorth[i] = optionsLatestNetWorth[whiteList[i]];
        }
        return (firstOption,latestNetWorth);
    }
    function getNetWrothLatestWorth(address settlement)public view returns(int256){
        return optionsLatestNetWorth[settlement];
    }
    function setSharedState(uint256 newFirstOption,int256[] latestNetWorth,address[] memory whiteList) public onlyManager{
        if (newFirstOption > firstOption){
            firstOption = newFirstOption;
        }
        uint256 len = whiteList.length;
        for (uint256 i = 0;i<len;i++){
            optionsLatestNetWorth[whiteList[i]] += latestNetWorth[i];
        }
    }
    function calRangeSharedPayment(uint256 lastOption,uint256 begin,uint256 end,address[] memory whiteList)
            public view returns(uint256[],uint256,bool){
        if (begin>=lastOption || end < firstOption){
            return(new uint256[](whiteList.length),0,false);
        }
        if (end>lastOption) {
            end = lastOption;
        }
        (uint256[] memory sharedBalances,uint256 _firstOption) = 
            _calculateSharedPayment(begin,end,whiteList);
        return (sharedBalances,_firstOption,true);
    }
    function _calculateSharedPayment(uint256 begin,uint256 end,address[] memory whiteList)
            internal view returns(uint256[],uint256){
        uint256[] memory totalSharedPayment = new uint256[](whiteList.length);
        uint256 newFirstOption;
        (begin,newFirstOption) = getFirstOption(begin,firstOption,end); 
        for (;begin<end;begin++){
            OptionsInfo storage info = allOptions[begin];
            OptionsInfoEx storage optionEx = optionExtraMap[begin];
            uint256 timeValue = _calculateCurrentPrice(optionEx.underlyingPrice,info.strikePrice,info.expiration,
                optionEx.ivNumerator,optionEx.ivDenominator,info.optType);
                emit DebugEvent(1111111,timeValue,optionEx.fullPrice);
            if (timeValue<optionEx.fullPrice){
                timeValue = optionEx.fullPrice - timeValue;
                uint256 index = whiteListAddress._getEligibleIndexAddress(whiteList,optionEx.settlement);
                timeValue = optionEx.tokenTimePrice.mul(timeValue).mul(info.amount)/calDecimals;
                totalSharedPayment[index] = totalSharedPayment[index].add(timeValue);
            }
        }
        return (totalSharedPayment,newFirstOption);
    }
    function calculateExpiredPayment(uint256 begin,uint256 end,address[] memory whiteList)public view returns(int256[]){
        int256[] memory totalExpiredPayment = new int256[](whiteList.length);
        for (;begin<end;begin++){
            OptionsInfo storage info = allOptions[begin];
            if (info.amount>0){
                OptionsInfoEx storage optionEx = optionExtraMap[begin];
                uint256 index = whiteListAddress._getEligibleIndexAddress(whiteList,optionEx.settlement);
                uint256 timeValue = optionEx.tokenTimePrice.mul(info.amount)/calDecimals;
                totalExpiredPayment[index] = totalExpiredPayment[index].add(int256(timeValue));
            }
        }
        return totalExpiredPayment;
    }
    function calculatePhaseOptionsFall(uint256 lastOption,uint256 begin,uint256 end,address[] memory whiteList) public view returns(int256[]){
        if (begin>=lastOption || end < firstOption){
            return new int256[](whiteList.length);
        }
        if (end>lastOption) {
            end = lastOption;
        }
        if (begin <= firstOption) {
            begin = firstOption;
        }
        uint256[] memory prices = getUnderlyingPrices();
        int256[] memory OptionsFallBalances = _calRangeOptionsFall(begin,end,whiteList,prices);
        uint256 whiteListLen = whiteList.length;
        for (uint256 index = 0;index<whiteListLen;index++){
            OptionsFallBalances[index] = OptionsFallBalances[index]/(int256(_oracle.getPrice(whiteList[index])));
        }
        return OptionsFallBalances;
    }
    function _calRangeOptionsFall(uint256 begin,uint256 lastOption,address[] memory whiteList,uint256[] memory prices)
                 internal view returns(int256[] memory){
        int256[] memory OptionsFallBalances = new int256[](whiteList.length);
        for (;begin<lastOption;begin++){
            OptionsInfo storage info = allOptions[begin];
            if(info.expiration<now || info.amount == 0){
                continue;
            }
            index = _getEligibleUnderlyingIndex(info.underlying);
            uint256 curValue = _calCurtimeCallateralFall(info,info.amount,prices[index]);
            if (curValue != 0){
                OptionsInfoEx storage optionEx = optionExtraMap[begin];
                uint256 index = whiteListAddress._getEligibleIndexAddress(whiteList,optionEx.settlement);
                OptionsFallBalances[index] = OptionsFallBalances[index]-int256(curValue);
            }
        }
        return OptionsFallBalances;
    }

    function _calCurtimeCallateralFall(OptionsInfo memory info,uint256 amount,uint256 curPrice) internal view returns(uint256){
        if (info.expiration<=now || amount == 0){
            return 0;
        }
        return _getOptionsPayback(info.optType,info.strikePrice,curPrice).mul(amount);
    }
    function _addNewOptionsNetworth(OptionsInfo memory info)  internal {
        OptionsInfoEx storage infoEx =  optionExtraMap[info.optionID-1];
        uint256 price = _oracle.getPrice(infoEx.settlement);
        uint256 curValue = _calCurtimeCallateralFall(info,info.amount,infoEx.underlyingPrice)/price;
        optionsLatestNetWorth[infoEx.settlement] = optionsLatestNetWorth[infoEx.settlement].sub(int256(curValue));
    }
    function _burnOptionsNetworth(OptionsInfo memory info,uint256 amount,uint256 underlyingPrice,uint256 currentPrice) internal returns (uint256) {
        uint256 curValue = _calCurtimeCallateralFall(info,amount,underlyingPrice);
        OptionsInfoEx storage optionEx = optionExtraMap[info.optionID-1];
        uint256 timeWorth = optionEx.fullPrice>currentPrice ? optionEx.fullPrice-currentPrice : 0;
        timeWorth = optionEx.tokenTimePrice.mul(timeWorth*amount)/calDecimals;
        curValue = curValue / _oracle.getPrice(optionEx.settlement);
        emit DebugEvent(123456789,curValue,timeWorth);
        int256 value = int256(curValue) - int256(timeWorth);
        optionsLatestNetWorth[optionEx.settlement] = optionsLatestNetWorth[optionEx.settlement]+value;
    }
    function _calculateCurrentPrice(uint256 curprice,uint256 strikePrice,uint256 expiration,uint256 ivNumerator,uint256 ivDenominator,uint8 optType)internal view returns (uint256){
        if (expiration > now){
            return _optionsPrice.getOptionsPrice_iv(curprice,strikePrice,expiration-now,ivNumerator,
                ivDenominator,optType);
        }
        return 0;
    }
}