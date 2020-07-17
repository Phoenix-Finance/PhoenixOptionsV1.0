pragma solidity ^0.4.26;
import "./SafeMath.sol";
import "./TransactionFee.sol";
import "./CompoundOracleInterface.sol";
import "./underlyingAssets.sol";
contract OptionsPool is UnderlyingAssets,TransactionFee {
    using SafeMath for uint256;
    struct OptionsInfo {
        uint256     optionID;
        address     owner;
        uint8   	optType;    //0 for call, 1 for put
        uint32		underlying;
        uint256		expiration;
        uint256     strikePrice;
        uint256     amount;
        int256     ivNumerator;
        int256     ivDenominator;
    }

    //each block burn options
    mapping(uint256=>uint256[2][]) public burnBlockOptions;
    mapping(address=>uint256[]) public optionsBalances;
    ICompoundOracle internal _oracle;
    uint256 private _calDecimal = 10000000000;

    OptionsInfo[] public allOptions;

    uint256 private firstPhase = 0;
    uint32 public optionPhase = 500;
    uint256 public lastCallOption;
    uint256 public lastCalBlock;

    uint256[] private OptionsPhases;
    function getOracleAddress() public view returns(address){
        return address(_oracle);
    }
    function setOracleAddress(address oracle)public onlyOwner{
        _oracle = ICompoundOracle(oracle);
    }
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
    function createOptions(uint8 optType,uint32 underlying,uint256 expiration,uint256 strikePrice,
        uint256 amount,int256 ivNumerator,int256 ivDenominator) internal {
        uint256 optionID = allOptions.length;
        allOptions.push(OptionsInfo(optionID,msg.sender,optType,underlying,expiration,strikePrice,amount,ivNumerator,ivDenominator));
        optionsBalances[msg.sender].push(optionID);
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
        return totalOccupied;
    }
    function calBurnedOptionsCollateral(OptionsInfo storage option,uint256 burned,uint256 underlyingPrice)internal view returns(uint256){
        uint256 totalOccupied = 0;
        if ((option.optType == 0) == (option.strikePrice>underlyingPrice)){ // call
            totalOccupied = option.strikePrice.mul(burned);
        } else {
            totalOccupied = underlyingPrice.mul(burned);
        }
        return totalOccupied;
    }
    function burnOptions(uint256 id,uint256 amount)internal{
        OptionsInfo storage info = getOptionsById(id);
        checkEligible(info);
        checkOwner(info,msg.sender);
        checkSufficient(info,amount);
        info.amount = info.amount.sub(amount);
        burnBlockOptions[block.number].push([id-1,amount]);
    }
    function getExerciseWorth(uint256 optionsId,uint256 amount)public view returns(uint256){
        OptionsInfo storage info = getOptionsById(optionsId);
        checkEligible(info);
        checkSufficient(info,amount);
        uint256 underlyingPrice = _oracle.getUnderlyingPrice(info.underlying);
        uint256 tokenPayback = 0;
        if (info.optType == 0){
            if (underlyingPrice > info.strikePrice){
                tokenPayback -= info.strikePrice;
            }
        }else{
            if ( underlyingPrice < info.strikePrice){
                tokenPayback = info.strikePrice-underlyingPrice;
            }
        }
        if (tokenPayback == 0 ){
            return 0;
        } 
        return tokenPayback.mul(amount);
    }
    function getOptionsById(uint256 id)internal view returns(OptionsInfo storage){
        require(id>0 && id <= allOptions.length,"option id is not exist");
        return allOptions[id];
    }
    function checkEligible(OptionsInfo storage info)internal view{
        require(info.expiration>now,"option is expired");
    }
    function checkOwner(OptionsInfo storage info,address owner)internal view{
        require(info.owner == owner,"caller is not the options owner");
    }
    function checkSufficient(OptionsInfo storage info,uint256 amount) internal view{
        require(info.amount >= amount,"option amount is insufficient");
    }

}