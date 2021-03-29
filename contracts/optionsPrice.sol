pragma solidity =0.5.16;

import "./modules/Ownable.sol";
import "./interfaces/IVolatility.sol";
import "./modules/SmallNumbers.sol";
/**
 * @title Options price calculation contract.
 * @dev calculate options' price, using B-S formulas.
 *
 */
contract OptionsPrice is ImportVolatility{
    // one year seconds
    uint256 constant internal Year = 365 days;
    int256 constant public FIXED_ONE = 1 << 32; // 0x100000000
    uint256 internal ratioR2 = 4<<32;
    
    /**
     * @dev constructor function , setting contract address.
     */  
    constructor (address ivContract) public{
        setVolatilityAddress(ivContract);
    }

    /**
     * @dev calculate option's price using B_S formulas
     * @param currentPrice current underlying price.
     * @param strikePrice option's strike price.
     * @param expiration option's expiration left time. Equal option's expiration timestamp - now.
     * @param underlying option's underlying id, 1 for BTC, 2 for ETH.
     * @param optType option's type, 0 for CALL, 2 for PUT.
     */
    function getOptionsPrice(uint256 currentPrice, uint256 strikePrice, uint256 expiration,uint32 underlying,uint8 optType)public view returns (uint256){
         uint256 _iv = _volatility.calculateIv(underlying,optType,expiration,currentPrice,strikePrice);
        if (optType == 0) {
            return callOptionsPrice(currentPrice,strikePrice,expiration,_iv);
        }else if (optType == 1){
            return putOptionsPrice(currentPrice,strikePrice,expiration,_iv);
        }else{
            require(optType<2," Must input 0 for call option or 1 for put option");
        }
    }
    /**
     * @dev calculate option's price using B_S formulas with user input iv.
     * @param currentPrice current underlying price.
     * @param strikePrice option's strike price.
     * @param expiration option's expiration left time. Equal option's expiration timestamp - now.
     * @param _iv user input iv numerator.
     * @param optType option's type, 0 for CALL, 2 for PUT.
     */
    function getOptionsPrice_iv(uint256 currentPrice, uint256 strikePrice, uint256 expiration,
            uint256 _iv,uint8 optType)public pure returns (uint256){
        if (optType == 0) {
            return callOptionsPrice(currentPrice,strikePrice,expiration,_iv);
        }else if (optType == 1){
            return putOptionsPrice(currentPrice,strikePrice,expiration,_iv);
        }else{
            require(optType<2," Must input 0 for call option or 1 for put option");
        }
    }
    /**
     * @dev An auxiliary function, calculate parameter d1 and d2 in B_S formulas.
     * @param currentPrice current underlying price.
     * @param strikePrice option's strike price.
     * @param expiration option's expiration left time. Equal option's expiration timestamp - now.
     * @param derta implied volatility value in B-S formulas.
     */
    function calculateD1D2(uint256 currentPrice, uint256 strikePrice, uint256 expiration, uint256 derta) 
            internal pure returns (int256,int256) {
        int256 d1 = 0;
        if (currentPrice > strikePrice){
            d1 = int256(SmallNumbers.fixedLoge((currentPrice<<32)/strikePrice));
        }else if (currentPrice<strikePrice){
            d1 = -int256(SmallNumbers.fixedLoge((strikePrice<<32)/currentPrice));
        }
        uint256 derta2 = (derta*derta)>>33;//0.5*derta^2
        derta2 = derta2*expiration/Year;
        d1 = d1+int256(derta2);
        derta2 = SmallNumbers.sqrt(derta2*2);
        d1 = (d1<<32)/int256(derta2);
        return (d1, d1 - int256(derta2));
    }
    /**
     * @dev An auxiliary function, calculate put option price using B_S formulas.
     * @param currentPrice current underlying price.
     * @param strikePrice option's strike price.
     * @param expiration option's expiration left time. Equal option's expiration timestamp - now.
     * @param derta implied volatility value in B-S formulas.
     */
    //L*pow(e,-rT)*(1-N(d2)) - S*(1-N(d1))
    function putOptionsPrice(uint256 currentPrice, uint256 strikePrice, uint256 expiration, uint256 derta) 
                internal pure returns (uint256) {
       (int256 d1, int256 d2) = calculateD1D2(currentPrice, strikePrice, expiration, derta);
        d1 = SmallNumbers.normsDist(d1);
        d2 = SmallNumbers.normsDist(d2);
        d1 = (FIXED_ONE - d1)*int256(currentPrice);
        d2 = (FIXED_ONE - d2)*int256(strikePrice);
        d1 = d2 - d1;
        int256 minPrice = int256(currentPrice)*12884902;
        return (d1>minPrice) ? uint256(d1>>32) : currentPrice*3/1000;
    }
    /**
     * @dev An auxiliary function, calculate call option price using B_S formulas.
     * @param currentPrice current underlying price.
     * @param strikePrice option's strike price.
     * @param expiration option's expiration left time. Equal option's expiration timestamp - now.
     * @param derta implied volatility value in B-S formulas.
     */
    //S*N(d1)-L*pow(e,-rT)*N(d2)
    function callOptionsPrice(uint256 currentPrice, uint256 strikePrice, uint256 expiration, uint256 derta) 
                internal pure returns (uint256) {
       (int256 d1, int256 d2) = calculateD1D2(currentPrice, strikePrice, expiration, derta);
        d1 = SmallNumbers.normsDist(d1);
        d2 = SmallNumbers.normsDist(d2);
        d1 = d1*int256(currentPrice)-d2*int256(strikePrice);
        int256 minPrice = int256(currentPrice)*12884902;
        return (d1>minPrice) ? uint256(d1>>32) : currentPrice*3/1000;
    }
    function calOptionsPriceRatio(uint256 selfOccupied,uint256 totalOccupied,uint256 totalCollateral) public pure returns (uint256){
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
}