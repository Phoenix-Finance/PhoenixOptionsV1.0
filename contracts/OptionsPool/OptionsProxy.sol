pragma solidity =0.5.16;
import "./OptionsData.sol";
import "../Proxy/baseProxy.sol";
/**
 * @title  Erc20Delegator Contract

 */
contract OptionsProxy is OptionsData,baseProxy{
        /**
     * @dev constructor function , setting contract address.
     *  oracleAddr FNX oracle contract address
     *  optionsPriceAddr options price contract address
     *  ivAddress implied volatility contract address
     */  

    constructor(address implementation_,address oracleAddr,address optionsPriceAddr,address ivAddress)
         baseProxy(implementation_) public  {
        _oracle = IFNXOracle(oracleAddr);
        _optionsPrice = IOptionsPrice(optionsPriceAddr);
        _volatility = IVolatility(ivAddress);
    }
    function setTimeLimitation(uint256 /*_limit*/)public{
        delegateAndReturn();
    }
    function getTimeLimitation()public view returns(uint256){
        delegateToViewAndReturn();
    }
    
    /**
     * @dev retrieve user's options' id. 
     *  user user's account.
     */     
    function getUserOptionsID(address /*user*/)public view returns(uint64[] memory){
        delegateToViewAndReturn();
    }
    /**
     * @dev retrieve user's `size` number of options' id. 
     *  user user's account.
     *  from user's option list begin positon.
     *  size retrieve size.
     */ 
    function getUserOptionsID(address /*user*/,uint256 /*from*/,uint256 /*size*/)public view returns(uint64[] memory){
        delegateToViewAndReturn();
    }
    /**
     * @dev retrieve all option list length. 
     */ 
    function getOptionInfoLength()public view returns (uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev retrieve `size` number of options' information. 
     *  from all option list begin positon.
     *  size retrieve size.
     */     
    function getOptionInfoList(uint256 /*from*/,uint256 /*size*/)public view 
                returns(address[] memory,uint256[] memory,uint256[] memory,uint256[] memory,uint256[] memory){
        delegateToViewAndReturn();
    }
    /**
     * @dev retrieve given `ids` options' information. 
     *  ids retrieved options' id.
     */   
    function getOptionInfoListFromID(uint256[] memory /*ids*/)public view 
                returns(address[] memory,uint256[] memory,uint256[] memory,uint256[] memory,uint256[] memory){
        delegateToViewAndReturn();
    }
    /**
     * @dev retrieve given `optionsId` option's burned limit timestamp. 
     *  optionsId retrieved option's id.
     */ 
    function getOptionsLimitTimeById(uint256 /*optionsId*/)public view returns(uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev retrieve given `optionsId` option's information. 
     *  optionsId retrieved option's id.
     */ 
    function getOptionsById(uint256 /*optionsId*/)public view returns(uint256,address,uint8,uint32,uint256,uint256,uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev retrieve given `optionsId` option's extra information. 
     *  optionsId retrieved option's id.
     */
    function getOptionsExtraById(uint256 /*optionsId*/)public view returns(address,uint256,uint256,uint256,uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev calculate option's exercise worth.
     *  optionsId option's id
     *  amount option's amount
     */
    function getExerciseWorth(uint256 /*optionsId*/,uint256 /*amount*/)public view returns(uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev check option's underlying and expiration.
     *  expiration option's expiration
     *  underlying option's underlying
     */
    // function buyOptionCheck(uint32 /*expiration*/,uint32 /*underlying*/)public view{
    //     delegateToViewAndReturn();
    // }
    /**
     * @dev Implementation of add an eligible expiration into the expirationList.
     *  expiration new eligible expiration.
     */
    function addExpiration(uint32 /*expiration*/)public{
        delegateAndReturn();
    }
    /**
     * @dev Implementation of revoke an invalid expiration from the expirationList.
     *  removeExpiration revoked expiration.
     */
    function removeExpirationList(uint32 /*removeExpiration*/)public returns(bool) {
        delegateAndReturn();
    }
    /**
     * @dev Implementation of getting the eligible expirationList.
     */
    function getExpirationList()public view returns (uint32[] memory){
        delegateToViewAndReturn();
    }
    /**
     * @dev Implementation of testing whether the input expiration is eligible.
     *  expiration input expiration for testing.
     */    
    function isEligibleExpiration(uint256 /*expiration*/) public view returns (bool){
        delegateToViewAndReturn();
    }
    /**
     * @dev check option's expiration.
     *  expiration option's expiration
     */
    function checkExpiration(uint256 /*expiration*/) public view{
        delegateToViewAndReturn();
    }
    /**
     * @dev calculate `amount` number of Option's full price when option is burned.
     *  optionID  option's optionID
     *  amount  option's amount
     */
    function getBurnedFullPay(uint256 /*optionID*/,uint256 /*amount*/) public view returns(address,uint256){
        delegateToViewAndReturn();
    }
        /**
     * @dev retrieve collateral occupied calculation information.
     */    
    function getOccupiedCalInfo()public view returns(uint256,int256,int256){
        delegateToViewAndReturn();
    }
    /**
     * @dev calculate collateral occupied value, and modify database, only foundation operator can modify database.
     */  
    function setOccupiedCollateral() public {
        delegateAndReturn();
    }
    /**
     * @dev calculate collateral occupied value.
     *  lastOption last option's position.
     *  beginOption begin option's poisiton.
     *  endOption end option's poisiton.
     */  
    function calculatePhaseOccupiedCollateral(uint256 /*lastOption*/,uint256 /*beginOption*/,uint256 /*endOption*/) public view returns(uint256,uint256,uint256,bool){
        delegateToViewAndReturn();
    }
 
    /**
     * @dev set collateral occupied value, only foundation operator can modify database.
     * totalCallOccupied new call options occupied collateral calculation result.
     * totalPutOccupied new put options occupied collateral calculation result.
     * beginOption new first valid option's positon.
     * latestCallOccpied latest call options' occupied value when operater invoke collateral occupied calculation.
     * latestPutOccpied latest put options' occupied value when operater invoke collateral occupied calculation.
     */  
    function setCollateralPhase(uint256 /*totalCallOccupied*/,uint256 /*totalPutOccupied*/,
        uint256 /*beginOption*/,int256 /*latestCallOccpied*/,int256 /*latestPutOccpied*/) public{
        delegateAndReturn();
    }
    function getAllTotalOccupiedCollateral() public view returns (uint256,uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev get call options total collateral occupied value.
     */ 
    function getCallTotalOccupiedCollateral() public view returns (uint256) {
        delegateToViewAndReturn();
    }
    /**
     * @dev get put options total collateral occupied value.
     */ 
    function getPutTotalOccupiedCollateral() public view returns (uint256) {
        delegateToViewAndReturn();
    }
    /**
     * @dev get real total collateral occupied value.
     */ 
    function getTotalOccupiedCollateral() public view returns (uint256) {
        delegateToViewAndReturn();
    }
    /**
     * @dev retrieve all information for net worth calculation. 
     *  whiteList collateral address whitelist.
     */ 
    function getNetWrothCalInfo(address[] memory /*whiteList*/)public view returns(uint256,int256[] memory){
        delegateToViewAndReturn();
    }
    /**
     * @dev retrieve latest options net worth which paid in settlement coin. 
     *  settlement settlement coin address.
     */ 
    function getNetWrothLatestWorth(address /*settlement*/)public view returns(int256){
        delegateToViewAndReturn();
    }
    /**
     * @dev set latest options net worth balance, only manager contract can modify database.
     *  newFirstOption new first valid option position.
     *  latestNetWorth latest options net worth.
     *  whiteList eligible collateral address white list.
     */ 
    function setSharedState(uint256 /*newFirstOption*/,int256[] memory /*latestNetWorth*/,address[] memory /*whiteList*/) public{
        delegateAndReturn();
    }
    /**
     * @dev calculate options time shared value,from begin to end in the alloptionsList.
     *  lastOption the last option position.
     *  begin the begin options position.
     *  end the end options position.
     *  whiteList eligible collateral address white list.
     */
    function calRangeSharedPayment(uint256 /*lastOption*/,uint256 /*begin*/,uint256 /*end*/,address[] memory /*whiteList*/)
            public view returns(int256[] memory,uint256[] memory,uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev calculate options payback fall value,from begin to end in the alloptionsList.
     *  lastOption the last option position.
     *  begin the begin options position.
     *  end the end options position.
     *  whiteList eligible collateral address white list.
     */
    function calculatePhaseOptionsFall(uint256 /*lastOption*/,uint256 /*begin*/,uint256 /*end*/,address[] memory /*whiteList*/) public view returns(int256[] memory){
        delegateToViewAndReturn();
    }

    /**
     * @dev retrieve all information for collateral occupied and net worth calculation.
     *  whiteList settlement address whitelist.
     */ 
    function getOptionCalRangeAll(address[] memory /*whiteList*/)public view returns(uint256,int256,int256,uint256,int256[] memory,uint256,uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev create new option,modify collateral occupied and net worth value, only manager contract can invoke this.
     *  from user's address.
     *  settlement user's input settlement coin.
     *  type_ly_exp tuple64 for option type,underlying,expiration.
     *  strikePrice user's input new option's strike price.
     *  optionPrice current new option's price, calculated by options price contract.
     *  amount user's input new option's amount.
     */ 
    function createOptions(address /*from*/,address /*settlement*/,uint256 /*type_ly_exp*/,
    uint128 /*strikePrice*/,uint128 /*underlyingPrice*/,uint128 /*amount*/,uint128 /*settlePrice*/) public returns(uint256) {
        delegateAndReturn();
    }
    /**
     * @dev burn option,modify collateral occupied and net worth value, only manager contract can invoke this.
     *  from user's address.
     *  id user's input option's id.
     *  amount user's input burned option's amount.
     *  optionPrice current new option's price, calculated by options price contract.
     */ 
    function burnOptions(address /*from*/,uint256 /*id*/,uint256 /*amount*/,uint256 /*optionPrice*/)public{
        delegateAndReturn();
    }
    function getUserAllOptionInfo(address /*user*/)public view 
        returns(address[] memory,uint256[] memory,uint256[] memory,uint256[] memory,uint256[] memory){
        delegateToViewAndReturn();
    }
}
