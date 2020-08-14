pragma solidity ^0.4.26;
import "./modules/SafeMath.sol";
import "./CollateralCal.sol";
import "./interfaces/IOptionsPrice.sol";
import "./modules/tuple64.sol";
contract OptionsManagerV2 is CollateralCal,ImportOptionsPrice {
    using SafeMath for uint256;

    constructor (address oracleAddr,address optionsPriceAddr,address optionsPoolAddr,address collateralPoolAddr,address FPTCoinAddr) public{
        _oracle = IFNXOracle(oracleAddr);
        _optionsPrice = IOptionsPrice(optionsPriceAddr);
        _optionsPool = IOptionsPool(optionsPoolAddr);
        _collateralPool = ICollateralPool(collateralPoolAddr);
        _FPTCoin = IFPTCoin(FPTCoinAddr);
    }

    uint256 internal maxPriceRate = 1500;
    uint256 internal minPriceRate = 500;
    function getPriceRateRange() public view returns(uint256,uint256) {
        return (minPriceRate,maxPriceRate);
    }
    function setPriceRateRange(uint256 _minPriceRate,uint256 _maxPriceRate) public onlyOwner{
        minPriceRate = _minPriceRate;
        maxPriceRate = _maxPriceRate;
    }
    function checkStrikePrice(uint256 strikePrice,uint256 underlyingPrice)internal view{
        require(underlyingPrice*maxPriceRate/1000>=strikePrice && underlyingPrice*minPriceRate/1000<=strikePrice,
                "strikePrice is out of price range");
    }
    event BuyOption(address indexed from,address indexed settlement,uint256 indexed optionId,uint256 optionPrice,uint256 settlementAmount,uint256 optionAmount);
    event SellOption(address indexed from,uint256 indexed optionId,uint256 amount,uint256 sellValue);
    event ExerciseOption(address indexed from,uint256 indexed optionId,uint256 amount,uint256 sellValue);
    function buyOption(address settlement,uint256 settlementAmount, uint256 strikePrice,uint32 underlying,
                uint256 expiration,uint256 amount,uint8 optType) nonReentrant notHalted public payable{
        require(optType<2," Must input 0 for call option or 1 for put option");
        _optionsPool.buyOptionCheck(expiration,underlying);
        uint256 ty_ly_exp = tuple64.getTuple(uint256(optType),uint256(underlying),uint256(expiration),0);
        uint256 underlyingPrice = _oracle.getUnderlyingPrice(underlying);
        checkStrikePrice(strikePrice,underlyingPrice);
        uint256 optionPrice = _optionsPrice.getOptionsPrice(underlyingPrice,strikePrice,expiration,underlying,optType); 
        require(getAvailableCollateral()>=calOptionsOccupied(strikePrice,underlyingPrice,amount,optType),"collateral is insufficient!");
        _optionsPool.createOptions(msg.sender,settlement,ty_ly_exp,strikePrice,optionPrice,amount);
        buyOption_sub(settlement,settlementAmount,optionPrice,amount);
    }

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
    function exerciseOption(uint256 optionsId,uint256 amount) nonReentrant notHalted public{
        checkInputAmount(amount);
        uint256 allPay = _optionsPool.getExerciseWorth(optionsId,amount);
        if (allPay == 0) {
            return;
        }
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