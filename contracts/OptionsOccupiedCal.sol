pragma solidity ^0.4.26;
import "./OptionsBase.sol";
import "./modules/tuple.sol";
import "./modules/Operator.sol";
import "./OptionsBase.sol";
import "./modules/SafeInt256.sol";
contract OptionsOccupiedCal is OptionsBase,Operator {

    //calculate options Collateral occupied phases
    uint256 private firstOption; 
    uint256 private optionsOccupied;
    int256 private optionsLatestOccupied;
    using SafeInt256 for int256;
    //each block burn options
    //index,lastOption,lastBurned
    function getOccupiedCalInfo()public view returns(uint256,int256){
        return (firstOption,optionsLatestOccupied);
    }
    function setOccupiedCollateral() public onlyOperatorIndex(0) {
        int256 latestOccupied = optionsLatestOccupied;
        uint256 lastOption = allOptions.length;
        (uint256 totalOccupied,uint256 beginOption,bool success) = calculatePhaseOccupiedCollateral(lastOption,firstOption,lastOption);
        if (success){
            setCollateralPhase(totalOccupied,beginOption,latestOccupied);
        }
    }
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
    function _calculateOccupiedCollateral(uint256 begin,uint256 end)internal view returns(uint256,uint256){
        uint256 newFirstOption;
        (begin,newFirstOption) = getFirstOption(begin,firstOption,end);
        uint256[] memory prices = getUnderlyingPrices();
        uint256 totalOccupied = 0;
        for (;begin<end;begin++){
            uint256 index = _getEligibleUnderlyingIndex(allOptions[begin].underlying);
            uint256 value = calOptionsCollateral(allOptions[begin],prices[index]);
            totalOccupied = totalOccupied.add(value);
        }
        return (totalOccupied,newFirstOption);
    }
    function setCollateralPhase(uint256 totalOccupied,uint256 beginOption,int256 latestOccpied) public onlyOperatorIndex(0){
        if (beginOption > firstOption){
            firstOption = beginOption;
        }
        optionsOccupied = totalOccupied;
        optionsLatestOccupied -= latestOccpied;
    }
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
    function _addOptionsCollateral(OptionsInfo memory info) internal {
        OptionsInfoEx storage infoEx =  optionExtraMap[info.optionID-1];
        uint256 newOccupied = calOptionsCollateral(info,infoEx.underlyingPrice);
        optionsLatestOccupied = optionsLatestOccupied.add(int256(newOccupied));
    }
    function _burnOptionsCollateral(OptionsInfo memory info,uint256 amount,uint256 underlyingPrice) internal {
        uint256 newOccupied = _getOptionsWorth(info.optType,info.strikePrice,underlyingPrice).mul(amount);
        optionsLatestOccupied = optionsLatestOccupied.sub(int256(newOccupied));
    }

}