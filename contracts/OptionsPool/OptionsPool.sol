pragma solidity =0.5.16;
import "./Optionsbase.sol";
/**
 * @title Options pool contract.
 * @dev store options' information and nessesary options' calculation.
 *
 */
contract OptionsPool is OptionsBase {
    constructor (address multiSignatureClient)public proxyOwner(multiSignatureClient) {
    }
    function initialize() public{
        versionUpdater.initialize();
        expirationList =  [1 days,2 days,3 days, 7 days, 10 days, 15 days,20 days, 30 days/*,90 days*/];
        limitation = 1 hours;
        maxAmount = 1e30;
        minAmount = 1e2;
    } 
    function initAddresses(address optionsCalAddr,address oracleAddr,address optionsPriceAddr,address ivAddress,uint32[] calldata underlyings)external onlyOwner {
        setOptionsNetWorthCal(optionsCalAddr);
        _oracle = IPHXOracle(oracleAddr);
        optionsPrice = IOptionsPrice(optionsPriceAddr);
        volatility = IVolatility(ivAddress);
        underlyingAssets = underlyings;
    }

    /**
     * @dev create new option,modify collateral occupied and net worth value, only manager contract can invoke this.
     * @param from user's address.
     * @param type_ly_expiration tuple64 for option type,underlying,expiration.
     * @param strikePrice user's input new option's strike price.
     * @param underlyingPrice current new option's price, calculated by options price contract.
     * @param amount user's input new option's amount.
     */ 
    function createOptions(address from,address settlement,uint256 type_ly_expiration,
        uint128 strikePrice,uint128 underlyingPrice,uint128 amount,uint128 settlePrice) onlyManager public returns(uint256){
        uint256 price = _createOptions(from,settlement,type_ly_expiration,strikePrice,underlyingPrice,amount,settlePrice);
        uint256 totalOccupied = _getOptionsWorth(uint8(type_ly_expiration),strikePrice,underlyingPrice,amount);
        require(totalOccupied<=1e40,"Option collateral occupied calculate error");
        if (uint8(type_ly_expiration) == 0){
            underlyingOccupiedMap[uint32(type_ly_expiration>>64)].callLatestOccupied += int256(totalOccupied);
        }else{
            underlyingOccupiedMap[uint32(type_ly_expiration>>64)].putLatestOccupied += int256(totalOccupied);
        }
        underlyingTotalOccupied += totalOccupied;
        return price;
    }
    /**
     * @dev burn option,modify collateral occupied and net worth value, only manager contract can invoke this.
     * @param from user's address.
     * @param id user's input option's id.
     * @param amount user's input burned option's amount.
     * @param optionPrice current new option's price, calculated by options price contract.
     */ 
    function burnOptions(address from,uint256 id,uint256 amount,uint256 optionPrice)public onlyManager Smaller(amount) OutLimitation(id){
        OptionsInfo memory info = _getOptionsById(id);
        _burnOptions(from,id,info,amount);
        uint256 currentPrice = oracleUnderlyingPrice(info.underlying);
        _burnOptionsCollateral(info,amount,currentPrice);
        _burnOptionsNetworth(info,amount,currentPrice,optionPrice);
    }
    modifier OutLimitation(uint256 id) {
        require(allOptions[id-1].createTime+limitation<now,"Time limitation is not expired!");
        _;
    }
    /**
     * @dev deduct burned option collateral occupied value when user burn option.
     * @param info burned option's information.
     * @param amount burned option's amount.
     * @param underlyingPrice current underlying price.
     */ 
    function _burnOptionsCollateral(OptionsInfo memory info,uint256 amount,uint256 underlyingPrice) internal {
        uint256 newOccupied = _getOptionsWorth(info.optType,info.strikePrice,underlyingPrice,amount);
        require(newOccupied<=1e40,"Option collateral occupied calculate error");
        if (info.optType == 0){
            underlyingOccupiedMap[info.underlying].callLatestOccupied -= int256(newOccupied);
        }else{
            underlyingOccupiedMap[info.underlying].putLatestOccupied -= int256(newOccupied);
        }
        underlyingTotalOccupied -= newOccupied;
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
     * @dev set burn option net worth change.
     * @param info the option information.
     * @param amount the option amount to calculate.
     * @param underlyingPrice underlying price when option is created.
     * @param currentPrice current underlying price.
     */
    function _burnOptionsNetworth(OptionsInfo memory info,uint256 amount,uint256 underlyingPrice,uint256 currentPrice) internal {
        int256 curValue = _calCurtimeCallateralFall(info,amount,underlyingPrice);
        uint256 timeWorth = info.optionsPrice>currentPrice ? info.optionsPrice-currentPrice : 0;
        timeWorth = timeWorth*amount/info.settlePrice;
        address settlement = info.settlement;
        curValue = curValue / int256(oraclePrice(settlement));
        int256 value = curValue - int256(timeWorth);
        optionsLatestNetWorth[settlement] = optionsLatestNetWorth[settlement]+value;
    }
        /**
     * @dev subfunction, calculate option payback fall value.
     * @param info the option information.
     * @param amount the option amount to calculate.
     * @param curPrice current underlying price.
     */
    function _calCurtimeCallateralFall(OptionsInfo memory info,uint256 amount,uint256 curPrice) internal view returns(int256){
        if (info.createTime + info.expiration<=now || amount == 0){
            return 0;
        }
        uint256 newFall = _getOptionsPayback(info.optType,info.optionsPrice,curPrice,amount);
        uint256 OriginFall = _getOptionsPayback(info.optType,info.optionsPrice,(info.strikePrice*info.priceRate)>>28,amount);
        int256 curValue = int256(newFall) - int256(OriginFall);
        require(curValue>=-1e40 && curValue<=1e40,"options fall calculate error");
        return curValue;
    }
    function getOccupiedCalInfo()public view returns(uint256,int256[] memory,int256[] memory){
        delegateToViewAndReturn();
    }
    function getUnderlyingTotalOccupiedCollateral(uint32 /*underlying*/) public view returns (uint256,uint256,uint256){
        delegateToViewAndReturn();
    }
    function getTotalOccupiedCollateral() public view returns (uint256) {
        return underlyingTotalOccupied;
    }
    /**
     * @dev calculate collateral occupied value.
     * @param lastOption last option's position.
     * @param beginOption begin option's poisiton.
     * @param endOption end option's poisiton.
     */  
    function calculatePhaseOccupiedCollateral(uint256 lastOption,uint256 beginOption,uint256 endOption) public view returns(uint256[] memory,uint256[] memory,uint256,bool){
        delegateToViewAndReturn();
    }
    function setOccupiedCollateral() public{
        delegateAndReturn();
    }
    /**
     * @dev retrieve all information for net worth calculation. 
     * param whiteList collateral address whitelist.
     */ 
    function getNetWrothCalInfo(address[] memory /*whiteList*/)public view returns(uint256,int256[] memory){
        delegateToViewAndReturn();
    }
    function getOptionCalRangeAll(address[] memory /*whiteList*/)public view returns(uint256,int256[] memory,int256[] memory,uint256,int256[] memory,uint256,uint256){
        delegateToViewAndReturn();
    }
    function setCollateralPhase(uint256[] calldata /*totalCallOccupied*/,uint256[] calldata /*totalPutOccupied*/,uint256 /*beginOption*/,
            int256[] calldata /*latestCallOccpied*/,int256[] calldata /*latestPutOccpied*/) external{
        delegateAndReturn();
    }
    /**
     * @dev calculate options time shared value,from begin to end in the alloptionsList.
     * param lastOption the last option position.
     * param begin the begin options position.
     * param end the end options position.
     * param whiteList eligible collateral address white list.
     */
    function calRangeSharedPayment(uint256 /*lastOption*/,uint256 /*begin*/,uint256 /*end*/,address[] calldata /*whiteList*/)
            external view returns(int256[] memory,uint256[] memory,uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev calculate options payback fall value,from begin to end in the alloptionsList.
     * param lastOption the last option position.
     * param begin the begin options position.
     * param end the end options position.
     * param whiteList eligible collateral address white list.
     */
    function calculatePhaseOptionsFall(uint256 /*lastOption*/,uint256 /*begin*/,uint256 /*end*/,address[] calldata /*whiteList*/)
         external view returns(int256[] memory){    
         delegateToViewAndReturn();
    }
    function setSharedState(uint256 /*newFirstOption*/,int256[] calldata /*latestNetWorth*/,address[] calldata /*whiteList*/) external {
        delegateAndReturn();
    }
    function delegateToImplementation(bytes memory data) public returns (bytes memory) {
        (bool success, bytes memory returnData) = OptionsNetWorthCal().delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize)
            }
        }
        return returnData;
    }
    function delegateToViewAndReturn() internal view returns (bytes memory) {
        (bool success, ) = address(this).staticcall(abi.encodeWithSignature("delegateToImplementation(bytes)", msg.data));

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize)

            switch success
            case 0 { revert(free_mem_ptr, returndatasize) }
            default { return(add(free_mem_ptr, 0x40), sub(returndatasize, 0x40)) }
        }
    }

    function delegateAndReturn() internal returns (bytes memory) {
        (bool success, ) = OptionsNetWorthCal().delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize)

            switch success
            case 0 { revert(free_mem_ptr, returndatasize) }
            default { return(free_mem_ptr, returndatasize) }
        }
    }
}