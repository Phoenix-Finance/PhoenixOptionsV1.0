pragma solidity =0.5.16;
import "./ManagerData.sol";
import "../Proxy/baseProxy.sol";
/**
 * @title  Erc20Delegator Contract

 */
contract ManagerProxy is ManagerData,baseProxy{
    /**
    * @dev Options manager constructor. set other contract address
    *  oracleAddr fnx oracle contract address.
    *  optionsPriceAddr options price contract address
    *  optionsPoolAddr optoins pool contract address
    *  FPTCoinAddr FPTCoin contract address
    */
    constructor(address implementation_,address oracleAddr,address optionsPriceAddr,
            address optionsPoolAddr,address collateralPoolAddr,address FPTCoinAddr)
         baseProxy(implementation_) public  {
        _oracle = IFNXOracle(oracleAddr);
        _optionsPrice = IOptionsPrice(optionsPriceAddr);
        _optionsPool = IOptionsPool(optionsPoolAddr);
        _collateralPool = ICollateralPool(collateralPoolAddr);
        _FPTCoin = IFPTCoin(FPTCoinAddr);
    }
    /**
     * @dev  The foundation owner want to set the minimum collateral occupation rate.
     *  collateral collateral coin address
     *  colRate The thousandths of the minimum collateral occupation rate.
     */
    function setCollateralRate(address /*collateral*/,uint256 /*colRate*/) public {
        delegateAndReturn();
    }
    /**
     * @dev Get the minimum collateral occupation rate.
     */
    function getCollateralRate(address /*collateral*/)public view returns (uint256) {
        delegateToViewAndReturn();
    }
    /**
     * @dev Retrieve user's cost of collateral, priced in USD.
     *  user input retrieved account 
     */
    function getUserPayingUsd(address /*user*/)public view returns (uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev Retrieve user's amount of the specified collateral.
     *  user input retrieved account 
     *  collateral input retrieved collateral coin address 
     */
    function userInputCollateral(address /*user*/,address /*collateral*/)public view returns (uint256){
        delegateToViewAndReturn();
    }

    /**
     * @dev Retrieve user's current total worth, priced in USD.
     *  account input retrieve account
     */
    function getUserTotalWorth(address /*account*/)public view returns (uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev Retrieve FPTCoin's net worth, priced in USD.
     */
    function getTokenNetworth() public view returns (uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev Deposit collateral in this pool from user.
     *  collateral The collateral coin address which is in whitelist.
     *  amount the amount of collateral to deposit.
     */
    function addCollateral(address /*collateral*/,uint256 /*amount*/) public payable {
        delegateAndReturn();
    }
    /**
     * @dev redeem collateral from this pool, user can input the prioritized collateral,he will get this coin,
     * if this coin is unsufficient, he will get others collateral which in whitelist.
     *  tokenAmount the amount of FPTCoin want to redeem.
     *  collateral The prioritized collateral coin address.
     */
    function redeemCollateral(uint256 /*tokenAmount*/,address /*collateral*/) public {
        delegateAndReturn();
    }
    /**
     * @dev Retrieve user's collateral worth in all collateral coin. 
     * If user want to redeem all his collateral,and the vacant collateral is sufficient,
     * He can redeem each collateral amount in return list.
     *  account the retrieve user's account;
     */
    function calCollateralWorth(address /*account*/)public view returns(uint256[] memory){
        delegateToViewAndReturn();
    }
    /**
     * @dev Retrieve the occupied collateral worth, multiplied by minimum collateral rate, priced in USD. 
     */
    function getOccupiedCollateral() public view returns(uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev Retrieve the available collateral worth, the worth of collateral which can used for buy options, priced in USD. 
     */
    function getAvailableCollateral()public view returns(uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev Retrieve the left collateral worth, the worth of collateral which can used for redeem collateral, priced in USD. 
     */
    function getLeftCollateral()public view returns(uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev Retrieve the unlocked collateral worth, the worth of collateral which currently used for options, priced in USD. 
     */
    function getUnlockedCollateral()public view returns(uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev The auxiliary function for calculate option occupied. 
     *  strikePrice option's strike price
     *  underlyingPrice option's underlying price
     *  amount option's amount
     *  optType option's type, 0 for call, 1 for put.
     */
    function calOptionsOccupied(uint256 /*strikePrice*/,uint256 /*underlyingPrice*/,uint256 /*amount*/,uint8 /*optType*/)public view returns(uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev Retrieve the total collateral worth, priced in USD. 
     */
    function getTotalCollateral()public view returns(uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev Retrieve the balance of collateral, the auxiliary function for the total collateral calculation. 
     */
    function getRealBalance(address /*settlement*/)public view returns(int256){
        delegateToViewAndReturn();
    }
    function getNetWorthBalance(address /*settlement*/)public view returns(uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev collateral occupation rate calculation
     *      collateral occupation rate = sum(collateral Rate * collateral balance) / sum(collateral balance)
     */
    function calculateCollateralRate()public view returns (uint256){
        delegateToViewAndReturn();
    }
    /**
    * @dev retrieve input price valid range rate, thousandths.
    */ 
    function getPriceRateRange() public view returns(uint256,uint256) {
        delegateToViewAndReturn();
    }
    /**
    * @dev set input price valid range rate, thousandths.
    */ 
    function setPriceRateRange(uint256 /*_minPriceRate*/,uint256 /*_maxPriceRate*/) public{
        delegateAndReturn();
    }
    /**
    * @dev user buy option and create new option.
    *  settlement user's settement coin address
    *  settlementAmount amount of settlement user want fo pay.
    *  strikePrice user input option's strike price
    *  underlying user input option's underlying id, 1 for BTC,2 for ETH
    *  expiration user input expiration,time limit from now
    *  amount user input amount of new option user want to buy.
    *  optType user input option type
    */ 
    function buyOption(address /*settlement*/,uint256 /*settlementAmount*/, uint256 /*strikePrice*/,uint32 /*underlying*/,
                uint256 /*expiration*/,uint256 /*amount*/,uint8 /*optType*/) public payable{
        delegateAndReturn();
    }
    /**
    * @dev User sell option.
    *  optionsId option's ID which was wanted to sell, must owned by user
    *  amount user input amount of option user want to sell.
    */ 
    function sellOption(uint256 /*optionsId*/,uint256 /*amount*/) public{
        delegateAndReturn();
    }
    /**
    * @dev User exercise option.
    *  optionsId option's ID which was wanted to exercise, must owned by user
    *  amount user input amount of option user want to exercise.
    */ 
    function exerciseOption(uint256 /*optionsId*/,uint256 /*amount*/) public{
        delegateAndReturn();
    }
    function getOptionsPrice(uint256 /*underlyingPrice*/, uint256 /*strikePrice*/, uint256 /*expiration*/,
                    uint32 /*underlying*/,uint256 /*amount*/,uint8 /*optType*/) public view returns(uint256){
        delegateToViewAndReturn();
    }
}
