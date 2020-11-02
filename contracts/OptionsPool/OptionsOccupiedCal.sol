pragma solidity =0.5.16;
import "./Optionsbase.sol";
/**
 * @title Options collateral occupied calculation contract for finnexus proposal v2.
 * @dev A Smart-contract for collateral occupied calculation.
 *
 */
contract OptionsOccupiedCal is OptionsBase {

    /**
     * @dev retrieve collateral occupied calculation information.
     */    
    function getOccupiedCalInfo()public view returns(uint256,int256,int256){
        return (occupiedFirstOption,callLatestOccupied,putLatestOccupied);
    }
    /**
     * @dev calculate collateral occupied value, and modify database, only foundation operator can modify database.
     */  
    function setOccupiedCollateral() public onlyOperatorIndex(1) {
        int256 latestCallOccupied = callLatestOccupied;
        int256 latestPutOccupied = putLatestOccupied;
        uint256 lastOption = allOptions.length;
        (uint256 totalCallOccupied,uint256 totalPutOccupied,uint256 beginOption,bool success) = calculatePhaseOccupiedCollateral(lastOption, occupiedFirstOption,lastOption);
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
    function calculatePhaseOccupiedCollateral(uint256 lastOption,uint256 beginOption,uint256 endOption) public view returns(uint256,uint256,uint256,bool){
        if (beginOption <  occupiedFirstOption){
            beginOption =  occupiedFirstOption;
        }
        if (beginOption>=lastOption){
            return (0,0,0,false);
        }
        if (endOption>lastOption) {
            endOption = lastOption;
        }else if(endOption <  occupiedFirstOption){
            return (0,0,0,false);
        }
        (uint256 totalCallOccupied,uint256 totalPutOccupied,uint256 newFirstOption) = _calculateOccupiedCollateral(beginOption,endOption);
        return (totalCallOccupied,totalPutOccupied,newFirstOption,true);
    }
    /**
     * @dev subfunction, calculate collateral occupied value.
     * @param begin begin option's poisiton.
     * @param end end option's poisiton.
     */  
    function _calculateOccupiedCollateral(uint256 begin,uint256 end)internal view returns(uint256,uint256,uint256){
        uint256 newFirstOption;
        (begin,newFirstOption) = getFirstOption(begin, occupiedFirstOption,end);
        uint256[] memory prices = getUnderlyingPrices();
        uint256 totalCallOccupied = 0;
        uint256 totalPutOccupied = 0;
        for (;begin<end;begin++){
            uint256 index = _getEligibleUnderlyingIndex(allOptions[begin].underlying);
            uint256 value = calOptionsCollateral(allOptions[begin],prices[index]);
            if (allOptions[begin].optType == 0){
                totalCallOccupied += value;
            }else{
                totalPutOccupied += value;
            }
        }
        return (totalCallOccupied,totalPutOccupied,newFirstOption);
    }
    /**
     * @dev set collateral occupied value, only foundation operator can modify database.
     * @param totalCallOccupied new call options occupied collateral calculation result.
     * @param totalPutOccupied new put options occupied collateral calculation result.
     * @param beginOption new first valid option's positon.
     * @param latestCallOccpied latest call options' occupied value when operater invoke collateral occupied calculation.
     * @param latestPutOccpied latest put options' occupied value when operater invoke collateral occupied calculation.
     */  
    function setCollateralPhase(uint256 totalCallOccupied,uint256 totalPutOccupied,uint256 beginOption,
            int256 latestCallOccpied,int256 latestPutOccpied) public onlyOperatorIndex(1){
        require(beginOption <= allOptions.length, "beginOption calculate Error");
        if (beginOption >  occupiedFirstOption){
             occupiedFirstOption = beginOption;
        }
        callOccupied = totalCallOccupied;
        putOccupied = totalPutOccupied;
        require(latestCallOccpied>=-1e40 && latestCallOccpied<=1e40,"options fall calculate error");
        require(latestPutOccpied>=-1e40 && latestPutOccpied<=1e40,"options fall calculate error");
        callLatestOccupied -= latestCallOccpied;
        putLatestOccupied -= latestPutOccpied;
    }
    /**
     * @dev get real total collateral occupied value.
     */ 
    function getAllTotalOccupiedCollateral() public view returns (uint256,uint256) {
        return (getCallTotalOccupiedCollateral(),getPutTotalOccupiedCollateral());
    }
    /**
     * @dev get call options total collateral occupied value.
     */ 
    function getCallTotalOccupiedCollateral() public view returns (uint256) {
        if (callLatestOccupied>=0){
            uint256 result = callOccupied+uint256(callLatestOccupied);
            require(result>=callOccupied,"TotalOccupiedCollateral calculate overflow");
            return result;
        }else{
            uint256 latestOccupied = uint256(-callLatestOccupied);
            if (callOccupied>latestOccupied){
                return callOccupied - latestOccupied;
            }else{
                return 0;
            }
        }
    }
        /**
     * @dev get put options total collateral occupied value.
     */ 
    function getPutTotalOccupiedCollateral() public view returns (uint256) {
        if (putLatestOccupied>=0){
            uint256 result = putOccupied+uint256(putLatestOccupied);
            require(result>=putOccupied,"TotalOccupiedCollateral calculate overflow");
            return result;
        }else{
            uint256 latestOccupied = uint256(-putLatestOccupied);
            if (putOccupied>latestOccupied){
                return putOccupied - latestOccupied;
            }else{
                return 0;
            }
        }
    }
    /**
     * @dev get real total collateral occupied value.
     */ 
    function getTotalOccupiedCollateral() public view returns (uint256) {
        return getCallTotalOccupiedCollateral() + getPutTotalOccupiedCollateral();
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
     * @dev deduct burned option collateral occupied value when user burn option.
     * @param info burned option's information.
     * @param amount burned option's amount.
     * @param underlyingPrice current underlying price.
     */ 
    function _burnOptionsCollateral(OptionsInfo memory info,uint256 amount,uint256 underlyingPrice) internal {
        uint256 newOccupied = _getOptionsWorth(info.optType,info.strikePrice,underlyingPrice)*amount;
        require(newOccupied<=1e40,"Option collateral occupied calculate error");
        if (info.optType == 0){
            callLatestOccupied -= int256(newOccupied);
        }else{
            putLatestOccupied -= int256(newOccupied);
        }
    }

}