pragma solidity ^0.4.26;
import "./SafeMath.sol";
import "./CollateralPool.sol";
import "./IOptionsPrice.sol";
import "./whiteList.sol";
contract OptionsMangerV2 is CollateralPool {
    using SafeMath for uint256;
    uint256[] public expirationList;
    IOptionsPrice internal optionsPrice;
    function getOptionsPriceAddress() public view returns(address){
        return address(optionsPrice);
    }
    function setOptionsPriceAddress(address options)public onlyOwner{
        optionsPrice = IOptionsPrice(options);
    }

    function buyOption(address settlement,uint256 settlementAmount, uint256 strikePrice,uint32 underlying,
        uint256 expiration,uint256 amount,uint8 optType)public payable{
        checkExpiration(expiration);
        require(isEligibleUnderlyingAsset(underlying) , "underlying is unsupported asset");
        uint256 underlyingPrice =  _oracle.getUnderlyingPrice(underlying);
        uint256 allPay = amount.mul(optionsPrice.getOptionsPrice(underlyingPrice,strikePrice,expiration,optType));
        buyOption_sub(settlement,settlementAmount,allPay);
        (int256 ivNumerator,int256 ivDenominator) = optionsPrice.getIV();
        OptionsInfo storage info = _createOptions(optType,underlying,now+expiration,strikePrice,
                    amount,ivNumerator,ivDenominator);
        uint256 collateralNeed = calculateCollateral(calOptionsCollateral(info,underlyingPrice));
        require(getLeftCollateral()>=collateralNeed,"collateral is insufficient!");
    }
    function buyOption_sub(address settlement,uint256 settlementAmount,uint256 allPay)internal{
        settlementAmount = getPayableAmount(settlement,settlementAmount);
        require(settlementAmount>0 , "settlement amount is zero!");
        uint256 buyFee = 0;
        uint256 fee = calculateFee(buyFee,allPay);
        uint256 settlePrice = _oracle.getPrice(settlement);
        require(settlePrice.mul(settlementAmount)>=allPay.add(fee),"settlement asset is insufficient!");
        allPay = allPay.div(settlePrice);
        fee = fee.div(settlePrice);
        _addTransactionFee(settlement,fee);
        settlementAmount = settlementAmount.sub(allPay).sub(fee);
        if (settlementAmount > 0){
            _transferPayback(msg.sender,settlement,settlementAmount);
        }  
    }
    function sellOption(uint256 optionsId,uint256 amount)public{
        require(amount>0 , "sell amount is zero!");
        burnOptions(optionsId,amount);
        OptionsInfo storage info = _getOptionsById(optionsId);
        uint256 expiration = info.expiration-now;
        uint256 currentPrice = _oracle.getUnderlyingPrice(info.underlying);
        uint256 optPrice = optionsPrice.getOptionsPrice(currentPrice,info.strikePrice,expiration,info.optType);
        uint256 sellFee = 1;
        uint256 allPay = optPrice.mul(amount);
        paybackSeller(allPay,sellFee);
    }
    function exerciseOption(uint256 optionsId,uint256 amount)public{
        require(amount>0 , "exercise amount is zero!");
        uint256 allPay = getExerciseWorth(optionsId,amount);
        uint256 exerciseFee = 2;
        if (allPay == 0) {
            return;
        }
        burnOptions(optionsId,amount);
        paybackSeller(allPay,exerciseFee);
    }
    function paybackSeller(uint256 worth,uint256 feeType) internal{
        worth = _paybackWorth_sub(eBalance.premium,worth,feeType);
        _paybackWorth_sub(eBalance.collateral,worth,feeType);
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
        return whiteListUint256.checkEligibleUint256(expirationList,expiration);
    }
    function _getEligibleExpirationIndex(uint256 expiration) internal view returns (uint256){
        return whiteListUint256._getEligibleIndexUint256(expirationList,expiration);
    }
}