pragma solidity =0.5.16;
import "./OptionsData.sol";
import "../modules/tuple64.sol";
/**
 * @title Options data contract.
 * @dev A Smart-contract to store options info.
 *
 */
contract OptionsBase is OptionsData {
    using whiteListUint32 for uint32[];
    constructor () public{
        initialize();
    }
    function initialize() onlyOwner public {
        expirationList =  [1 days,2 days,3 days, 7 days, 10 days, 15 days,20 days, 30 days/*,90 days*/];
        underlyingAssets = [1,2];
    }
    function setTimeLimitation(uint256 _limit)public onlyOwner{
        limitation = _limit;
    }
    function getTimeLimitation()public view returns(uint256){
        return limitation;
    }
    
    /**
     * @dev retrieve user's options' id. 
     * @param user user's account.
     */     
    function getUserOptionsID(address user)public view returns(uint64[] memory){
        return optionsBalances[user];
    }
    /**
     * @dev retrieve user's `size` number of options' id. 
     * @param user user's account.
     * @param from user's option list begin positon.
     * @param size retrieve size.
     */ 
    function getUserOptionsID(address user,uint256 from,uint256 size)public view returns(uint64[] memory){
        require(from <optionsBalances[user].length,"input from is overflow");
        require(size>0,"input size is zero");
        uint64[] memory userIdAry = new uint64[](size);
        if (from+size>optionsBalances[user].length){
            size = optionsBalances[user].length-from;
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
    function getOptionInfo(uint64 id)internal view returns(address,uint256,uint256,uint256,uint256){
        OptionsInfo memory info = allOptions[id-1];
        return (info.owner,
            (uint256(id) << 128)+(uint256(info.underlying) << 64) + info.optType,
            (uint256(info.createTime+limitation) << 128)+(uint256(info.createTime) << 64)+info.createTime+info.expiration,
            info.strikePrice,
            info.amount);
            
    }
    /**
     * @dev retrieve `size` number of options' information. 
     * @param from all option list begin positon.
     * @param size retrieve size.
     */     
    function getOptionInfoList(uint256 from,uint256 size)public view 
                returns(address[] memory,uint256[] memory,uint256[] memory,uint256[] memory,uint256[] memory){
        uint256 allLen = allOptions.length;
        require(from <allLen,"input from is overflow");
        require(size>0,"input size is zero");
        if (from+size>allLen){
            size = allLen - from;
        }
        address[] memory ownerArr = new address[](size);
        uint256[] memory type_underlying_id = new uint256[](size);
        uint256[] memory exp_create_limit = new uint256[](size);
        uint256[] memory priceArr = new uint256[](size);
        uint256[] memory amountArr = new uint256[](size);
        for (uint i=0;i<size;i++){
            (ownerArr[i],type_underlying_id[i],exp_create_limit[i],priceArr[i],amountArr[i]) = 
                getOptionInfo(uint64(from+i+1));
        }
        return (ownerArr,type_underlying_id,exp_create_limit,priceArr,amountArr);
    }

    /**
     * @dev retrieve given `ids` options' information. 
     * @param ids retrieved options' id.
     */   
    function getOptionInfoListFromID(uint64[] memory ids)public view 
                returns(address[] memory,uint256[] memory,uint256[] memory,uint256[] memory,uint256[] memory){
        uint256 size = ids.length;
        require(size > 0, "input ids array is empty");
        address[] memory ownerArr = new address[](size);
        uint256[] memory type_underlying_id = new uint256[](size);
        uint256[] memory exp_create_limit = new uint256[](size);
        uint256[] memory priceArr = new uint256[](size);
        uint256[] memory amountArr = new uint256[](size);
        for (uint i=0;i<size;i++){
            (ownerArr[i],type_underlying_id[i],exp_create_limit[i],priceArr[i],amountArr[i]) = 
                getOptionInfo(ids[i]);
        }
        return (ownerArr,type_underlying_id,exp_create_limit,priceArr,amountArr);
    }
        /**
     * @dev retrieve given `ids` options' information. 
     * @param user retrieved user's address.
     */   
    function getUserAllOptionInfo(address user)public view 
                returns(address[] memory,uint256[] memory,uint256[] memory,uint256[] memory,uint256[] memory){
        return getOptionInfoListFromID(optionsBalances[user]);
    }
    /**
     * @dev retrieve given `optionsId` option's burned limit timestamp. 
     * @param optionsId retrieved option's id.
     */ 
    function getOptionsLimitTimeById(uint256 optionsId)public view returns(uint256){
        require(optionsId>0 && optionsId <= allOptions.length,"option id is not exist");
        OptionsInfo storage info = allOptions[optionsId-1];
        return info.createTime + limitation;
    }
    /**
     * @dev retrieve given `optionsId` option's information. 
     * @param optionsId retrieved option's id.
     */ 
    function getOptionsById(uint256 optionsId)public view returns(uint256,address,uint8,uint32,uint256,uint256,uint256){
        OptionsInfo memory info = _getOptionsById(optionsId);
        return (optionsId,info.owner,info.optType,info.underlying,info.createTime+info.expiration,info.strikePrice,info.amount);
    }
    /**
     * @dev retrieve given `optionsId` option's extra information. 
     * @param optionsId retrieved option's id.
     */
    function getOptionsExtraById(uint256 optionsId)public view returns(address,uint256,uint256,uint256,uint256){
        OptionsInfo memory info = _getOptionsById(optionsId);
        return (info.settlement,info.settlePrice,(info.strikePrice*info.priceRate)>>28,
                info.optionsPrice,info.iv);
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
    /**
     * @dev create new option, store option info.
     * @param from option's owner
     * @param type_ly_expiration the tuple64 of option type, underlying,expiration
     * @param strikePrice option's strike price and underlying price
     * @param underlyingPrice option's paid price and price rate
     * @param amount option's amount
     */
    function _createOptions(address from,address settlement,uint256 type_ly_expiration,
        uint128 strikePrice,uint128 underlyingPrice,uint128 amount,uint128 settlePrice) internal returns(uint256){
        uint32 expiration = uint32(type_ly_expiration>>128);
        require(underlyingAssets.isEligibleUint32(uint32(type_ly_expiration>>64)) , "underlying is unsupported asset");
        require(expirationList.isEligibleUint32(expiration),"expiration value is not supported");
        uint256 iv = _volatility.calculateIv(uint32(type_ly_expiration>>64),uint8(type_ly_expiration),expiration,
            underlyingPrice,strikePrice); 
        uint256 optPrice = _optionsPrice.getOptionsPrice_iv(underlyingPrice,strikePrice,expiration,iv,uint8(type_ly_expiration));
        allOptions.push(OptionsInfo(from,
            uint8(type_ly_expiration),
            uint24(type_ly_expiration>>64),
            uint64(optPrice),
            settlement,
            uint64(now),
            expiration,
            amount,
            settlePrice,
            strikePrice,
            uint32((underlyingPrice<<28)/strikePrice),
            uint64(iv),
            0));
        uint64 optionID = uint64(allOptions.length);
        optionsBalances[from].push(optionID);
        emit CreateOption(from,optionID,uint8(type_ly_expiration),uint32(type_ly_expiration>>64),expiration+now,
            strikePrice,amount);
        return optPrice;
    }
    /**
     * @dev An auxiliary function, store new option's extra information.
     * @param info option's information
     * @param settlement the Coin address which user's paying for
     * @param priceAndRate option's paid price
     * @param underlyingAndStrike option's strike price and underlying price
     */
     /*
    function setOptionsExtra(OptionsInfo memory info,address settlement,uint256 priceAndRate,uint256 underlyingAndStrike,uint256 settlePrice) internal{
        uint256 underlyingPrice = (underlyingAndStrike>>128);
        uint256 expiration = info.expiration - now;
        uint256 ivNumerator = _volatility.calculateIv(info.underlying,info.optType,expiration,underlyingPrice,uint256(uint128(underlyingAndStrike)));
        uint128 optionPrice = uint128(priceAndRate>>128);
        uint128 rate = uint128(priceAndRate);
        settlePrice = settlePrice/(uint256(rate));
        optionExtraMap[info.optionID-1]= OptionsInfoEx(settlement,settlePrice,underlyingPrice,(uint256(optionPrice)*rate)>>32,ivNumerator,1<<32);
    }
    */
    /**
     * @dev burn an exist option whose id is `id`.
     * @param from option's owner
     * @param amount option's amount
     */
    function _burnOptions(address from,uint256 id,OptionsInfo memory info,uint256 amount)internal{
//        OptionsInfo storage info = _getOptionsById(id);
        require(info.createTime+info.expiration>now,"option is expired");
        require(info.owner == from,"caller is not the options owner");
        require(info.amount >= amount,"option amount is insufficient");
        allOptions[id-1].amount = info.amount-uint128(amount);
        emit BurnOption(from,id,amount);
    }
    /**
     * @dev calculate option's exercise worth.
     * @param optionsId option's id
     * @param amount option's amount
     */
    function getExerciseWorth(uint256 optionsId,uint256 amount)public view returns(uint256){
        OptionsInfo memory info = _getOptionsById(optionsId);
        require(info.createTime+info.expiration>now,"option is expired");
        require(info.amount >= amount,"option amount is insufficient");
        uint256 underlyingPrice = oracleUnderlyingPrice(info.underlying);
        uint256 tokenPayback = _getOptionsPayback(info.optType,info.strikePrice,underlyingPrice);
        if (tokenPayback == 0 ){
            return 0;
        } 
        return tokenPayback*amount;
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

    // /**
    //  * @dev check option's underlying and expiration.
    //  * @param expiration option's expiration
    //  * @param underlying option's underlying
    //  */
    // function buyOptionCheck(uint32 expiration,uint32 underlying)public view{
    //     require(underlyingAssets.isEligibleUint32(underlying) , "underlying is unsupported asset");
    //     require(expirationList.isEligibleUint32(expiration),"expiration value is not supported");
    // }
    /**
     * @dev Implementation of add an eligible expiration into the expirationList.
     * @param expiration new eligible expiration.
     */
    function addExpiration(uint32 expiration)public onlyOwner{
        expirationList.addWhiteListUint32(expiration);
    }
    /**
     * @dev Implementation of revoke an invalid expiration from the expirationList.
     * @param removeExpiration revoked expiration.
     */
    function removeExpirationList(uint32 removeExpiration)public onlyOwner returns(bool) {
        return expirationList.removeWhiteListUint32(removeExpiration);
    }
    /**
     * @dev Implementation of getting the eligible expirationList.
     */
    function getExpirationList()public view returns (uint32[] memory){
        return expirationList;
    }
    /**
     * @dev Implementation of testing whether the input expiration is eligible.
     * @param expiration input expiration for testing.
     */    
    function isEligibleExpiration(uint32 expiration) public view returns (bool){
        return expirationList.isEligibleUint32(expiration);
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
        uint256 totalOccupied = _getOptionsWorth(option.optType,option.strikePrice,underlyingPrice)*amount;
        require(totalOccupied<=1e40,"Option collateral occupied calculate error");
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
    function getBurnedFullPay(uint256 optionID,uint256 amount) Smaller(amount) public view returns(address,uint256){
        OptionsInfo memory info = _getOptionsById(optionID);
        return (info.settlement,info.optionsPrice*amount/info.settlePrice);
    }
}