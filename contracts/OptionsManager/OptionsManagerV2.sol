pragma solidity =0.5.16;
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
    function initialize() onlyOwner public {
        
    }
    function update() onlyOwner public {
        
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
        require(_minPriceRate<_maxPriceRate,"minimum Price rate must be smaller than maximum price rate");
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
                uint32 expiration,uint256 amount,uint8 optType) nonReentrant notHalted
                 InRange(amount) public payable{
        uint256 type_ly_expiration = optType+(uint256(underlying)<<64)+(uint256(expiration)<<128);
        (uint256 settlePrice,uint256 underlyingPrice) = oracleAssetAndUnderlyingPrice(settlement,underlying);
        checkStrikePrice(strikePrice,underlyingPrice);
        uint256 optRate = _getOptionsPriceRate(underlyingPrice,strikePrice,amount,optType);

        uint256 optPrice = _optionsPool.createOptions(msg.sender,settlement,type_ly_expiration,
            uint128(strikePrice),uint128(underlyingPrice),uint128(amount),uint128((settlePrice<<32)/optRate));
        optPrice = (optPrice*optRate)>>32;
        buyOption_sub(settlement,settlementAmount,optPrice,settlePrice,amount);
    }
    /**
    * @dev subfunction of buy option.
    * @param settlement user's settement coin address
    * @param settlementAmount amount of settlement user want fo pay.
    * @param optionPrice new option's price
    * @param amount user input amount of new option user want to buy.
    */ 
    function buyOption_sub(address settlement,uint256 settlementAmount,
            uint256 optionPrice,uint256 settlePrice,uint256 amount) 
            addressPermissionAllowed(settlement,allowBuyOptions) internal{
        settlementAmount = getPayableAmount(settlement,settlementAmount);
        amount = uint256(uint128(amount));
        uint256 allPay = amount*optionPrice;
        uint256 allPayUSd = allPay/1e8;
        allPay = allPay/settlePrice;
        _collateralPool.buyOptionsPayfor(msg.sender,settlement,settlementAmount,allPay);
        //_FPTCoin.addMinerBalance(msg.sender,allPayUSd);
        emit BuyOption(msg.sender,settlement,optionPrice,allPay,amount); 
    }
    /**
    * @dev User sell option.
    * @param optionsId option's ID which was wanted to sell, must owned by user
    * @param amount user input amount of option user want to sell.
    */ 
    function sellOption(uint256 optionsId,uint256 amount) nonReentrant notHalted InRange(amount) public{
        require(false,"sellOption is not supported");
        // (,,uint8 optType,uint32 underlying,uint256 expiration,uint256 strikePrice,) = _optionsPool.getOptionsById(optionsId);
        // expiration = expiration.sub(now);
        // uint256 currentPrice = oracleUnderlyingPrice(underlying);
        // uint256 optPrice = _optionsPrice.getOptionsPrice(currentPrice,strikePrice,expiration,underlying,optType);
        // _optionsPool.burnOptions(msg.sender,optionsId,amount,optPrice);
        // uint256 allPay = optPrice*amount;
        // (address settlement,uint256 fullPay) = _optionsPool.getBurnedFullPay(optionsId,amount);
        // _collateralPool.addNetWorthBalance(settlement,int256(fullPay));
        // _paybackWorth(allPay,1);
        // emit SellOption(msg.sender,optionsId,amount,allPay);
    }
    /**
    * @dev User exercise option.
    * @param optionsId option's ID which was wanted to exercise, must owned by user
    * @param amount user input amount of option user want to exercise.
    */ 
    function exerciseOption(uint256 optionsId,uint256 amount) nonReentrant notHalted InRange(amount) public{
        uint256 allPay = _optionsPool.getExerciseWorth(optionsId,amount);
        require(allPay > 0,"This option cannot exercise");
        (,,uint8 optType,uint32 underlying,uint256 expiration,uint256 strikePrice,) = _optionsPool.getOptionsById(optionsId);
        expiration = expiration.sub(now);
        uint256 currentPrice = oracleUnderlyingPrice(underlying);
        uint256 optPrice = _optionsPrice.getOptionsPrice(currentPrice,strikePrice,expiration,underlying,optType);
        _optionsPool.burnOptions(msg.sender,optionsId,amount,optPrice);
        (address settlement,uint256 fullPay) = _optionsPool.getBurnedFullPay(optionsId,amount);
        _collateralPool.addNetWorthBalance(settlement,int256(fullPay));
        _paybackWorth(allPay,2);
        emit ExerciseOption(msg.sender,optionsId,amount,allPay);
    }
    function getOptionsPrice(uint256 underlyingPrice, uint256 strikePrice, uint256 expiration,
                    uint32 underlying,uint256 amount,uint8 optType) public view returns(uint256){  
        require(underlyingPrice<1e40 && strikePrice < 1e40 && expiration < 1e30 && amount < 1e40 , "Input number is too large");
        uint256 ratio = _getOptionsPriceRate(underlyingPrice,strikePrice,amount,optType);
        uint256 optPrice = _optionsPrice.getOptionsPrice(underlyingPrice,strikePrice,expiration,underlying,optType);
        return (optPrice*ratio)>>32;
    }
    function _getOptionsPriceRate(uint256 underlyingPrice, uint256 strikePrice,uint256 amount,uint8 optType) internal view returns(uint256){
        (uint256 totalCollateral,uint256 rate) = getCollateralAndRate();
        uint256 lockedWorth = _FPTCoin.getTotalLockedWorth();
        require(totalCollateral>=lockedWorth,"collateral is insufficient!");
        totalCollateral = totalCollateral - lockedWorth;
        uint256 buyOccupied = ((optType == 0) == (strikePrice>underlyingPrice)) ? strikePrice*amount:underlyingPrice*amount;
        (uint256 callCollateral,uint256 putCollateral) = _optionsPool.getAllTotalOccupiedCollateral();
        uint256 totalOccupied = (callCollateral + putCollateral + buyOccupied)*rate/1000;
        buyOccupied = ((optType == 0 ? callCollateral : putCollateral) + buyOccupied)*rate/1000;
        require(totalCollateral>=totalOccupied,"collateral is insufficient!");
        return calOptionsPriceRatio(buyOccupied,totalOccupied,totalCollateral);
    }
    function calOptionsPriceRatio(uint256 selfOccupied,uint256 totalOccupied,uint256 totalCollateral) internal pure returns (uint256){
        //r1 + 0.5
        if (selfOccupied*2<=totalOccupied){
            return 4294967296;
        }
        uint256 r1 = (selfOccupied<<32)/totalOccupied-2147483648;
        uint256 r2 = (totalOccupied<<32)/totalCollateral*2;
        //r1*r2*1.5
        r1 = (r1*r2)>>32;
        return ((r1*r1*r1)>>64)*3+4294967296;
//        return SmallNumbers.pow(r1,r2);
    }
        // totalCollateral,OccupiedCollateral,lockedCollateral,unlockedCollateral,LeftCollateral,AvailableCollateral
    function getALLCollateralinfo(address user)public view 
        returns(uint256[] memory,int256[] memory,uint32[] memory,uint32[] memory){
        uint256[] memory values = new uint256[](13); 
        values[0] = getTotalCollateral();
        values[1] = getOccupiedCollateral();
        values[2] = _FPTCoin.getTotalLockedWorth();
        values[3] = safeSubCollateral(values[0],values[2]);
        values[4] = safeSubCollateral(values[0],values[1]);
        values[5] = safeSubCollateral(values[3],values[1]);
        values[6] = getTokenNetworth();
        values[7] = getUserPayingUsd(user);
        values[8] = _FPTCoin.totalSupply();
        values[9] = _FPTCoin.balanceOf(user);
        values[10] = calculateCollateralRate();

        (values[11],values[12]) = getPriceRateRange();
        return (values,
                _collateralPool.getAllRealBalance(whiteList),
                _collateralPool.getFeeRateAll(),
                _optionsPool.getExpirationList());
    }
}
