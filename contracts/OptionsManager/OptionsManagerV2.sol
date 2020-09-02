pragma solidity ^0.5.1;
import "../modules/SafeMath.sol";
import "./CollateralCal.sol";
import "../modules/tuple64.sol";
/**
 * @title Options manager contract for finnexus proposal v2.
 * @dev A Smart-contract to manage Options pool, collatral pool, mine pool, FPTCoin, etc.
 *
 */
contract OptionsManagerV2 is CollateralCal {
    using SafeMath for uint256;

    /**
    * @dev Options manager constructor. set other contract address
    * @param oracleAddr fnx oracle contract address.
    * @param optionsPriceAddr options price contract address
    * @param optionsPoolAddr optoins pool contract address
    * @param FPTCoinAddr FPTCoin contract address
    */
    constructor (address oracleAddr,address optionsPriceAddr,address optionsPoolAddr,address collateralPoolAddr,address FPTCoinAddr) public{
        _oracle = IFNXOracle(oracleAddr);
        _optionsPrice = IOptionsPrice(optionsPriceAddr);
        _optionsPool = IOptionsPool(optionsPoolAddr);
        _collateralPool = ICollateralPool(collateralPoolAddr);
        _FPTCoin = IFPTCoin(FPTCoinAddr);
    }
    function initialize() public {
        
    }
    /**
    * @dev retrieve input price valid range rate, thousandths.
    */ 
    function getPriceRateRange() public view returns(uint256,uint256) {
        return (minPriceRate,maxPriceRate);
    }
    /**
    * @dev set input price valid range rate, thousandths.
    */ 
    function setPriceRateRange(uint256 _minPriceRate,uint256 _maxPriceRate) public onlyOwner{
        minPriceRate = _minPriceRate;
        maxPriceRate = _maxPriceRate;
    }
    /**
    * @dev check user input price is in valid range.
    * @param strikePrice user input strikePrice
    * @param underlyingPrice current underlying price.
    */ 
    function checkStrikePrice(uint256 strikePrice,uint256 underlyingPrice)internal view{
        require(underlyingPrice*maxPriceRate/1000>=strikePrice && underlyingPrice*minPriceRate/1000<=strikePrice,
                "strikePrice is out of price range");
    }
    /**
    * @dev user buy option and create new option.
    * @param settlement user's settement coin address
    * @param settlementAmount amount of settlement user want fo pay.
    * @param strikePrice user input option's strike price
    * @param underlying user input option's underlying id, 1 for BTC,2 for ETH
    * @param expiration user input expiration,time limit from now
    * @param amount user input amount of new option user want to buy.
    * @param optType user input option type
    */ 
    function buyOption(address settlement,uint256 settlementAmount, uint256 strikePrice,uint32 underlying,
                uint256 expiration,uint256 amount,uint8 optType) nonReentrant notHalted public payable{
        _optionsPool.buyOptionCheck(expiration,underlying);
        uint256 ty_ly_exp = tuple64.getTuple(uint256(optType),uint256(underlying),uint256(expiration),0);
        uint256 underlyingPrice = _oracle.getUnderlyingPrice(underlying);
        checkStrikePrice(strikePrice,underlyingPrice);
        uint256 optionPrice = _optionsPrice.getOptionsPrice(underlyingPrice,strikePrice,expiration,underlying,optType); 
        require(getAvailableCollateral()>=calOptionsOccupied(strikePrice,underlyingPrice,amount,optType),"collateral is insufficient!");
        _optionsPool.createOptions(msg.sender,settlement,ty_ly_exp,strikePrice,optionPrice,amount);
        buyOption_sub(settlement,settlementAmount,optionPrice,amount);
    }
    /**
    * @dev subfunction of buy option.
    * @param settlement user's settement coin address
    * @param settlementAmount amount of settlement user want fo pay.
    * @param optionPrice new option's price
    * @param amount user input amount of new option user want to buy.
    */ 
    function buyOption_sub(address settlement,uint256 settlementAmount,
            uint256 optionPrice,uint256 amount)internal{
        settlementAmount = getPayableAmount(settlement,settlementAmount);
        uint256 settlePrice = _oracle.getPrice(settlement);
        uint256 allPay = amount*optionPrice;
        uint256 allPayUSd = allPay/1e8;
        allPay = allPay/settlePrice;
        uint256 fee = _collateralPool.addTransactionFee(settlement,allPay,0);
        require(settlementAmount>=allPay+fee,"settlement asset is insufficient!");
        settlementAmount = settlementAmount.sub(allPay+fee);
        if (settlementAmount > 0){
            _collateralPool.transferPayback(msg.sender,settlement,settlementAmount);
        }
        uint256 id =_optionsPool.getOptionInfoLength();
        _FPTCoin.addMinerBalance(msg.sender,allPayUSd);
        emit BuyOption(msg.sender,settlement,id,optionPrice,allPay,amount); 
    }
    /**
    * @dev User sell option.
    * @param optionsId option's ID which was wanted to sell, must owned by user
    * @param amount user input amount of option user want to sell.
    */ 
    function sellOption(uint256 optionsId,uint256 amount) nonReentrant notHalted public{
        checkInputAmount(amount);
        (,,uint8 optType,uint32 underlying,uint256 expiration,uint256 strikePrice,) = _optionsPool.getOptionsById(optionsId);
        expiration = expiration.sub(now);
        uint256 currentPrice = _oracle.getUnderlyingPrice(underlying);
        uint256 optPrice = _optionsPrice.getOptionsPrice(currentPrice,strikePrice,expiration,underlying,optType);
        _optionsPool.burnOptions(msg.sender,optionsId,amount,optPrice);
        uint256 allPay = optPrice*amount;
        (address settlement,uint256 fullPay) = _optionsPool.getBurnedFullPay(optionsId,amount);
        _collateralPool.addNetWorthBalance(settlement,int256(fullPay));
        _paybackWorth(allPay,1);
        emit SellOption(msg.sender,optionsId,amount,allPay);
    }
    /**
    * @dev User exercise option.
    * @param optionsId option's ID which was wanted to exercise, must owned by user
    * @param amount user input amount of option user want to exercise.
    */ 
    function exerciseOption(uint256 optionsId,uint256 amount) nonReentrant notHalted public{
        checkInputAmount(amount);
        uint256 allPay = _optionsPool.getExerciseWorth(optionsId,amount);
        require(allPay > 0,"This option cannot exercise");
        (,,uint8 optType,uint32 underlying,uint256 expiration,uint256 strikePrice,) = _optionsPool.getOptionsById(optionsId);
        expiration = expiration.sub(now);
        uint256 currentPrice = _oracle.getUnderlyingPrice(underlying);
        uint256 optPrice = _optionsPrice.getOptionsPrice(currentPrice,strikePrice,expiration,underlying,optType);
        _optionsPool.burnOptions(msg.sender,optionsId,amount,optPrice);
        (address settlement,uint256 fullPay) = _optionsPool.getBurnedFullPay(optionsId,amount);
        _collateralPool.addNetWorthBalance(settlement,int256(fullPay));
        _paybackWorth(allPay,2);
        emit ExerciseOption(msg.sender,optionsId,amount,allPay);
    }
}