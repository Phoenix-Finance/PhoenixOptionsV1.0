pragma solidity ^0.4.26;
import "./modules/SafeMath.sol";
import "./CollateralPool.sol";
import "./modules/whiteList.sol";
import "./interfaces/IOptionsPrice.sol";
contract OptionsMangerV2 is CollateralPool {
    using SafeMath for uint256;
    IOptionsPrice internal optionsPrice;
    function buyOption(address settlement,uint256 settlementAmount, uint256 strikePrice,uint32 underlying,
        uint256 expiration,uint256 amount,uint8 optType)public payable{
        optionsPool.buyOptionCheck(expiration,underlying);
        uint256 allPay = amount.mul(optionsPrice.getOptionsPrice(_oracle.getUnderlyingPrice(underlying),strikePrice,expiration,optType));
        buyOption_sub(settlement,settlementAmount,allPay);
        uint256 collateralNeed = optionsPool.createOptions(optType,underlying,now+expiration,strikePrice,amount,settlement);
        collateralNeed = calculateCollateral(collateralNeed);
        require(getLeftCollateral()>=collateralNeed,"collateral is insufficient!");
    }
    function buyOption_sub(address settlement,uint256 settlementAmount,uint256 allPay)internal{
        settlementAmount = getPayableAmount(settlement,settlementAmount);
        require(settlementAmount>0 , "settlement amount is zero!");
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
        optionsPool.burnOptions(optionsId,amount);
        (,,uint8 optType,uint32 underlying,uint256 expiration,uint256 strikePrice,) = optionsPool.getOptionsById(optionsId);
        expiration = optType-now;
        uint256 currentPrice = _oracle.getUnderlyingPrice(underlying);
        uint256 optPrice = optionsPrice.getOptionsPrice(currentPrice,strikePrice,expiration,optType);
        uint256 allPay = optPrice.mul(amount);
        _paybackWorth(allPay,sellFee);
    }
    function exerciseOption(uint256 optionsId,uint256 amount)public{
        require(amount>0 , "exercise amount is zero!");
        uint256 allPay = optionsPool.getExerciseWorth(optionsId,amount);
        if (allPay == 0) {
            return;
        }
        optionsPool.burnOptions(optionsId,amount);
        _paybackWorth(allPay,exerciseFee);
    }

}