pragma solidity =0.5.16;
import "./OptionsData.sol";
import "../PhoenixModules/modules/whiteListUint32.sol";
/**
 * @title Options collateral occupied calculation contract for finnexus proposal v2.
 * @dev A Smart-contract for collateral occupied calculation.
 *
 */
import "../PhoenixModules/modules/whiteListAddress.sol";
contract OptionsOccupiedCal is OptionsData {
    using whiteListUint32 for uint32[];
    using whiteListAddress for address[];
    /**
     * @dev retrieve collateral occupied calculation information.
     */    
    function getOccupiedCalInfo()public view returns(uint256,int256[] memory,int256[] memory){
        uint256 underlyingLen = underlyingAssets.length;
        int256[] memory callLatestOccupied = new int256[](underlyingLen);
        int256[] memory putLatestOccupied = new int256[](underlyingLen);
        for (uint256 i=0;i<underlyingLen;i++){
            uint32 underlying = underlyingAssets[i];
            callLatestOccupied[i] = underlyingOccupiedMap[underlying].callLatestOccupied;
            putLatestOccupied[i] = underlyingOccupiedMap[underlying].putLatestOccupied;
        }
        return (occupiedFirstOption,callLatestOccupied,putLatestOccupied);
    }
    /**
     * @dev calculate collateral occupied value, and modify database, only foundation operator can modify database.
     */  
    function setOccupiedCollateral() public onlyOperator(1) {
        (,int256[] memory latestCallOccupied,int256[] memory latestPutOccupied) = getOccupiedCalInfo();
        uint256 lastOption = allOptions.length;
        (uint256[] memory totalCallOccupied,uint256[] memory totalPutOccupied,uint256 beginOption,bool success) = calculatePhaseOccupiedCollateral(lastOption, occupiedFirstOption,lastOption);
        if (success){
            setCollateralPhase(totalCallOccupied,totalPutOccupied,beginOption,latestCallOccupied,latestPutOccupied);
        }
    }
    /**
     * @dev calculate collateral occupied value.
     * @param lastOption last option's position.
     * @param beginOption begin option's poisiton.
     * @param endOption end option's poisiton.
     */  
    function calculatePhaseOccupiedCollateral(uint256 lastOption,uint256 beginOption,uint256 endOption) public view returns(uint256[] memory,uint256[] memory,uint256,bool){
        if (beginOption <  occupiedFirstOption){
            beginOption =  occupiedFirstOption;
        }
        if (beginOption>=lastOption){
            return (new uint256[](0),new uint256[](0),0,false);
        }
        if (endOption>lastOption) {
            endOption = lastOption;
        }else if(endOption <  occupiedFirstOption){
            return (new uint256[](0),new uint256[](0),0,false);
        }
        (uint256[] memory totalCallOccupied,uint256[] memory totalPutOccupied,uint256 newFirstOption) = _calculateOccupiedCollateral(beginOption,endOption);
        return (totalCallOccupied,totalPutOccupied,newFirstOption,true);
    }
    /**
     * @dev subfunction, calculate collateral occupied value.
     * @param begin begin option's poisiton.
     * @param end end option's poisiton.
     */  
    function _calculateOccupiedCollateral(uint256 begin,uint256 end)internal view returns(uint256[] memory,uint256[] memory,uint256){
        uint256 newFirstOption;
        (begin,newFirstOption) = getFirstOption(begin, occupiedFirstOption,end);
        uint256 underlyingLen = underlyingAssets.length;
        uint256[] memory underlyingCallOccupied = new uint256[](underlyingLen);
        uint256[] memory underlyingPutOccupied = new uint256[](underlyingLen);
        uint256[] memory prices = getUnderlyingPrices();
        for (;begin<end;begin++){
            OptionsInfo memory info = allOptions[begin];
            uint256 index = underlyingAssets._getEligibleIndexUint32(info.underlying);
            uint256 value = calOptionsCollateral(info,prices[index]);
            if (info.optType == 0){
                underlyingCallOccupied[index] += value;
            }else{
                underlyingPutOccupied[index] += value;
            }
        }
        return (underlyingCallOccupied,underlyingPutOccupied,newFirstOption);
    }
    /**
     * @dev set collateral occupied value, only foundation operator can modify database.
     * @param totalCallOccupied new call options occupied collateral calculation result.
     * @param totalPutOccupied new put options occupied collateral calculation result.
     * @param beginOption new first valid option's positon.
     * @param latestCallOccpied latest call options' occupied value when operater invoke collateral occupied calculation.
     * @param latestPutOccpied latest put options' occupied value when operater invoke collateral occupied calculation.
     */  
    function setCollateralPhase(uint256[] memory totalCallOccupied,uint256[] memory totalPutOccupied,uint256 beginOption,
            int256[] memory latestCallOccpied,int256[] memory latestPutOccpied) public onlyOperator(1){
        require(beginOption <= allOptions.length, "beginOption calculate Error");
        if (beginOption >  occupiedFirstOption){
             occupiedFirstOption = beginOption;
        }
        uint256 underlyingLen = underlyingAssets.length;
        underlyingTotalOccupied = 0;
        for (uint256 i=0;i<underlyingLen;i++){
            uint32 underlying = underlyingAssets[i];
            underlyingOccupiedMap[underlying].callOccupied = totalCallOccupied[i];
            underlyingOccupiedMap[underlying].putOccupied = totalPutOccupied[i];
            underlyingOccupiedMap[underlying].callLatestOccupied -= latestCallOccpied[i];
            underlyingOccupiedMap[underlying].putLatestOccupied -= latestPutOccpied[i];
            underlyingTotalOccupied += getUnderlyingOccupiedCollateral(underlyingOccupiedMap[underlying].callOccupied,
                underlyingOccupiedMap[underlying].callLatestOccupied);
            underlyingTotalOccupied += getUnderlyingOccupiedCollateral(underlyingOccupiedMap[underlying].putOccupied,
                underlyingOccupiedMap[underlying].putLatestOccupied);
        }
    }
    /**
     * @dev get real total collateral occupied value.
     */ 
    function getUnderlyingTotalOccupiedCollateral(uint32 underlying) public view returns (uint256,uint256,uint256) {
        return (getUnderlyingOccupiedCollateral(underlyingOccupiedMap[underlying].callOccupied,
                underlyingOccupiedMap[underlying].callLatestOccupied),
                getUnderlyingOccupiedCollateral(underlyingOccupiedMap[underlying].putOccupied,
                underlyingOccupiedMap[underlying].putLatestOccupied),underlyingTotalOccupied);
    }
    /**
     * @dev get call options total collateral occupied value.
     */ 
    function getUnderlyingOccupiedCollateral(uint256 optionOccupied,int256 optionLatestOccupied) internal pure returns (uint256) {
        if (optionLatestOccupied>=0){
            uint256 result = optionOccupied+uint256(optionLatestOccupied);
            require(result>=optionOccupied,"TotalOccupiedCollateral calculate overflow");
            return result;
        }else{
            uint256 latestOccupied = uint256(-optionLatestOccupied);
            if (optionOccupied>latestOccupied){
                return optionOccupied - latestOccupied;
            }else{
                return 0;
            }
        }
    }

//     /**
//      * @dev add new option collateral occupied value when user create a new option.
//      * @param optionID new option's ID.
//      */ 
//     function _addOptionsCollateral(uint256 optionID) internal {
//         OptionsInfo memory info = allOptions[optionID-1];
// //        OptionsInfoEx storage infoEx =  optionExtraMap[optionID-1];
//         uint256 newOccupied = calOptionsCollateral(info,(info.strikePrice*info.priceRate)>>28);
//         if (info.optType == 0){
//             callLatestOccupied += int256(newOccupied);
//         }else{
//             putLatestOccupied += int256(newOccupied);
//         }
//     }

        /**
     * @dev An auxiliary function, retrieve first available option's positon.
     * @param begin  the start of option's positon
     * @param latestBegin  the latest begin option positon.
     * @param end  the end of option's positon
     */
    function getFirstOption(uint256 begin,uint256 latestBegin,uint256 end) internal view returns(uint256,uint256){
        uint256 newFirstOption = latestBegin;
        if (begin > newFirstOption){
            //if in other phase, begin != new begin
            return (begin,newFirstOption);
        }
        begin = newFirstOption;
        for (;begin<end;begin++){
            OptionsInfo storage info = allOptions[begin];
            if(info.createTime+info.expiration<now || info.amount == 0){
                continue;
            }
            break;
        }
        //if in first phase, begin = new begin
        return (begin,begin);
    }
        /**
     * @dev calculate option's occupied collateral.
     * @param option  option's information
     * @param underlyingPrice  underlying current price.
     */
    function calOptionsCollateral(OptionsInfo memory option,uint256 underlyingPrice)internal view returns(uint256){
        uint256 amount = option.amount;
        if (option.createTime+option.expiration<=now || amount == 0){
            return 0;
        }
        uint256 totalOccupied = _getOptionsWorth(option.optType,option.strikePrice,underlyingPrice,amount);
        require(totalOccupied<=1e40,"Option collateral occupied calculate error");
        return totalOccupied;
    }
    /**
     * @dev calculate one option's occupied collateral.
     * @param optType  option's type, 0 for CALL, 1 for PUT.
     * @param strikePrice  option's strikePrice
     * @param underlyingPrice  underlying current price.
     */
    function _getOptionsWorth(uint8 optType,uint256 strikePrice,uint256 underlyingPrice,uint256 amount)internal pure returns(uint256){
        if ((optType == 0) == (strikePrice>underlyingPrice)){ // call
            return strikePrice*amount;
        } else {
            return underlyingPrice*amount;
        }
    }
        /**
     * @dev An auxiliary function, get underlying prices. 
     */
    function getUnderlyingPrices()internal view returns(uint256[] memory){
        uint256 underlyingLen = underlyingAssets.length;
        uint256[] memory prices = new uint256[](underlyingLen);
        for (uint256 i = 0;i<underlyingLen;i++){
            prices[i] = oracleUnderlyingPrice(underlyingAssets[i]);
        }
        return prices;
    }
}