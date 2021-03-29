pragma solidity =0.5.16;

import "../modules/SafeInt256.sol";
import "./TransactionFee.sol";
/**
 * @title collateral pool contract with coin and necessary storage data.
 * @dev A smart-contract which stores user's deposited collateral.
 *
 */
contract CollateralPool is TransactionFee{
    using SafeMath for uint256;
    using SafeInt256 for int256;
    constructor(address optionsPool)public{
        _optionsPool = IOptionsPool(optionsPool);
    }
    /**
     * @dev Transfer colleteral from manager contract to this contract.
     *  Only manager contract can invoke this function.
     */
    function () external payable onlyManager{

    }
    function initialize() onlyOwner public {
        TransactionFee.initialize();
    }
    function update() onlyOwner public{
    }
    /**
     * @dev An interface for add transaction fee.
     *  Only manager contract can invoke this function.
     * @param collateral collateral address, also is the coin for fee.
     * @param amount total transaction amount.
     * @param feeType transaction fee type. see TransactionFee contract
     */
    function addTransactionFee(address collateral,uint256 amount,uint256 feeType)public onlyManager returns (uint256) {
        uint256 fee = FeeRates[feeType]*amount/1000;
        _addTransactionFee(collateral,fee);
        return fee;
    }
    /**
     * @dev Retrieve user's cost of collateral, priced in USD.
     * @param user input retrieved account 
     */
    function getUserPayingUsd(address user)public view returns (uint256){
        return userCollateralPaying[user];
    }
    /**
     * @dev Retrieve user's amount of the specified collateral.
     * @param user input retrieved account 
     * @param collateral input retrieved collateral coin address 
     */
    function getUserInputCollateral(address user,address collateral)public view returns (uint256){
        return userInputCollateral[user][collateral];
    }

    /**
     * @dev Retrieve collateral balance data.
     * @param collateral input retrieved collateral coin address 
     */
    function getCollateralBalance(address collateral)public view returns (uint256){
        return collateralBalances[collateral];
    }
    /**
     * @dev Opterator user paying data, priced in USD. Only manager contract can modify database.
     * @param user input user account which need add paying amount.
     * @param amount the input paying amount.
     */
    function addUserPayingUsd(address user,uint256 amount)public onlyManager{
        userCollateralPaying[user] = userCollateralPaying[user].add(amount);
    }
    /**
     * @dev Opterator user input collateral data. Only manager contract can modify database.
     * @param user input user account which need add input collateral.
     * @param collateral the collateral address.
     * @param amount the input collateral amount.
     */
    function addUserInputCollateral(address user,address collateral,uint256 amount)public onlyManager{
        userInputCollateral[user][collateral] = userInputCollateral[user][collateral].add(amount);
        collateralBalances[collateral] = collateralBalances[collateral].add(amount);
        netWorthBalances[collateral] = netWorthBalances[collateral].add(int256(amount));
    }
    /**
     * @dev Opterator net worth balance data. Only manager contract can modify database.
     * @param whiteList available colleteral address list.
     * @param newNetworth collateral net worth list.
     */
    function addNetWorthBalances(address[] memory whiteList,int256[] memory newNetworth)internal{
        for (uint i=0;i<newNetworth.length;i++){
            netWorthBalances[whiteList[i]] = netWorthBalances[whiteList[i]].add(newNetworth[i]);
        }
    }
    /**
     * @dev Opterator net worth balance data. Only manager contract can modify database.
     * @param collateral available colleteral address.
     * @param amount collateral net worth increase amount.
     */
    function addNetWorthBalance(address collateral,int256 amount)public onlyManager{
        netWorthBalances[collateral] = netWorthBalances[collateral].add(amount);
    }
    /**
     * @dev Opterator collateral balance data. Only manager contract can modify database.
     * @param collateral available colleteral address.
     * @param amount collateral colleteral increase amount.
     */
    function addCollateralBalance(address collateral,uint256 amount)public onlyManager{
        collateralBalances[collateral] = collateralBalances[collateral].add(amount);
    }
    /**
     * @dev Substract user paying data,priced in USD. Only manager contract can modify database.
     * @param user user's account.
     * @param amount user's decrease amount.
     */
    function subUserPayingUsd(address user,uint256 amount)public onlyManager{
        userCollateralPaying[user] = userCollateralPaying[user].sub(amount);
    }
    /**
     * @dev Substract user's collateral balance. Only manager contract can modify database.
     * @param user user's account.
     * @param collateral collateral address.
     * @param amount user's decrease amount.
     */
    function subUserInputCollateral(address user,address collateral,uint256 amount)public onlyManager{
        userInputCollateral[user][collateral] = userInputCollateral[user][collateral].sub(amount);
    }
    /**
     * @dev Substract net worth balance. Only manager contract can modify database.
     * @param collateral collateral address.
     * @param amount the decrease amount.
     */
    function subNetWorthBalance(address collateral,int256 amount)public onlyManager{
        netWorthBalances[collateral] = netWorthBalances[collateral].sub(amount);
    }
    /**
     * @dev Substract collateral balance. Only manager contract can modify database.
     * @param collateral collateral address.
     * @param amount the decrease amount.
     */
    function subCollateralBalance(address collateral,uint256 amount)public onlyManager{
        collateralBalances[collateral] = collateralBalances[collateral].sub(amount);
    }
    /**
     * @dev set user paying data,priced in USD. Only manager contract can modify database.
     * @param user user's account.
     * @param amount user's new amount.
     */
    function setUserPayingUsd(address user,uint256 amount)public onlyManager{
        userCollateralPaying[user] = amount;
    }
    /**
     * @dev set user's collateral balance. Only manager contract can modify database.
     * @param user user's account.
     * @param collateral collateral address.
     * @param amount user's new amount.
     */
    function setUserInputCollateral(address user,address collateral,uint256 amount)public onlyManager{
        userInputCollateral[user][collateral] = amount;
    }
    /**
     * @dev set net worth balance. Only manager contract can modify database.
     * @param collateral collateral address.
     * @param amount the new amount.
     */
    function setNetWorthBalance(address collateral,int256 amount)public onlyManager{
        netWorthBalances[collateral] = amount;
    }
    /**
     * @dev set collateral balance. Only manager contract can modify database.
     * @param collateral collateral address.
     * @param amount the new amount.
     */
    function setCollateralBalance(address collateral,uint256 amount)public onlyManager{
        collateralBalances[collateral] = amount;
    }
    /**
     * @dev Operation for transfer user's payback and deduct transaction fee. Only manager contract can invoke this function.
     * @param recieptor the recieptor account.
     * @param settlement the settlement coin address.
     * @param payback the payback amount
     * @param feeType the transaction fee type. see transactionFee contract
     */
    function transferPaybackAndFee(address payable recieptor,address settlement,uint256 payback,
            uint256 feeType)public onlyManager{
        _transferPaybackAndFee(recieptor,settlement,payback,feeType);
        netWorthBalances[settlement] = netWorthBalances[settlement].sub(int256(payback));
    }
        /**
     * @dev Operation for transfer user's payback. Only manager contract can invoke this function.
     * @param recieptor the recieptor account.
     * @param allPay the payback amount
     */
    function buyOptionsPayfor(address payable recieptor,address settlement,uint256 settlementAmount,uint256 allPay)public onlyManager{
        uint256 fee = addTransactionFee(settlement,allPay,0);
        require(settlementAmount>=allPay+fee,"settlement asset is insufficient!");
        settlementAmount = settlementAmount-(allPay+fee);
        if (settlementAmount > 0){
            _transferPayback(recieptor,settlement,settlementAmount);
        }
    }
    /**
     * @dev Operation for transfer user's payback. Only manager contract can invoke this function.
     * @param recieptor the recieptor account.
     * @param settlement the settlement coin address.
     * @param payback the payback amount
     */
    function transferPayback(address payable recieptor,address settlement,uint256 payback)public onlyManager{
        _transferPayback(recieptor,settlement,payback);
    }
    /**
     * @dev Operation for transfer user's payback and deduct transaction fee for multiple settlement Coin.
     *       Specially used for redeem collateral.Only manager contract can invoke this function.
     * @param account the recieptor account.
     * @param redeemWorth the redeem worth, priced in USD.
     * @param tmpWhiteList the settlement coin white list
     * @param colBalances the Collateral balance based for user's input collateral.
     * @param PremiumBalances the premium collateral balance if redeem worth is exceeded user's input collateral.
     * @param prices the collateral prices list.
     */
    function transferPaybackBalances(address payable account,uint256 redeemWorth,address[] memory tmpWhiteList,uint256[] memory colBalances,
        uint256[] memory PremiumBalances,uint256[] memory prices)public onlyManager {
        uint256 ln = tmpWhiteList.length;
        uint256[] memory PaybackBalances = new uint256[](ln);
        uint256 i=0;
        uint256 amount;
        for(; i<ln && redeemWorth>0;i++){
            //address addr = tmpWhiteList[i];
            if (colBalances[i] > 0){
                amount = redeemWorth/prices[i];
                if (amount < colBalances[i]){
                    redeemWorth = 0;
                }else{
                    amount = colBalances[i];
                    redeemWorth = redeemWorth - colBalances[i]*prices[i];
                }
                PaybackBalances[i] = amount;
                amount = amount * userInputCollateral[account][tmpWhiteList[i]]/colBalances[i];
                userInputCollateral[account][tmpWhiteList[i]] =userInputCollateral[account][tmpWhiteList[i]].sub(amount);
                collateralBalances[tmpWhiteList[i]] = collateralBalances[tmpWhiteList[i]].sub(amount);

            }
        }
        if (redeemWorth>0) {
           amount = 0;
            for (i=0; i<ln;i++){
                amount = amount.add(PremiumBalances[i]*prices[i]);
            }
//            require(amount >= redeemWorth ,"redeem collateral is insufficient");
            if (amount<redeemWorth){
                amount = redeemWorth;
            }
            for (i=0; i<ln;i++){
                PaybackBalances[i] = PaybackBalances[i].add(PremiumBalances[i].mul(redeemWorth)/amount);
            }
        }
        for (i=0;i<ln;i++){ 
            transferPaybackAndFee(account,tmpWhiteList[i],PaybackBalances[i],redeemColFee);
        } 
    }
    /**
     * @dev calculate user's input collateral balance and premium collateral balance.
     *      Specially used for user's redeem collateral.
     * @param account the recieptor account.
     * @param userTotalWorth the user's total FPTCoin worth, priced in USD.
     * @param tmpWhiteList the settlement coin white list
     * @param _RealBalances the real Collateral balance.
     * @param prices the collateral prices list.
     */
    function getCollateralAndPremiumBalances(address account,uint256 userTotalWorth,address[] memory tmpWhiteList,
        uint256[] memory _RealBalances,uint256[] memory prices) public view returns(uint256[] memory,uint256[] memory){
//        uint256 ln = tmpWhiteList.length;
        uint256[] memory colBalances = new uint256[](tmpWhiteList.length);
        uint256[] memory PremiumBalances = new uint256[](tmpWhiteList.length);
        uint256 totalWorth = 0;
        uint256 PremiumWorth = 0;
        uint256 i=0;
        for(; i<tmpWhiteList.length;i++){
            (colBalances[i],PremiumBalances[i]) = calUserNetWorthBalanceRate(tmpWhiteList[i],account,_RealBalances[i]);
            totalWorth = totalWorth.add(prices[i]*colBalances[i]);
            PremiumWorth = PremiumWorth.add(prices[i]*PremiumBalances[i]);
        }
        if (totalWorth >= userTotalWorth){
            for (i=0; i<tmpWhiteList.length;i++){
                colBalances[i] = colBalances[i].mul(userTotalWorth)/totalWorth;
            }
        }else if (PremiumWorth>0){
            userTotalWorth = userTotalWorth - totalWorth;
            for (i=0; i<tmpWhiteList.length;i++){
                PremiumBalances[i] = PremiumBalances[i].mul(userTotalWorth)/PremiumWorth;
            }
        }
        return (colBalances,PremiumBalances);
    } 
    /**
     * @dev calculate user's input collateral balance.
     *      Specially used for user's redeem collateral.
     * @param settlement the settlement coin address.
     * @param user the recieptor account.
     * @param netWorthBalance the settlement coin real balance
     */
    function calUserNetWorthBalanceRate(address settlement,address user,uint256 netWorthBalance)internal view returns(uint256,uint256){
        uint256 collateralBalance = collateralBalances[settlement];
        uint256 amount = userInputCollateral[user][settlement];
        if (collateralBalance > 0){
            uint256 curAmount = netWorthBalance.mul(amount)/collateralBalance;
            return (curAmount,netWorthBalance.sub(curAmount));
        }else{
            return (0,netWorthBalance);
        }
    }
    function getAllRealBalance(address[] memory whiteList)public view returns(int256[] memory){
        uint256 len = whiteList.length;
        int256[] memory realBalances = new int256[](len); 
        for (uint i = 0;i<len;i++){
            int256 latestWorth = _optionsPool.getNetWrothLatestWorth(whiteList[i]);
            realBalances[i] = netWorthBalances[whiteList[i]].add(latestWorth);
        }
        return realBalances;
    }
        /**
     * @dev Retrieve the balance of collateral, the auxiliary function for the total collateral calculation. 
     */
    function getRealBalance(address settlement)public view returns(int256){
        int256 latestWorth = _optionsPool.getNetWrothLatestWorth(settlement);
        return netWorthBalances[settlement].add(latestWorth);
    }
    function getNetWorthBalance(address settlement)public view returns(uint256){
        int256 latestWorth = _optionsPool.getNetWrothLatestWorth(settlement);
        int256 netWorth = netWorthBalances[settlement].add(latestWorth);
        if (netWorth>0){
            return uint256(netWorth);
        }
        return 0;
    }
        /**
     * @dev  The foundation operator want to add some coin to netbalance, which can increase the FPTCoin net worth.
     * @param settlement the settlement coin address which the foundation operator want to transfer in this contract address.
     * @param amount the amount of the settlement coin which the foundation operator want to transfer in this contract address.
     */
    function addNetBalance(address settlement,uint256 amount) public payable {
        amount = getPayableAmount(settlement,amount);
        netWorthBalances[settlement] = netWorthBalances[settlement].add(int256(amount));
    }
        /**
     * @dev the auxiliary function for getting user's transer
     */
    function getPayableAmount(address settlement,uint256 settlementAmount) internal returns (uint256) {
        if (settlement == address(0)){
            settlementAmount = msg.value;
        }else if (settlementAmount > 0){
            IERC20 oToken = IERC20(settlement);
            uint256 preBalance = oToken.balanceOf(address(this));
            oToken.transferFrom(msg.sender, address(this), settlementAmount);
            uint256 afterBalance = oToken.balanceOf(address(this));
            require(afterBalance-preBalance==settlementAmount,"settlement token transfer error!");
        }
        return settlementAmount;
    }
        /**
     * @dev Calculate the collateral pool shared worth.
     * The foundation operator will invoke this function frequently
     */
    function calSharedPayment(address[] memory _whiteList) public onlyOperatorIndex(0) {
        (uint256 firstOption,int256[] memory latestShared) = _optionsPool.getNetWrothCalInfo(_whiteList);
        uint256 lastOption = _optionsPool.getOptionInfoLength();
        (int256[] memory newNetworth,uint256[] memory sharedBalance,uint256 newFirst) =
                     _optionsPool.calRangeSharedPayment(lastOption,firstOption,lastOption,_whiteList);
        int256[] memory fallBalance = _optionsPool.calculatePhaseOptionsFall(lastOption,newFirst,lastOption,_whiteList);
        for (uint256 i= 0;i<fallBalance.length;i++){
            fallBalance[i] = int256(sharedBalance[i]).sub(latestShared[i]).add(fallBalance[i]);
        }
        setSharedPayment(_whiteList,newNetworth,fallBalance,newFirst);
    }
    /**
     * @dev Set the calculation results of the collateral pool shared worth.
     * The foundation operator will invoke this function frequently
     * @param newNetworth Current expired options' net worth 
     * @param sharedBalances All unexpired options' shared balance distributed by time.
     * @param firstOption The new first unexpired option's index.
     */
    function setSharedPayment(address[] memory _whiteList,int256[] memory newNetworth,int256[] memory sharedBalances,uint256 firstOption) public onlyOperatorIndex(0){
        _optionsPool.setSharedState(firstOption,sharedBalances,_whiteList);
        addNetWorthBalances(_whiteList,newNetworth);
    }
}