pragma solidity =0.5.16;
import "./CollateralData.sol";
import "../Proxy/baseProxy.sol";
/**
 * @title  Erc20Delegator Contract

 */
contract CollateralProxy is CollateralData,baseProxy{
        /**
     * @dev constructor function , setting contract address.
     *  oracleAddr FNX oracle contract address
     *  optionsPriceAddr options price contract address
     *  ivAddress implied volatility contract address
     */  

    constructor(address implementation_,address optionsPool)
         baseProxy(implementation_) public  {
        _optionsPool = IOptionsPool(optionsPool);
    }
        /**
     * @dev Transfer colleteral from manager contract to this contract.
     *  Only manager contract can invoke this function.
     */
    function () external payable onlyManager{

    }
    function getFeeRateAll()public view returns (uint32[] memory){
        delegateToViewAndReturn();
    }
    function getFeeRate(uint256 /*feeType*/)public view returns (uint32){
        delegateToViewAndReturn();
    }
    /**
     * @dev set the rate of trasaction fee.
     *  feeType the transaction fee type
     *  numerator the numerator of transaction fee .
     *  denominator thedenominator of transaction fee.
     * transaction fee = numerator/denominator;
     */   
    function setTransactionFee(uint256 /*feeType*/,uint32 /*thousandth*/)public{
        delegateAndReturn();
    }

    function getFeeBalance(address /*settlement*/)public view returns(uint256){
        delegateToViewAndReturn();
    }
    function getAllFeeBalances()public view returns(address[] memory,uint256[] memory){
        delegateToViewAndReturn();
    }
    function redeem(address /*currency*/)public{
        delegateAndReturn();
    }
    function redeemAll()public{
        delegateAndReturn();
    }
    function calculateFee(uint256 /*feeType*/,uint256 /*amount*/)public view returns (uint256){
        delegateToViewAndReturn();
    }
        /**
     * @dev An interface for add transaction fee.
     *  Only manager contract can invoke this function.
     *  collateral collateral address, also is the coin for fee.
     *  amount total transaction amount.
     *  feeType transaction fee type. see TransactionFee contract
     */
    function addTransactionFee(address /*collateral*/,uint256 /*amount*/,uint256 /*feeType*/)public returns (uint256) {
        delegateAndReturn();
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
    function getUserInputCollateral(address /*user*/,address /*collateral*/)public view returns (uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev Retrieve collateral balance data.
     *  collateral input retrieved collateral coin address 
     */
    function getCollateralBalance(address /*collateral*/)public view returns (uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev Opterator user paying data, priced in USD. Only manager contract can modify database.
     *  user input user account which need add paying amount.
     *  amount the input paying amount.
     */
    function addUserPayingUsd(address /*user*/,uint256 /*amount*/)public{
        delegateAndReturn();
    }
    /**
     * @dev Opterator user input collateral data. Only manager contract can modify database.
     *  user input user account which need add input collateral.
     *  collateral the collateral address.
     *  amount the input collateral amount.
     */
    function addUserInputCollateral(address /*user*/,address /*collateral*/,uint256 /*amount*/)public{
        delegateAndReturn();
    }
    /**
     * @dev Opterator net worth balance data. Only manager contract can modify database.
     *  collateral available colleteral address.
     *  amount collateral net worth increase amount.
     */
    function addNetWorthBalance(address /*collateral*/,int256 /*amount*/)public{
        delegateAndReturn();
    }
    /**
     * @dev Opterator collateral balance data. Only manager contract can modify database.
     *  collateral available colleteral address.
     *  amount collateral colleteral increase amount.
     */
    function addCollateralBalance(address /*collateral*/,uint256 /*amount*/)public{
        delegateAndReturn();
    }
    /**
     * @dev Substract user paying data,priced in USD. Only manager contract can modify database.
     *  user user's account.
     *  amount user's decrease amount.
     */
    function subUserPayingUsd(address /*user*/,uint256 /*amount*/)public{
        delegateAndReturn();
    }
    /**
     * @dev Substract user's collateral balance. Only manager contract can modify database.
     *  user user's account.
     *  collateral collateral address.
     *  amount user's decrease amount.
     */
    function subUserInputCollateral(address /*user*/,address /*collateral*/,uint256 /*amount*/)public{
        delegateAndReturn();
    }
    /**
     * @dev Substract net worth balance. Only manager contract can modify database.
     *  collateral collateral address.
     *  amount the decrease amount.
     */
    function subNetWorthBalance(address /*collateral*/,int256 /*amount*/)public{
        delegateAndReturn();
    }
    /**
     * @dev Substract collateral balance. Only manager contract can modify database.
     *  collateral collateral address.
     *  amount the decrease amount.
     */
    function subCollateralBalance(address /*collateral*/,uint256 /*amount*/)public{
        delegateAndReturn();
    }
    /**
     * @dev set user paying data,priced in USD. Only manager contract can modify database.
     *  user user's account.
     *  amount user's new amount.
     */
    function setUserPayingUsd(address /*user*/,uint256 /*amount*/)public{
        delegateAndReturn();
    }
    /**
     * @dev set user's collateral balance. Only manager contract can modify database.
     *  user user's account.
     *  collateral collateral address.
     *  amount user's new amount.
     */
    function setUserInputCollateral(address /*user*/,address /*collateral*/,uint256 /*amount*/)public{
        delegateAndReturn();
    }
    /**
     * @dev set net worth balance. Only manager contract can modify database.
     *  collateral collateral address.
     *  amount the new amount.
     */
    function setNetWorthBalance(address /*collateral*/,int256 /*amount*/)public{
        delegateAndReturn();
    }
    /**
     * @dev set collateral balance. Only manager contract can modify database.
     *  collateral collateral address.
     *  amount the new amount.
     */
    function setCollateralBalance(address /*collateral*/,uint256 /*amount*/)public{
        delegateAndReturn();
    }
    /**
     * @dev Operation for transfer user's payback and deduct transaction fee. Only manager contract can invoke this function.
     *  recieptor the recieptor account.
     *  settlement the settlement coin address.
     *  payback the payback amount
     *  feeType the transaction fee type. see transactionFee contract
     */
    function transferPaybackAndFee(address payable /*recieptor*/,address /*settlement*/,uint256 /*payback*/,
            uint256 /*feeType*/)public{
        delegateAndReturn();
    }
    function buyOptionsPayfor(address payable /*recieptor*/,address /*settlement*/,uint256 /*settlementAmount*/,uint256 /*allPay*/)public onlyManager{
        delegateAndReturn();
    }
    /**
     * @dev Operation for transfer user's payback. Only manager contract can invoke this function.
     *  recieptor the recieptor account.
     *  settlement the settlement coin address.
     *  payback the payback amount
     */
    function transferPayback(address payable /*recieptor*/,address /*settlement*/,uint256 /*payback*/)public{
        delegateAndReturn();
    }
    /**
     * @dev Operation for transfer user's payback and deduct transaction fee for multiple settlement Coin.
     *       Specially used for redeem collateral.Only manager contract can invoke this function.
     *  account the recieptor account.
     *  redeemWorth the redeem worth, priced in USD.
     *  tmpWhiteList the settlement coin white list
     *  colBalances the Collateral balance based for user's input collateral.
     *  PremiumBalances the premium collateral balance if redeem worth is exceeded user's input collateral.
     *  prices the collateral prices list.
     */
    function transferPaybackBalances(address payable /*account*/,uint256 /*redeemWorth*/,
            address[] memory /*tmpWhiteList*/,uint256[] memory /*colBalances*/,
            uint256[] memory /*PremiumBalances*/,uint256[] memory /*prices*/)public {
            delegateAndReturn();
    }
    /**
     * @dev calculate user's input collateral balance and premium collateral balance.
     *      Specially used for user's redeem collateral.
     *  account the recieptor account.
     *  userTotalWorth the user's total FPTCoin worth, priced in USD.
     *  tmpWhiteList the settlement coin white list
     *  _RealBalances the real Collateral balance.
     *  prices the collateral prices list.
     */
    function getCollateralAndPremiumBalances(address /*account*/,uint256 /*userTotalWorth*/,address[] memory /*tmpWhiteList*/,
        uint256[] memory /*_RealBalances*/,uint256[] memory /*prices*/) public view returns(uint256[] memory,uint256[] memory){
            delegateToViewAndReturn();
    } 
    function getAllRealBalance(address[] memory /*whiteList*/)public view returns(int256[] memory){
        delegateToViewAndReturn();
    }
    function getRealBalance(address /*settlement*/)public view returns(int256){
        delegateToViewAndReturn();
    }
    function getNetWorthBalance(address /*settlement*/)public view returns(uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev  The foundation operator want to add some coin to netbalance, which can increase the FPTCoin net worth.
     *  settlement the settlement coin address which the foundation operator want to transfer in this contract address.
     *  amount the amount of the settlement coin which the foundation operator want to transfer in this contract address.
     */
    function addNetBalance(address /*settlement*/,uint256 /*amount*/) public payable{
        delegateAndReturn();
    }
    /**
     * @dev Calculate the collateral pool shared worth.
     * The foundation operator will invoke this function frequently
     */
    function calSharedPayment(address[] memory /*_whiteList*/) public{
        delegateAndReturn();
    }
    /**
     * @dev Set the calculation results of the collateral pool shared worth.
     * The foundation operator will invoke this function frequently
     *  newNetworth Current expired options' net worth 
     *  sharedBalances All unexpired options' shared balance distributed by time.
     *  firstOption The new first unexpired option's index.
     */
    function setSharedPayment(address[] memory /*_whiteList*/,int256[] memory /*newNetworth*/,
            int256[] memory /*sharedBalances*/,uint256 /*firstOption*/) public{
        delegateAndReturn();
    }

}
