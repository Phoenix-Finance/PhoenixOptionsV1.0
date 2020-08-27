pragma solidity ^0.5.1;
import "./modules/SafeMath.sol";
import "./modules/Managerable.sol";
import "./interfaces/IFNXOracle.sol";
import "./modules/underlyingAssets.sol";
import "./interfaces/IVolatility.sol";
import "./modules/tuple64.sol";
/**
 * @title Options data contract.
 * @dev A Smart-contract to store options info.
 *
 */
contract OptionsBase is UnderlyingAssets,Managerable,ImportOracle,ImportVolatility {
    using whiteListUint256 for uint256[];
    using SafeMath for uint256;
    // store option info
    struct OptionsInfo {
        uint64     optionID;    //an increasing nubmer id, begin from one.
        address     owner;      // option's owner
        uint8   	optType;    //0 for call, 1 for put
        uint32		underlying; // underlying ID, 1 for BTC,2 for ETH
        uint256		expiration; // Expiration timestamp
        uint256     strikePrice;    //strike price
        uint256     amount;         // mint amount
    }
    // store option extra info
    struct OptionsInfoEx{
        uint256		 createdTime;   //option's created timestamp
        address      settlement;    //user's settlement paying for option. 
        uint256      tokenTimePrice; //option's buying price based on settlement, used for options share calculation
        uint256      underlyingPrice;//underlying price when option is created.
        uint256      fullPrice;      //option's buying price.
        uint256      ivNumerator;   // option's iv numerator when option is created.
        uint256      ivDenominator;// option's iv denominator when option is created.
    }
    //all options information list
    OptionsInfo[] internal allOptions;
    // all option's extra information map
    mapping(uint256=>OptionsInfoEx) internal optionExtraMap;
    // option share value calculation's decimal
    uint256 constant internal calDecimals = 1e18;
    //user options balances
    mapping(address=>uint256[]) internal optionsBalances;
    //expiration whitelist
    uint256[] internal expirationList;
    //option burn limit time from option's created.
    uint256 internal burnTimeLimit = 1 hours;

    /**
     * @dev Emitted when `owner` create a new option. 
     * @param owner new option's owner
     * @param optionID new option's id
     * @param optionID new option's type 
     * @param underlying new option's underlying 
     * @param expiration new option's expiration timestamp
     * @param strikePrice  new option's strikePrice
     * @param amount  new option's amount
     */
    event CreateOption(address indexed owner,uint256 indexed optionID,uint8 optType,uint32 underlying,uint256 expiration,uint256 strikePrice,uint256 amount);
    /**
     * @dev Emitted when `owner` burn `amount` his option which id is `optionID`. 
     */    
    event BurnOption(address indexed owner,uint256 indexed optionID,uint amount);
    constructor () public{
        expirationList =  [1 days,3 days, 7 days, 10 days, 15 days, 30 days,90 days];
        underlyingAssets = [1,2];
    }
    /**
     * @dev get option's burn time limit. 
     */ 
    function getBurnTimeLimit()public view returns(uint256){
        return burnTimeLimit;
    }
    /**
     * @dev set option's burn time limit. 
     * @param timeLimit set new option's burn time limit.
     */ 
    function setBurnTimeLimit(uint256 timeLimit)public onlyOwner{
        burnTimeLimit = timeLimit;
    }
    /**
     * @dev retrieve user's options' id. 
     * @param user user's account.
     */     
    function getUserOptionsID(address user)public view returns(uint256[] memory){
        return optionsBalances[user];
    }
    /**
     * @dev retrieve user's `size` number of options' id. 
     * @param user user's account.
     * @param from user's option list begin positon.
     * @param size retrieve size.
     */ 
    function getUserOptionsID(address user,uint256 from,uint256 size)public view returns(uint256[] memory){
        uint256[] memory userIdAry = new uint256[](size);
        if (from+size>optionsBalances[user].length){
            size = optionsBalances[user].length.sub(from);
        }
        for (uint256 i= 0;i<size;i++){
            userIdAry[i] = optionsBalances[user][from+i];
        }
        return userIdAry;
    }
    /**
     * @dev retrieve all option list length. 
     */ 
    function getOptionInfoLength()public view returns (uint256){
        return allOptions.length;
    }
    /**
     * @dev retrieve `size` number of options' information. 
     * @param from all option list begin positon.
     * @param size retrieve size.
     */     
    function getOptionInfoList(uint256 from,uint256 size)public view 
                returns(address[] memory,uint256[] memory,uint256[] memory,uint256[] memory,uint256[] memory){
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
                typeAndUnderArr[i] = (info.underlying << 16) + info.optType;
                expArr[i] = info.expiration;
                priceArr[i] = info.strikePrice;
                amountArr[i] = info.amount;
            }
            return (ownerArr,typeAndUnderArr,expArr,priceArr,amountArr);
        }
    }
    /**
     * @dev retrieve given `ids` options' information. 
     * @param ids retrieved options' id.
     */   
    function getOptionInfoListFromID(uint256[] memory ids)public view 
                returns(address[] memory,uint256[] memory,uint256[] memory,uint256[] memory,uint256[] memory){
        uint256 size = ids.length;
        address[] memory ownerArr = new address[](size);
        uint256[] memory typeAndUnderArr = new uint256[](size);
        uint256[] memory expArr = new uint256[](size);
        uint256[] memory priceArr = new uint256[](size);
        uint256[] memory amountArr = new uint256[](size);
        for (uint i=0;i<size;i++){
            OptionsInfo storage info = _getOptionsById(ids[i]);
            ownerArr[i] = info.owner;
            typeAndUnderArr[i] = (info.underlying << 16) + info.optType;
            expArr[i] = info.expiration;
            priceArr[i] = info.strikePrice;
            amountArr[i] = info.amount;
        }
        return (ownerArr,typeAndUnderArr,expArr,priceArr,amountArr);
    }
    /**
     * @dev retrieve given `optionsId` option's burned limit timestamp. 
     * @param optionsId retrieved option's id.
     */ 
    function getOptionsLimitTimeById(uint256 optionsId)public view returns(uint256){
        require(optionsId>0 && optionsId <= allOptions.length,"option id is not exist");
        return optionExtraMap[optionsId-1].createdTime + burnTimeLimit;
    }
    /**
     * @dev retrieve given `optionsId` option's information. 
     * @param optionsId retrieved option's id.
     */ 
    function getOptionsById(uint256 optionsId)public view returns(uint256,address,uint8,uint32,uint256,uint256,uint256){
        OptionsInfo storage info = _getOptionsById(optionsId);
        return (info.optionID,info.owner,info.optType,info.underlying,info.expiration,info.strikePrice,info.amount);
    }
    /**
     * @dev retrieve given `optionsId` option's extra information. 
     * @param optionsId retrieved option's id.
     */
    function getOptionsExtraById(uint256 optionsId)public view returns(uint256,address,uint256,uint256,uint256,uint256,uint256){
        require(optionsId>0 && optionsId <= allOptions.length,"option id is not exist");
        OptionsInfoEx storage info = optionExtraMap[optionsId];
        return (info.createdTime,info.settlement,info.tokenTimePrice,info.underlyingPrice,
                info.fullPrice,info.ivNumerator,info.ivDenominator);
    }
    /**
     * @dev An auxiliary function, get underlying prices. 
     */
    function getUnderlyingPrices()internal view returns(uint256[] memory){
        uint256 underlyingLen = underlyingAssets.length;
        uint256[] memory prices = new uint256[](underlyingLen);
        for (uint256 i = 0;i<underlyingLen;i++){
            prices[i] = _oracle.getUnderlyingPrice(underlyingAssets[i]);
        }
        return prices;
    }
    /**
     * @dev create new option, store option info.
     * @param from option's owner
     * @param settlement the Coin address which user's paying for
     * @param type_ly_exp the tuple64 of option type, underlying,expiration
     * @param strikePrice option's strike price
     * @param optionPrice option's paid price
     * @param amount option's amount
     */
    function _createOptions(address from,address settlement,uint256 type_ly_exp,uint256 strikePrice,uint256 optionPrice,
                uint256 amount) internal {
        uint256 optionID = allOptions.length;
        uint8 optType = uint8(tuple64.getValue0(type_ly_exp));
        uint32 underlying = uint32(tuple64.getValue1(type_ly_exp));
        allOptions.push(OptionsInfo(uint64(optionID+1),from,optType,underlying,tuple64.getValue2(type_ly_exp)+now,strikePrice,amount));
        optionsBalances[from].push(optionID+1);
        OptionsInfo memory info = allOptions[optionID];
        setOptionsExtra(info,settlement,optionPrice,strikePrice,underlying);
        emit CreateOption(from,optionID+1,optType,underlying,tuple64.getValue2(type_ly_exp)+now,strikePrice,amount);
    }
    /**
     * @dev An auxiliary function, store new option's extra information.
     * @param info option's information
     * @param settlement the Coin address which user's paying for
     * @param optionPrice option's paid price
     * @param strikePrice option's strike price
     * @param underlying option's underlying
     */
    function setOptionsExtra(OptionsInfo memory info,address settlement,uint256 optionPrice,uint256 strikePrice,uint256 underlying) internal{
        uint256 underlyingPrice = _oracle.getUnderlyingPrice(underlying);
        uint256 expiration = info.expiration - now;
        (uint256 ivNumerator,uint256 ivDenominator) = _volatility.calculateIv(info.underlying,info.optType,expiration,underlyingPrice,strikePrice);
        uint256 tokenTimePrice = calDecimals/_oracle.getPrice(settlement);
        optionExtraMap[info.optionID-1]= OptionsInfoEx(now,settlement,tokenTimePrice,underlyingPrice,optionPrice,ivNumerator,ivDenominator);
    }
    /**
     * @dev burn an exist option whose id is `id`.
     * @param from option's owner
     * @param amount option's amount
     */
    function _burnOptions(address from,uint256 id,uint256 amount)internal{
        OptionsInfo storage info = _getOptionsById(id);
        checkEligible(info);
        checkBurnable(info.optionID);
        checkOwner(info,from);
        checkSufficient(info,amount);
        info.amount = info.amount-amount;
        emit BurnOption(from,id,amount);
    }
    /**
     * @dev calculate option's exercise worth.
     * @param optionsId option's id
     * @param amount option's amount
     */
    function getExerciseWorth(uint256 optionsId,uint256 amount)public view returns(uint256){
        OptionsInfo memory info = _getOptionsById(optionsId);
        checkEligible(info);
        checkSufficient(info,amount);
        uint256 underlyingPrice = _oracle.getUnderlyingPrice(info.underlying);
        uint256 tokenPayback = _getOptionsPayback(info.optType,info.strikePrice,underlyingPrice);
        if (tokenPayback == 0 ){
            return 0;
        } 
        return tokenPayback.mul(amount);
    }
    /**
     * @dev An auxiliary function, calculate option's exercise payback.
     * @param optType option's type
     * @param strikePrice option's strikePrice
     * @param underlyingPrice underlying's price
     */
    function _getOptionsPayback(uint8 optType,uint256 strikePrice,uint256 underlyingPrice)internal pure returns(uint256){
        if ((optType == 0) == (strikePrice>underlyingPrice)){ // call
            return 0;
        } else {
            return (optType == 0) ? underlyingPrice - strikePrice : strikePrice - underlyingPrice;
        }
    }
    /**
     * @dev retrieve option by id, check option's id.
     * @param id option's id
     */
    function _getOptionsById(uint256 id)internal view returns(OptionsInfo storage){
        require(id>0 && id <= allOptions.length,"option id is not exist");
        return allOptions[id-1];
    }
    /**
     * @dev check option's burned time limited.
     * @param optionID option's id
     */
    function checkBurnable(uint256 optionID)internal view{
        require(optionExtraMap[optionID-1].createdTime+burnTimeLimit<now,"option lock limitation is not expired");
    }
    /**
     * @dev check whether option is eligible, check option's expiration.
     * @param info option's information
     */
    function checkEligible(OptionsInfo memory info)internal view{
        require(info.expiration>now,"option is expired");
    }
    /**
     * @dev check whether option's owner is equal.
     * @param info option's information
     * @param owner user's address
     */
    function checkOwner(OptionsInfo memory info,address owner)internal pure{
        require(info.owner == owner,"caller is not the options owner");
    }
    /**
     * @dev check whether option's amount is sufficient.
     * @param info option's information
     * @param amount user input amount
     */
    function checkSufficient(OptionsInfo memory info,uint256 amount) internal pure{
        require(info.amount >= amount,"option amount is insufficient");
    }
    /**
     * @dev check option's underlying and expiration.
     * @param expiration option's expiration
     * @param underlying option's underlying
     */
    function buyOptionCheck(uint256 expiration,uint32 underlying)public view{
        require(isEligibleUnderlyingAsset(underlying) , "underlying is unsupported asset");
        checkExpiration(expiration);
    }
    /**
     * @dev Implementation of add an eligible expiration into the expirationList.
     * @param expiration new eligible expiration.
     */
    function addExpiration(uint256 expiration)public onlyOwner{
        expirationList.addWhiteListUint256(expiration);
    }
    /**
     * @dev Implementation of revoke an invalid expiration from the expirationList.
     * @param removeExpiration revoked expiration.
     */
    function removeExpirationList(uint256 removeExpiration)public onlyOwner returns(bool) {
        return expirationList.removeWhiteListUint256(removeExpiration);
    }
    /**
     * @dev Implementation of getting the eligible expirationList.
     */
    function getExpirationList()public view returns (uint256[] memory){
        return expirationList;
    }
    /**
     * @dev Implementation of testing whether the input expiration is eligible.
     * @param expiration input expiration for testing.
     */    
    function isEligibleExpiration(uint256 expiration) public view returns (bool){
        return expirationList.isEligibleUint256(expiration);
    }
    /**
     * @dev check option's expiration.
     * @param expiration option's expiration
     */
    function checkExpiration(uint256 expiration) public view{
        return require(isEligibleExpiration(expiration),"expiration value is not supported");
    }
    /**
     * @dev retrieve index from expiration white list.
            If the input expriation is not found, the index is equal to whitelist's length, 
     * @param expiration input expiration
     */
    function _getEligibleExpirationIndex(uint256 expiration) internal view returns (uint256){
        return expirationList._getEligibleIndexUint256(expiration);
    }
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
            if(info.expiration<now || info.amount == 0){
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
        if (option.expiration<=now || option.amount == 0){
            return 0;
        }
        uint256 totalOccupied = _getOptionsWorth(option.optType,option.strikePrice,underlyingPrice).mul(option.amount);
        return totalOccupied;
    }
    /**
     * @dev calculate one option's occupied collateral.
     * @param optType  option's type
     * @param strikePrice  option's strikePrice
     * @param underlyingPrice  underlying current price.
     */
    function _getOptionsWorth(uint8 optType,uint256 strikePrice,uint256 underlyingPrice)internal pure returns(uint256){
        if ((optType == 0) == (strikePrice>underlyingPrice)){ // call
            return strikePrice;
        } else {
            return underlyingPrice;
        }
    }
    /**
     * @dev calculate `amount` number of Option's full price when option is burned.
     * @param optionID  option's optionID
     * @param amount  option's amount
     */
    function getBurnedFullPay(uint256 optionID,uint256 amount) public view returns(address,uint256){
        OptionsInfoEx storage optionEx = optionExtraMap[optionID-1];
        return (optionEx.settlement,optionEx.fullPrice.mul(optionEx.tokenTimePrice).mul(amount)/calDecimals);
    }
}