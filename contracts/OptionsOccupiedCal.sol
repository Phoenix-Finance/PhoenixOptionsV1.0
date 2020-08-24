pragma solidity ^0.4.26;
import "./OptionsBase.sol";
import "./modules/Operator.sol";
import "./OptionsBase.sol";
import "./modules/SafeInt256.sol";
/**
 * @title Options collateral occupied calculation contract for finnexus proposal v2.
 * @dev A Smart-contract for collateral occupied calculation.
 *
 */
contract OptionsOccupiedCal is OptionsBase,Operator {

    // first option position which is needed calculate.
    uint256 private firstOption; 
    //latest calcutated Options Occupied value.
    uint256 private optionsOccupied;
    //latest Options volatile occupied value when bought or selled options.
    int256 private optionsLatestOccupied;
    using SafeInt256 for int256;
    /**
     * @dev retrieve collateral occupied calculation information.
     */    
    function getOccupiedCalInfo()public view returns(uint256,int256){
        return (firstOption,optionsLatestOccupied);
    }
    /**
     * @dev calculate collateral occupied value, and modify database, only foundation operator can modify database.
     */  
    function setOccupiedCollateral() public onlyOperatorIndex(0) {
        int256 latestOccupied = optionsLatestOccupied;
        uint256 lastOption = allOptions.length;
        (uint256 totalOccupied,uint256 beginOption,bool success) = calculatePhaseOccupiedCollateral(lastOption,firstOption,lastOption);
        if (success){
            setCollateralPhase(totalOccupied,beginOption,latestOccupied);
        }
    }
    /**
     * @dev calculate collateral occupied value.
     * @param lastOption last option's position.
     * @param beginOption begin option's poisiton.
     * @param endOption end option's poisiton.
     */  
    function calculatePhaseOccupiedCollateral(uint256 lastOption,uint256 beginOption,uint256 endOption) public view returns(uint256,uint256,bool){
        if (beginOption < firstOption){
            beginOption = firstOption;
        }
        if (beginOption>=lastOption){
            return (0,0,false);
        }
        if (endOption>lastOption) {
            endOption = lastOption;
        }else if(endOption < firstOption){
            return (0,0,false);
        }
        (uint256 totalOccupied,uint256 newFirstOption) = _calculateOccupiedCollateral(beginOption,endOption);
        return (totalOccupied,newFirstOption,true);
    }
    /**
     * @dev subfunction, calculate collateral occupied value.
     * @param begin begin option's poisiton.
     * @param end end option's poisiton.
     */  
    function _calculateOccupiedCollateral(uint256 begin,uint256 end)internal view returns(uint256,uint256){
        uint256 newFirstOption;
        (begin,newFirstOption) = getFirstOption(begin,firstOption,end);
        uint256[] memory prices = getUnderlyingPrices();
        uint256 totalOccupied = 0;
        for (;begin<end;begin++){
            uint256 index = _getEligibleUnderlyingIndex(allOptions[begin].underlying);
            uint256 value = calOptionsCollateral(allOptions[begin],prices[index]);
            totalOccupied = totalOccupied+value;
        }
        return (totalOccupied,newFirstOption);
    }
    /**
     * @dev set collateral occupied value, only foundation operator can modify database.
     * @param totalOccupied new collateral calculation result.
     * @param beginOption new first valid option's positon.
     * @param latestOccpied latest occupied value when operater invoke collateral occupied calculation.
     */  
    function setCollateralPhase(uint256 totalOccupied,uint256 beginOption,int256 latestOccpied) public onlyOperatorIndex(0){
        if (beginOption > firstOption){
            firstOption = beginOption;
        }
        optionsOccupied = totalOccupied;
        optionsLatestOccupied -= latestOccpied;
    }
    /**
     * @dev get real total collateral occupied value.
     */ 
    function getTotalOccupiedCollateral() public view returns (uint256) {
        if (optionsLatestOccupied>=0){
            return optionsOccupied.add(uint256(optionsLatestOccupied));
        }else{
            uint256 latestOccupied = uint256(-optionsLatestOccupied);
            if (optionsOccupied>latestOccupied){
                return optionsOccupied - latestOccupied;
            }else{
                return 0;
            }
        }
    }
    /**
     * @dev add new option collateral occupied value when user create a new option.
     * @param info new option's information.
     */ 
    function _addOptionsCollateral(OptionsInfo memory info) internal {
        OptionsInfoEx storage infoEx =  optionExtraMap[info.optionID-1];
        uint256 newOccupied = calOptionsCollateral(info,infoEx.underlyingPrice);
        optionsLatestOccupied = optionsLatestOccupied.add(int256(newOccupied));
    }
    /**
     * @dev deduct burned option collateral occupied value when user burn option.
     * @param info burned option's information.
     * @param amount burned option's amount.
     * @param underlyingPrice current underlying price.
     */ 
    function _burnOptionsCollateral(OptionsInfo memory info,uint256 amount,uint256 underlyingPrice) internal {
        uint256 newOccupied = _getOptionsWorth(info.optType,info.strikePrice,underlyingPrice).mul(amount);
        optionsLatestOccupied = optionsLatestOccupied.sub(int256(newOccupied));
    }

}