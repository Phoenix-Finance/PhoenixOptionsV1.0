pragma solidity ^0.4.26;
import "./OptionsBase.sol";
import "./modules/tuple.sol";
contract OptionsPool is OptionsBase {

    //calculate options Collateral occupied phases
    uint32 public optionPhase = 400;
    uint256[3] internal optionPhaseInfo;    //firstOption,lastOption,lastBurn
    mapping(uint256=>uint256) internal OptionsPhases;
    //each burn options
    mapping(uint256=>uint256[2]) internal burnedOptions;
    uint256 internal burnedLength;
    //calculate Options time shared value phases
    uint32 public sharedPhase = 400;
    uint256[3] internal optionPhaseInfo_Share;  //firstOption,lastOption,lastBurn
    mapping (uint256 =>uint256) internal OptionsPhaseTimes;
    mapping (uint256 =>uint256[]) internal OptionsPhasePrices;
    //each block burn options

    constructor (address oracleAddr,address optionsPriceAddr,address ivAddress) OptionsBase(oracleAddr,optionsPriceAddr,ivAddress) public{
    }

    function getOptionPhaseCalRange()public view returns(uint256,uint256,uint256){
        return (optionPhaseInfo[0],allOptions.length,burnedLength);
    }
    function getsharedPhaseCalRange()public view returns(uint256,uint256,uint256,uint256){
        return (optionPhaseInfo_Share[0],allOptions.length,burnedLength,now);
    }
    function getsharedPhaseCalInfo(uint256 index)public view returns(uint256,uint256[]){
        return (OptionsPhaseTimes[index],OptionsPhasePrices[index]);
    }
    //index,lastOption,lastBurned
    function setPhaseOccupiedCollateral(uint256 calInfo) public onlyOwner {
        (uint256 totalOccupied,uint256 beginOption,bool success) = calculatePhaseOccupiedCollateral(calInfo);
        if (success){
            setCollateralPhase(calInfo,totalOccupied,beginOption);
        }
    }
    function setCollateralPhase(uint256 calInfo,uint256 totalOccupied,uint256 beginOption) public onlyOwner{
        if (beginOption > optionPhaseInfo[0]){
            optionPhaseInfo[0] = beginOption;
        }
        if (tuple64.getValue0(calInfo)*optionPhase+optionPhase > tuple64.getValue1(calInfo)){
            optionPhaseInfo[1] = tuple64.getValue1(calInfo);
            optionPhaseInfo[2] = tuple64.getValue2(calInfo);
        }
        OptionsPhases[tuple64.getValue0(calInfo)] = totalOccupied;
    }
    function calculatePhaseOccupiedCollateral(uint256 calInfo) public view returns(uint256,uint256,bool){
        uint256 beginOption = tuple64.getValue0(calInfo).mul(optionPhase);
        if (beginOption>=tuple64.getValue1(calInfo)){
            return (0,0,false);
        }
        uint256 endOption = beginOption.add(optionPhase);
        if (endOption>tuple64.getValue1(calInfo)) {
            endOption = tuple64.getValue1(calInfo);
        }else if(endOption < optionPhaseInfo[0]){
            return (0,0,false);
        }
        (uint256 totalOccupied,uint256 newFirstOption) = _calculateOccupiedCollateral(beginOption,endOption);
        return (totalOccupied,newFirstOption,true);
    }
    function _calculateOccupiedCollateral(uint256 begin,uint256 end)internal view returns(uint256,uint256){
        uint256 newFirstOption = optionPhaseInfo[0];
        bool bfirstPhase = begin <= newFirstOption;
        if (bfirstPhase) {
            begin = newFirstOption;
        }
        uint256[] memory prices = getUnderlyingPrices();
        uint256 totalOccupied = 0;
        for (;begin<end;begin++){
            uint256 index = _getEligibleUnderlyingIndex(allOptions[begin].underlying);
            uint256 value = calOptionsCollateral(allOptions[begin],prices[index]);
            if (bfirstPhase && value > 0){
                newFirstOption = begin;
                bfirstPhase = false;
            }
            totalOccupied = totalOccupied.add(value);
        }
        //all options in this phase are empty;
        if (bfirstPhase){
            newFirstOption = begin;
        }
        return (totalOccupied,newFirstOption);
    }
    function setSharedState(uint256 calInfo,uint256 firstOption,uint256[] prices,uint256 calTime) public onlyManager{
        if (firstOption > optionPhaseInfo_Share[0]){
            optionPhaseInfo_Share[0] = firstOption;
        }
        if (tuple64.getValue0(calInfo)*sharedPhase+sharedPhase > tuple64.getValue1(calInfo)){
            optionPhaseInfo_Share[1] = tuple64.getValue1(calInfo);
            optionPhaseInfo_Share[2] = tuple64.getValue2(calInfo);
        }
        OptionsPhaseTimes[tuple64.getValue0(calInfo)] = calTime;
        OptionsPhasePrices[tuple64.getValue0(calInfo)] = prices;
    }
    function calculatePhaseSharedPayment(uint256 calInfo,address[] memory whiteList)
        public view returns(uint256[],uint256,bool){
        uint256 beginOption = tuple64.getValue0(calInfo).mul(sharedPhase);
        return calRangeSharedPayment(calInfo,beginOption,beginOption.add(sharedPhase),whiteList);
    }
    function calRangeSharedPayment(uint256 calInfo,uint256 begin,uint256 end,address[] memory whiteList)
            public view returns(uint256[],uint256,bool){
        if (begin>=tuple64.getValue1(calInfo) || end < optionPhaseInfo_Share[0]){
            return(sharedBalances,0,false);
        }
        if (end>tuple64.getValue1(calInfo)) {
            end = tuple64.getValue1(calInfo);
        }
        (uint256[] memory sharedBalances,uint256 _firstOption) = 
            _calculateSharedPayment(begin,end,OptionsPhaseTimes[tuple64.getValue0(calInfo)],tuple64.getValue2(calInfo),whiteList);
        return (sharedBalances,_firstOption,true);
    }
    function _calculateSharedPayment(uint256 begin,uint256 end,uint256 preTime,uint256 lastburn,address[] memory whiteList)
            internal view returns(uint256[],uint256){
        
        uint256 newFirstOption;
        (begin,newFirstOption) = getSharedFirstOption(begin,end,preTime);
        uint256[] memory totalSharedPayment = new uint256[](whiteList.length);
        for (;begin<end;begin++){
            OptionsInfo storage info = allOptions[begin];
            uint256 tempValue = info.expiration;
            if(tempValue<preTime || info.amount == 0){
                continue;
            }
            OptionsInfoEx storage optionEx = optionExtraMap[begin];
            uint256 timeValue = _calculateTimePrice(preTime,optionEx.createdTime,tempValue,info.strikePrice,
                    optionEx.ivNumerator,optionEx.ivDenominator,info.optType);
            if (timeValue>0){
                tempValue = whiteListAddress._getEligibleIndexAddress(whiteList,optionEx.settlement);
                timeValue = optionEx.tokenTimePrice.mul((timeValue)).mul(info.amount).div(optionEx.fullPrice);
                totalSharedPayment[tempValue] = totalSharedPayment[tempValue].add(timeValue);
            }
        }
        //burned
        return (_calBurnedSharePrice(begin,end,preTime,lastburn,whiteList,totalSharedPayment),newFirstOption);
    }
    function getSharedFirstOption(uint256 begin,uint256 end,uint256 preTime) internal view returns(uint256,uint256){
        uint256 newFirstOption = optionPhaseInfo_Share[0];
        if (begin > newFirstOption){
            return (begin,newFirstOption);
        }
        begin = newFirstOption;
        for (;begin<end;begin++){
            OptionsInfo storage info = allOptions[begin];
            if(info.expiration<preTime || info.amount == 0){
                continue;
            }
            break;
        }
        return (begin,begin);
    }
    function _calBurnedSharePrice(uint256 beginIndex,uint256 endIndex,uint256 preTime,uint256 lastburn,address[] memory whiteList,uint256[] memory totalSharedPayment)public view returns(uint256[]){
        for (uint256 i = optionPhaseInfo_Share[2];i<lastburn;i++){
            uint256[2] memory burnInfo = burnedOptions[i];
            if(burnInfo[0]<beginIndex || burnInfo[0] >=endIndex){
                continue;
            }
            OptionsInfo storage info = allOptions[burnInfo[0]];
            uint256 expiration = info.expiration;
            if(expiration<preTime || burnInfo[1] == 0){
                continue;
            }
            OptionsInfoEx storage optionEx = optionExtraMap[burnInfo[0]];
            uint256 nowValue = _optionsPrice.getOptionsPrice_iv(info.strikePrice,info.strikePrice,expiration-now,optionEx.ivNumerator,
                optionEx.ivDenominator,info.optType);
            nowValue = optionEx.tokenTimePrice.mul(nowValue).mul(burnInfo[1]).div(optionEx.fullPrice);
            uint256 index = whiteListAddress._getEligibleIndexAddress(whiteList,optionEx.settlement);
            totalSharedPayment[index] = totalSharedPayment[index].add(nowValue);
        }     
        return totalSharedPayment;
    }
    function _calculateTimePrice(uint256 preTime,uint256 createdTime,uint256 expiration,
            uint256 strikePrice,uint256 ivNumerator,uint256 ivDenominator,uint8 optType)internal view returns (uint256){
        uint256 preExpiration = preTime>createdTime ? expiration - preTime : expiration - createdTime;
        uint256 preValue = _optionsPrice.getOptionsPrice_iv(strikePrice,strikePrice,preExpiration,ivNumerator,
            ivDenominator,optType);
        uint256 nowValue = _optionsPrice.getOptionsPrice_iv(strikePrice,strikePrice,expiration-now,ivNumerator,
            ivDenominator,optType);
        return (preValue>nowValue)? preValue-nowValue : 0;
    }
    function calculatePhaseOptionsFall(uint256 calInfo,address[] memory whiteList) public view returns(int256[],uint256[]){
        uint256 begin = tuple64.getValue0(calInfo).mul(sharedPhase);
        uint256 end = begin.add(sharedPhase);
        if (begin>=tuple64.getValue1(calInfo) || end < optionPhaseInfo_Share[0]){
            return;
        }
        if (end>tuple64.getValue1(calInfo)) {
            end = tuple64.getValue1(calInfo);
        }
        if (begin <= optionPhaseInfo_Share[0]) {
            begin = optionPhaseInfo_Share[0];
        }
        uint256[] memory prices = getUnderlyingPrices();
        int256[] memory OptionsFallBalances = _calRangeOptionsFall(begin,end,tuple64.getValue0(calInfo),whiteList,prices);
        uint256 whiteListLen = whiteList.length;
        for (uint256 index = 0;index<whiteListLen;index++){
            OptionsFallBalances[index] = OptionsFallBalances[index]/(int256(_oracle.getPrice(whiteList[index])));
        }
        return (OptionsFallBalances,prices);
    }
    function _calRangeOptionsFall(uint256 begin,uint256 lastOption,uint256 index,address[] memory whiteList,uint256[] memory prices)
                 internal view returns(int256[] memory){
        uint256[] memory lastPrice = OptionsPhasePrices[index];
        int256[] memory OptionsFallBalances = new int256[](whiteList.length);

        for (;begin<lastOption;begin++){
            index = _getEligibleUnderlyingIndex(allOptions[begin].underlying);
            uint256 curValue = calOptionsCollateral(allOptions[begin],prices[index]);
            uint256 prePrice = begin < optionPhaseInfo_Share[1] ? lastPrice[index] : optionExtraMap[begin].optionPrice;
            uint256 preValue = calOptionsCollateral(allOptions[begin],prePrice);
            if (preValue != curValue){
                OptionsInfoEx storage optionEx = optionExtraMap[begin];
                index = whiteListAddress._getEligibleIndexAddress(whiteList,optionEx.settlement);
                OptionsFallBalances[index] += int256(curValue) - int256(preValue);
            }
        }
        return OptionsFallBalances;
    }
    function getTotalOccupiedCollateral() public view returns (uint256) {
        uint256 totalOccupied = sumOptionPhases();
        uint256[] memory prices = getUnderlyingPrices();
        uint optionsLen = allOptions.length;
        for (uint256 beginOption = optionPhaseInfo[1]; beginOption < optionsLen;beginOption++){
            uint256 index = _getEligibleUnderlyingIndex(allOptions[beginOption].underlying);
            totalOccupied = totalOccupied.add(calOptionsCollateral(allOptions[beginOption],prices[index]));
        }
        uint burnedLen = burnedLength;
        for (uint256 i = optionPhaseInfo[2];i<burnedLen;i++){
            uint256[2] memory burnInfo = burnedOptions[i];
            uint optionId = burnInfo[0];
            index = _getEligibleUnderlyingIndex(allOptions[optionId].underlying);
            totalOccupied = totalOccupied.sub(calBurnedOptionsCollateral(allOptions[optionId],
                burnInfo[1],prices[index]));
        }
        return totalOccupied;
    }
    function calBurnedOptionsCollateral(OptionsInfo memory option,uint256 burned,uint256 underlyingPrice)internal pure returns(uint256){
        uint256 totalOccupied = 0;
        if ((option.optType == 0) == (option.strikePrice>underlyingPrice)){ // call
            totalOccupied = option.strikePrice.mul(burned);
        } else {
            totalOccupied = underlyingPrice.mul(burned);
        }
        return totalOccupied;
    }
    function sumOptionPhases()internal view returns(uint256){
        uint256 totalOccupied = 0;
        uint256 i = optionPhaseInfo[0]/optionPhase;
        uint256 phaseLen = optionPhaseInfo[1]/optionPhase+1;
        for (;i<phaseLen;i++){
            totalOccupied = totalOccupied.add(OptionsPhases[i]);
        }
        return totalOccupied;
    }
    function calOptionsCollateral(OptionsInfo memory option,uint256 underlyingPrice)internal view returns(uint256){
        if (option.expiration<=now || option.amount == 0){
            return 0;
        }
        uint256 totalOccupied = 0;
        if ((option.optType == 0) == (option.strikePrice>underlyingPrice)){ // call
            totalOccupied = option.strikePrice.mul(option.amount);
        } else {
            totalOccupied = underlyingPrice.mul(option.amount);
        }
        return totalOccupied;
    }
    function burnOptions(address from,uint256 id,uint256 amount)public onlyManager{
        OptionsInfo memory info = _getOptionsById(id);
        checkEligible(info);
        checkOwner(info,from);
        checkSufficient(info,amount);
        info.amount = info.amount.sub(amount);
        burnedOptions[burnedLength] = [id-1,amount];
        burnedLength++;
        emit BurnOption(from,id,amount);
    }
}