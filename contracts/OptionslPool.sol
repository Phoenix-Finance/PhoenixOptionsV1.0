pragma solidity ^0.4.26;
import "./SafeMath.sol";
import "./TransactionFee.sol";
import "./CompoundOracleInterface.sol";
import "./underlyingAssets.sol";
contract OptionslPool is UnderlyingAssets,TransactionFee {
    using SafeMath for uint256;
    struct OptionsInfo {
        uint8   	optType;    //0 for call, 1 for put
        uint32		underlying;
        uint256		expiration;
        uint256     strikePrice;
        uint256     amount;
        uint256     volatility;
    }

    Number public collateralRate;
    //each block burn options
    mapping(uint256=>uint256[2][]) public burnBlockOptions;
    ICompoundOracle internal _oracle;
    uint256 private _calDecimal = 10000000000;

    OptionsInfo[] public allOptions;

    uint256 private firstPhase = 0;
    uint32 public optionPhase = 500;
    uint256 public lastCallOption;
    uint256 public lastCalBlock;

    uint256[] private OptionsPhases;

    function calculatePhaseOccupiedCollateral(uint256 index) public onlyOwner {
        uint256 beginOption = index.mul(optionPhase);
        if (beginOption>=allOptions.length){
            return;
        }
        if(OptionsPhases.length<index+1){
            OptionsPhases.length = index+1;
        }
        uint256 lastOption = beginOption.add(optionPhase);
        if (lastOption>allOptions.length) {
            lastOption = allOptions.length;
        }
        uint256[] memory prices = new uint256[](underlyingAssets.length);
        for (uint256 i = 0;i<underlyingAssets.length;i++){
            prices[i] = _oracle.getUnderlyingPrice(underlyingAssets[i]);
        }
        uint256 totalOccupied = 0;
        for (;beginOption<lastOption;beginOption++){
            index = _getEligibleUnderlyingIndex(allOptions[beginOption].underlying);
            totalOccupied = totalOccupied.add(calOptionsCollateral(allOptions[beginOption],prices[index]));
        }
        OptionsPhases[index] = totalOccupied;
        if (lastCallOption<lastOption-1) {
            lastCallOption = lastOption-1;
            lastCalBlock = block.number;
        }
    }
    function createOptions(uint8 optType,uint32 underlying,uint256 expiration,uint256 strikePrice,uint256 amount) internal {
        allOptions.push(OptionsInfo(optType,underlying,expiration,strikePrice,amount,0));
    }
    function getTotalOccupiedCollateral() public view returns (uint256) {
        uint256 totalOccupied = sumOptionPhases();
        uint256[] memory prices = new uint256[](underlyingAssets.length);
        for (uint256 i = 0;i<underlyingAssets.length;i++){
            prices[i] = _oracle.getUnderlyingPrice(underlyingAssets[i]);
        }
        for (uint256 beginOption = lastCallOption+1; beginOption < allOptions.length;beginOption++){
            uint256 index = _getEligibleUnderlyingIndex(allOptions[beginOption].underlying);
            totalOccupied = totalOccupied.add(calOptionsCollateral(allOptions[beginOption],prices[index]));
        }
        for (uint256 beginBlock = lastCalBlock+1; beginBlock <= block.number;beginBlock++){
            uint256[2][] storage burnedTokens = burnBlockOptions[beginBlock];
            for (i = 0;i<burnedTokens.length;i++){
                index = _getEligibleUnderlyingIndex(allOptions[burnedTokens[i][0]].underlying);
                totalOccupied = totalOccupied.sub(calBurnedOptionsCollateral(allOptions[burnedTokens[i][0]],
                    burnedTokens[i][1],prices[index]));
            }
        }
        return totalOccupied;
    }
    function sumOptionPhases()internal view returns(uint256){
        uint256 totalOccupied = 0;
        for (uint256 i=0;i<OptionsPhases.length;i++){
            totalOccupied = totalOccupied.add(OptionsPhases[i]);
        }
        return totalOccupied;
    }
    function calOptionsCollateral(OptionsInfo storage option,uint256 underlyingPrice)internal view returns(uint256){
        uint256 totalOccupied = 0;
        if ((option.optType == 0) == (option.strikePrice>underlyingPrice)){ // call
            totalOccupied = option.strikePrice.mul(option.amount);
        } else {
            totalOccupied = underlyingPrice.mul(option.amount);
        }
        return _calNumberMulUint(collateralRate,totalOccupied);
    }
    function calBurnedOptionsCollateral(OptionsInfo storage option,uint256 burned,uint256 underlyingPrice)internal view returns(uint256){
        uint256 totalOccupied = 0;
        if ((option.optType == 0) == (option.strikePrice>underlyingPrice)){ // call
            totalOccupied = option.strikePrice.mul(burned);
        } else {
            totalOccupied = underlyingPrice.mul(burned);
        }
        return _calNumberMulUint(collateralRate,totalOccupied);
    }
    function burnOptions(uint256 optionIndex,uint256 amount)internal{
        require (optionIndex<allOptions.length,"option index is out of range!");
        allOptions[optionIndex].amount = allOptions[optionIndex].amount.sub(amount);
        burnBlockOptions[block.number].push([optionIndex,amount]);
    }
}