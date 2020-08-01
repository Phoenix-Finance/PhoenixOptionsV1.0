pragma solidity ^0.4.26;
import "./modules/SafeMath.sol";
import "./CollateralCal.sol";
import "./modules/whiteList.sol";
import "./interfaces/IOptionsPrice.sol";
import "./modules/tuple.sol";
contract OptionsManagerV2 is CollateralCal,ImportOptionsPrice {
    using SafeMath for uint256;
    constructor (address oracleAddr,address optionsPriceAddr,address optionsPoolAddr,address collateralPoolAddr,address FPTCoinAddr) public{
        setOracleAddress(oracleAddr);
        setOptionsPriceAddress(optionsPriceAddr);
        setOptionsPoolAddress(optionsPoolAddr);
        setFPTCoinAddress(FPTCoinAddr);
        setCollateralPoolAddress(collateralPoolAddr);
    }

    event BuyOption(address indexed from,address indexed settlement,uint256 indexed optionId,uint256 optionPrice,uint256 settlementAmount,uint256 optionAmount);
    event SellOption(address indexed from,uint256 indexed optionId,uint256 amount,uint256 sellValue);
    event ExerciseOption(address indexed from,uint256 indexed optionId,uint256 amount,uint256 sellValue);
    event DebugEvent(uint256 value0,uint256 value1,uint256 value2,uint256 value3);
    function buyOption(address settlement,uint256 settlementAmount, uint256 strikePrice,uint32 underlying,
                uint256 expiration,uint256 amount,uint8 optType) nonReentrant notHalted public payable{
        _optionsPool.buyOptionCheck(expiration,underlying);
        uint256 ty_ly_exp = tuple64.getTuple(uint256(optType),uint256(underlying),uint256(expiration),0);
        uint256 underlyingPrice = _oracle.getUnderlyingPrice(underlying);
        uint256 optionPrice = _optionsPrice.getOptionsPrice(underlyingPrice,strikePrice,expiration,underlying,optType); 
        require(getAvailableCollateral()>=calOptionsOccupied(strikePrice,underlyingPrice,amount,optType),"collateral is insufficient!");
        _optionsPool.createOptions(msg.sender,settlement,ty_ly_exp,strikePrice,optionPrice,amount);
        buyOption_sub(settlement,settlementAmount,optionPrice,amount);
    }
    function buyOption_sub(address settlement,uint256 settlementAmount,
            uint256 optionPrice,uint256 amount)internal{
        
        uint256 allPay = amount.mul(optionPrice);
        settlementAmount = getPayableAmount(settlement,settlementAmount);
        require(settlementAmount>0 , "settlement amount is zero!");
        uint256 fee = calculateFee(buyFee,allPay);
        uint256 settlePrice = _oracle.getPrice(settlement);
        require(settlePrice.mul(settlementAmount)>=allPay.add(fee),"settlement asset is insufficient!");
        uint256 allPayUSd = allPay.div(1e8);
        allPay = allPay.div(settlePrice);
        fee = fee.div(settlePrice);
        _addTransactionFee(settlement,fee);
        settlementAmount = settlementAmount.sub(allPay).sub(fee);
        if (settlementAmount > 0){
            _collateralPool.transferPayback(msg.sender,settlement,settlementAmount);
        }
        uint256 id =_optionsPool.getOptionInfoLength();
        _FPTCoin.addMinerBalance(msg.sender,allPayUSd);
        emit BuyOption(msg.sender,settlement,id,optionPrice,allPay,amount); 
    }
    function sellOption(uint256 optionsId,uint256 amount) nonReentrant notHalted public{
        require(amount>0 , "sell amount is zero!");
        _optionsPool.burnOptions(msg.sender,optionsId,amount);
        (,,uint8 optType,uint32 underlying,uint256 expiration,uint256 strikePrice,) = _optionsPool.getOptionsById(optionsId);
        expiration = expiration.sub(now);
        uint256 currentPrice = _oracle.getUnderlyingPrice(underlying);
        uint256 optPrice = _optionsPrice.getOptionsPrice(currentPrice,strikePrice,expiration,underlying,optType);
        uint256 allPay = optPrice.mul(amount);
        emit SellOption(msg.sender,optionsId,amount,allPay);
        _paybackWorth(allPay,sellFee);
    }
    function exerciseOption(uint256 optionsId,uint256 amount) nonReentrant notHalted public{
        require(amount>0 , "exercise amount is zero!");
        uint256 allPay = _optionsPool.getExerciseWorth(optionsId,amount);
        if (allPay == 0) {
            return;
        }
        _optionsPool.burnOptions(msg.sender,optionsId,amount);
        emit ExerciseOption(msg.sender,optionsId,amount,allPay);
        _paybackWorth(allPay,exerciseFee);
    }

}