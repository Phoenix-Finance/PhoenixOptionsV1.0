pragma solidity ^0.4.26;
import "./modules/SafeMath.sol";
import "./modules/Managerable.sol";
import "./interfaces/ICompoundOracle.sol";
import "./modules/underlyingAssets.sol";
import "./interfaces/IOptionsPrice.sol";
import "./interfaces/IVolatility.sol";
contract OptionsPool is UnderlyingAssets,Managerable,ImportOracle,ImportOptionsPrice,ImportVolatility {
    
    using SafeMath for uint256;
    struct OptionsInfo {
        uint256     optionID;
        address     owner;
        uint8   	optType;    //0 for call, 1 for put
        uint32		underlying;
        uint256		expiration;
        uint256     strikePrice;
        uint256     amount;
    }
    struct OptionsInfoEx{
        uint256		createdTime;
        address     settlement;
        uint256     tokenTimePrice;
        uint256     fullPrice;
        uint256      ivNumerator;
        uint256      ivDenominator;
    }

    //each block burn options
    mapping(uint256=>uint256[2][]) public burnBlockOptions;
    mapping(address=>uint256[]) public optionsBalances;
    uint256 constant _calDecimal = 10000000000;
    uint32 public optionPhase = 500;

    OptionsInfo[] public allOptions;
    mapping(uint256=>OptionsInfoEx) optionExtraMap;


    uint256 private firstOption = 0;
    uint256 public lastCallOption;
    uint256 public lastCalBlock;

    mapping(uint256=>uint256) private OptionsPhases;

    mapping (uint256 =>mapping (address => uint256)) private OptionsPhaseBalances;
    mapping (uint256 =>uint256) private OptionsPhaseTimes;
    uint256 public lastCalBlock_share;
    uint32 public sharedPhase = 500;

    uint256[] public expirationList;
    
    constructor () public{
    }
    function getOptionBalances(address user)public view returns(uint256[]){
        return optionsBalances[user];
    }
    function getOptionInfoList(uint256 from,uint256 size)public view 
                returns(address[],uint256[],uint256[],uint256[],uint256[]){
        if (from+size>allOptions.length){
            size = allOptions.length.sub(from);
        }
        if (size>0){
            address[] memory ownerArr = new address[](size);
            uint256[] memory typeAndUnderArr = new uint256[](size);
            uint256[] memory expArr = new uint256[](size);
            uint256[] memory priceArr = new uint256[](size);
            uint256[] memory amountArr = new uint256[](size);
            for (uint i=0;i<size;i++){
                OptionsInfo storage info = allOptions[from+i];
                ownerArr[i] = info.owner;
                typeAndUnderArr[i] = info.underlying << 16 + info.optType;
                expArr[i] = info.expiration;
                priceArr[i] = info.strikePrice;
                amountArr[i] = info.amount;
            }
            return (ownerArr,typeAndUnderArr,expArr,priceArr,amountArr);
        }
    }
    function getOptionInfoListFromID(uint256[] ids)public view 
                returns(address[],uint256[],uint256[],uint256[],uint256[]){
        uint256 size = ids.length;
        address[] memory ownerArr = new address[](size);
        uint256[] memory typeAndUnderArr = new uint256[](size);
        uint256[] memory expArr = new uint256[](size);
        uint256[] memory priceArr = new uint256[](size);
        uint256[] memory amountArr = new uint256[](size);
        for (uint i=0;i<size;i++){
            OptionsInfo storage info = allOptions[ids[i]-1];
            ownerArr[i] = info.owner;
            typeAndUnderArr[i] = info.underlying << 16 + info.optType;
            expArr[i] = info.expiration;
            priceArr[i] = info.strikePrice;
            amountArr[i] = info.amount;
        }
        return (ownerArr,typeAndUnderArr,expArr,priceArr,amountArr);
    }
    function getOptionsById(uint256 optionsId)public view returns(uint256,address,uint8,uint32,uint256,uint256,uint256){
        OptionsInfo storage info = _getOptionsById(optionsId);
        return (info.optionID,info.owner,info.optType,info.underlying,info.expiration,info.strikePrice,info.amount);
    }

    function setPhaseOccupiedCollateral(uint256 index) public onlyOwner {
        (uint256 totalOccupied,uint256 beginOption,uint256 lastOption) = calculatePhaseOccupiedCollateral(index);
        setCollateralPhase(index,totalOccupied,beginOption,lastOption,block.number);
    }
    function setCollateralPhase(uint256 index,uint256 totalOccupied,uint256 beginOption,uint256 lastOption,uint256 lastBlock) public onlyOwner{
        if (beginOption > firstOption){
            firstOption = beginOption;
        }
        if(lastCallOption < lastOption){
            lastCallOption = lastOption;
            lastCalBlock = lastBlock;
        }
        OptionsPhases[index] = totalOccupied;
    }
    function calculatePhaseOccupiedCollateral(uint256 index) public view returns(uint256,uint256,uint256){
        uint256 beginOption = index.mul(optionPhase);
        uint256 allLen = allOptions.length;
        if (beginOption>=allLen){
            return;
        }
        uint256 lastOption = beginOption.add(optionPhase);
        if (lastOption>allLen) {
            lastOption = allLen;
        }else if(lastOption < firstOption){
            return;
        }
        (uint256 totalOccupied,uint256 newFirstOption) = _calculateOccupiedCollateral(beginOption,lastOption);
        uint256 last = lastCallOption<lastOption-1 ? lastOption-1 : lastCallOption;
        return (totalOccupied,newFirstOption,last);
    }
    function _calculateOccupiedCollateral(uint256 begin,uint256 end)public view returns(uint256,uint256){
        bool bfirstPhase = begin <= firstOption;
        if (bfirstPhase) {
            begin = firstOption;
        }
        uint256 newFirstOption = firstOption;
        uint256 underlyingLen = underlyingAssets.length;
        uint256[] memory prices = new uint256[](underlyingLen);
        for (uint256 i = 0;i<underlyingLen;i++){
            prices[i] = _oracle.getUnderlyingPrice(underlyingAssets[i]);
        }
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
        return (totalOccupied,newFirstOption);
    }
    function setSharedState(uint256 index,uint256 lastBlock,uint256 calTime) public onlyManager{
        if(lastBlock < lastCalBlock_share){
            lastCalBlock_share = lastBlock;
        }
        OptionsPhaseTimes[index] = calTime;
    }
    function calculatePhaseSharedPayment(uint256 index,address[] whiteList) public view returns(uint256[],uint256){
        uint256 beginOption = index.mul(sharedPhase);
        uint256 allLen = allOptions.length;
        if (beginOption>=allLen){
            return;
        }
        uint256 lastOption = beginOption.add(sharedPhase);
        if (lastOption>allLen) {
            lastOption = allLen;
        }else if(lastOption < firstOption){
            return;
        }
        uint256[] memory sharedBalances = _calculateSharedPayment(beginOption,lastOption,OptionsPhaseTimes[index],whiteList);
        return (sharedBalances,block.number);
    }
    function _calculateSharedPayment(uint256 begin,uint256 end,uint256 preTime,address[] whiteList)public view returns(uint256[]){
        if (begin <= firstOption) {
            begin = firstOption;
        }
        uint256[] memory totalSharedPayment = new uint256[](whiteList.length);
        for (;begin<end;begin++){
            OptionsInfo storage info = allOptions[begin];
            uint256 expiration = info.expiration;
            if(expiration<preTime || info.amount == 0){
                continue;
            }
            OptionsInfoEx storage optionEx = optionExtraMap[begin];
            (uint256 preValue,uint256 nowValue) = _calculateTimePrice(preTime,optionEx.createdTime,expiration,info.strikePrice,
                    optionEx.ivNumerator,optionEx.ivDenominator,info.optType);
            if (preValue > nowValue){
                uint256 index = whiteListAddress._getEligibleIndexAddress(whiteList,optionEx.settlement);
                uint256 sharedValue = optionEx.tokenTimePrice.mul((preValue - nowValue)).mul(info.amount).div(optionEx.fullPrice);
                totalSharedPayment[index] = totalSharedPayment[index].add(sharedValue);
            }
        }
        //burned
        return _calBurnedSharePrice(begin,end,preTime,whiteList,totalSharedPayment);
    }
    function _calBurnedSharePrice(uint256 beginIndex,uint256 endIndex,uint256 preTime,address[] whiteList,uint256[] memory totalSharedPayment)public view returns(uint256[]){
        uint256 beginBlock = lastCalBlock_share+1;
        if (beginBlock == 1){
            return totalSharedPayment;
        }
        for (; beginBlock <= block.number;beginBlock++){
            uint256[2][] memory burnedTokens = burnBlockOptions[beginBlock];
            uint burnedLen = burnedTokens.length;
            for (uint256 i = 0;i<burnedLen;i++){
                if(burnedTokens[i][0]<beginIndex || burnedTokens[i][0] >=endIndex){
                   continue;
                }
                OptionsInfo storage info = allOptions[burnedTokens[i][0]];
                uint256 expiration = info.expiration;
                if(expiration<preTime || burnedTokens[i][1] == 0){
                    continue;
                }
                OptionsInfoEx storage optionEx = optionExtraMap[burnedTokens[i][0]];
                uint256 nowValue = _optionsPrice.getOptionsPrice_iv(info.strikePrice,info.strikePrice,expiration-now,optionEx.ivNumerator,
                    optionEx.ivDenominator,info.optType);
                nowValue = optionEx.tokenTimePrice.mul(nowValue).mul(burnedTokens[i][1]).div(optionEx.fullPrice);
                uint256 index = whiteListAddress._getEligibleIndexAddress(whiteList,optionEx.settlement);
                totalSharedPayment[index] = totalSharedPayment[index].add(nowValue);
            }
        }       
    }
    function _calculateTimePrice(uint256 preTime,uint256 createdTime,uint256 expiration,
            uint256 strikePrice,uint256 ivNumerator,uint256 ivDenominator,uint8 optType)internal view returns (uint256,uint256){
        uint256 preExpiration = preTime>createdTime ? expiration - preTime : expiration - createdTime;
        uint256 preValue = _optionsPrice.getOptionsPrice_iv(strikePrice,strikePrice,preExpiration,ivNumerator,
            ivDenominator,optType);
        uint256 nowValue = _optionsPrice.getOptionsPrice_iv(strikePrice,strikePrice,expiration-now,ivNumerator,
            ivDenominator,optType);
        return (preValue,nowValue);
    }
    function createOptions(uint8 optType,uint32 underlying,uint256 expiration,uint256 strikePrice,
        uint256 amount,address settlement) onlyManager public returns (uint256) {
        uint256 optionID = allOptions.length;
        uint256 underlyingPrice =  _oracle.getUnderlyingPrice(underlying);
        allOptions.push(OptionsInfo(optionID+1,msg.sender,optType,underlying,expiration,strikePrice,amount));
        optionsBalances[msg.sender].push(optionID);
        if (optionID == 0){
            lastCalBlock = block.number;
        }
        OptionsInfo storage info = allOptions[optionID];
        setOptionsExtra(info,settlement);
        return calOptionsCollateral(info,underlyingPrice);
    }
    function setOptionsExtra(OptionsInfo storage info,address settlement) onlyManager internal{
        uint256 strikePrice = info.strikePrice;
        uint256 expiration = info.expiration - now;
        (uint256 ivNumerator,uint256 ivDenominator) = _volatility.calculateIv(strikePrice,expiration);
        uint256 settlePrice = _oracle.getPrice(settlement);
        uint256 fullPrice = _optionsPrice.getOptionsPrice_iv(strikePrice,strikePrice,expiration,ivNumerator,ivDenominator,info.optType);
        uint256 tokenTimePrice = fullPrice.div(settlePrice);
        optionExtraMap[info.optionID-1]= OptionsInfoEx(now,settlement,tokenTimePrice,fullPrice,ivNumerator,ivDenominator);
    }
    function getTotalOccupiedCollateral() public view returns (uint256) {
        uint256 totalOccupied = sumOptionPhases();
        uint underlyingLen = underlyingAssets.length;
        uint256[] memory prices = new uint256[](underlyingLen);
        for (uint256 i = 0;i<underlyingLen;i++){
            prices[i] = _oracle.getUnderlyingPrice(underlyingAssets[i]);
        }
        uint optionsLen = allOptions.length;
        for (uint256 beginOption = lastCallOption+1; beginOption < optionsLen;beginOption++){
            uint256 index = _getEligibleUnderlyingIndex(allOptions[beginOption].underlying);
            totalOccupied = totalOccupied.add(calOptionsCollateral(allOptions[beginOption],prices[index]));
        }
        uint256 beginBlock = lastCalBlock+1;
        if (beginBlock == 1){
            return totalOccupied;
        }
        for (; beginBlock <= block.number;beginBlock++){
            uint256[2][] storage burnedTokens = burnBlockOptions[beginBlock];
            uint burnedLen = burnedTokens.length;
            for (i = 0;i<burnedLen;i++){
                uint optionId = burnedTokens[i][0];
                index = _getEligibleUnderlyingIndex(allOptions[optionId].underlying);
                totalOccupied = totalOccupied.sub(calBurnedOptionsCollateral(allOptions[optionId],
                    burnedTokens[i][1],prices[index]));
            }
        }
        return totalOccupied;
    }
    function sumOptionPhases()internal view returns(uint256){
        uint256 totalOccupied = 0;
        uint256 i = firstOption%optionPhase;
        uint256 phaseLen = allOptions.length%optionPhase+1;
        for (;i<phaseLen;i++){
            totalOccupied = totalOccupied.add(OptionsPhases[i]);
        }
        return totalOccupied;
    }
    function calOptionsCollateral(OptionsInfo storage option,uint256 underlyingPrice)internal view returns(uint256){
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
    function calBurnedOptionsCollateral(OptionsInfo storage option,uint256 burned,uint256 underlyingPrice)internal view returns(uint256){
        uint256 totalOccupied = 0;
        if ((option.optType == 0) == (option.strikePrice>underlyingPrice)){ // call
            totalOccupied = option.strikePrice.mul(burned);
        } else {
            totalOccupied = underlyingPrice.mul(burned);
        }
        return totalOccupied;
    }
    function burnOptions(uint256 id,uint256 amount)public onlyManager{
        OptionsInfo storage info = _getOptionsById(id);
        checkEligible(info);
        checkOwner(info,msg.sender);
        checkSufficient(info,amount);
        info.amount = info.amount.sub(amount);
        burnBlockOptions[block.number].push([id-1,amount]);
    }
    function getExerciseWorth(uint256 optionsId,uint256 amount)public view returns(uint256){
        OptionsInfo storage info = _getOptionsById(optionsId);
        checkEligible(info);
        checkSufficient(info,amount);
        uint256 underlyingPrice = _oracle.getUnderlyingPrice(info.underlying);
        uint256 tokenPayback = 0;
        if (info.optType == 0){
            if (underlyingPrice > info.strikePrice){
                tokenPayback = underlyingPrice - info.strikePrice;
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
    function _getOptionsById(uint256 id)internal view returns(OptionsInfo storage){
        require(id>0 && id <= allOptions.length,"option id is not exist");
        return allOptions[id-1];
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
    function buyOptionCheck(uint256 expiration,uint32 underlying)public view{
        require(isEligibleUnderlyingAsset(underlying) , "underlying is unsupported asset");
        checkExpiration(expiration);
    }
        /**
     * @dev Implementation of add an eligible expiration into the expirationList.
     * @param expiration new eligible expiration.
     */
    function addExpiration(uint256 expiration)public onlyOwner{
        whiteListUint256.addWhiteListUint256(expirationList,expiration);
    }
    /**
     * @dev Implementation of revoke an invalid expiration from the expirationList.
     * @param removeExpiration revoked expiration.
     */
    function removeExpirationList(uint256 removeExpiration)public onlyOwner returns(bool) {
        return whiteListUint256.removeWhiteListUint256(expirationList,removeExpiration);
    }
    /**
     * @dev Implementation of getting the eligible expirationList.
     */
    function getExpirationList()public view returns (uint256[]){
        return expirationList;
    }
    /**
     * @dev Implementation of testing whether the input expiration is eligible.
     * @param expiration input expiration for testing.
     */    
    function isEligibleExpiration(uint256 expiration) public view returns (bool){
        return whiteListUint256.isEligibleUint256(expirationList,expiration);
    }
    function checkExpiration(uint256 expiration) public view{
        return require(isEligibleExpiration(expiration),"expiration value is not supported");
    }
    function _getEligibleExpirationIndex(uint256 expiration) internal view returns (uint256){
        return whiteListUint256._getEligibleIndexUint256(expirationList,expiration);
    }

}