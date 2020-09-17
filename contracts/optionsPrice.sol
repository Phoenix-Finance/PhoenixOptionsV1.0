pragma solidity =0.5.16;

import "./modules/Ownable.sol";
import "./modules/Fraction.sol";
import "./interfaces/IVolatility.sol";
/**
 * @title Options price calculation contract.
 * @dev calculate options' price, using B-S formulas.
 *
 */
contract OptionsPrice is ImportVolatility{
    using Fraction for Fraction.fractionNumber;
    // one year seconds
    int256 constant internal Year = 365 days;
    // constant value in B-S formulas.
    int256 constant internal YearSqrt = 561569230;
    // rate in B-S formulas.
    Fraction.fractionNumber internal rate = Fraction.fractionNumber(0,1000);

    Fraction.fractionNumber internal ratioR2 = Fraction.fractionNumber(4,1);
    /**
     * @dev constructor function , setting contract address.
     * @param ivContract implied volatility contract address
     */  
    constructor (address ivContract) public{
        setVolatilityAddress(ivContract);
    }

    /**
     * @dev get B_S formulas r
     */
    function getRate()public view returns(int256,int256){
        return (rate.numerator,rate.denominator);
    }
    /**
     * @dev set B_S formulas r
     */
    function setRate(int256 numerator,int256 denominator)public onlyOwner{
        rate.numerator = numerator;
        rate.denominator = denominator;
    }
        /**
     * @dev get options price ratio for R2
     */
    function getRatioR2()public view returns(int256,int256){
        return (ratioR2.numerator,ratioR2.denominator);
    }
    /**
     * @dev set options price ratio for R2
     */
    function setRatioR2(int256 numerator,int256 denominator)public onlyOwner{
        ratioR2.numerator = numerator;
        ratioR2.denominator = denominator;
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
        (uint256 ivNumerator,uint256 ivDenominator) = _volatility.calculateIv(underlying,optType,expiration,currentPrice,strikePrice);
        Fraction.fractionNumber memory _iv = Fraction.fractionNumber(int256(ivNumerator),int256(ivDenominator));
        if (optType == 0) {
            return callOptionsPrice(currentPrice,strikePrice,expiration,rate,_iv);
        }else if (optType == 1){
            return putOptionsPrice(currentPrice,strikePrice,expiration,rate,_iv);
        }else{
            require(optType<2," Must input 0 for call option or 1 for put option");
        }
    }
    /**
     * @dev calculate option's price using B_S formulas with user input iv.
     * @param currentPrice current underlying price.
     * @param strikePrice option's strike price.
     * @param expiration option's expiration left time. Equal option's expiration timestamp - now.
     * @param ivNumerator user input iv numerator.
     * @param ivDenominator user input iv denominator.
     * @param optType option's type, 0 for CALL, 2 for PUT.
     */
    function getOptionsPrice_iv(uint256 currentPrice, uint256 strikePrice, uint256 expiration,
            uint256 ivNumerator,uint256 ivDenominator,uint8 optType)public view returns (uint256){
        Fraction.fractionNumber memory _iv = Fraction.fractionNumber(int256(ivNumerator),int256(ivDenominator));
        if (optType == 0) {
            return callOptionsPrice(currentPrice,strikePrice,expiration,rate,_iv);
        }else if (optType == 1){
            return putOptionsPrice(currentPrice,strikePrice,expiration,rate,_iv);
        }else{
            require(optType<2," Must input 0 for call option or 1 for put option");
        }
    }
    /**
     * @dev An auxiliary function, calculate parameter d1 and d2 in B_S formulas.
     * @param currentPrice current underlying price.
     * @param strikePrice option's strike price.
     * @param expiration option's expiration left time. Equal option's expiration timestamp - now.
     * @param r parameter r in B_S formulas.
     * @param derta implied volatility value in B-S formulas.
     */
    function calculateD1D2(uint256 currentPrice, uint256 strikePrice, uint256 expiration,
         Fraction.fractionNumber memory r, Fraction.fractionNumber memory derta) 
            internal pure returns (Fraction.fractionNumber memory, Fraction.fractionNumber memory) {
        Fraction.fractionNumber memory d1 = (currentPrice == strikePrice) ? Fraction.fractionNumber(0,1) :
            Fraction.ln(currentPrice).sub(Fraction.ln(strikePrice));
        Fraction.fractionNumber memory derta2 = derta.mul(derta);
        derta2.denominator = derta2.denominator*2;
        derta2 = derta2.add(r);
        derta2 = derta2.mul(Fraction.fractionNumber(int256(expiration),Year));
        d1 = d1.add(derta2);
        derta2 = Fraction.fractionNumber(int256(Fraction.sqrt(expiration*1e10)),YearSqrt).mul(derta);
        d1 = d1.div(derta2);
        derta2 = d1.sub(derta2);
        return (d1, derta2);
    }
    /**
     * @dev An auxiliary function, calculate put option price using B_S formulas.
     * @param currentPrice current underlying price.
     * @param strikePrice option's strike price.
     * @param expiration option's expiration left time. Equal option's expiration timestamp - now.
     * @param r parameter r in B_S formulas.
     * @param derta implied volatility value in B-S formulas.
     */
    //L*pow(e,-rT)*(1-N(d2)) - S*(1-N(d1))
    function putOptionsPrice(uint256 currentPrice, uint256 strikePrice, uint256 expiration,
            Fraction.fractionNumber memory r, Fraction.fractionNumber memory derta) 
                internal pure returns (uint256) {
       (Fraction.fractionNumber memory d1, Fraction.fractionNumber memory d2) = calculateD1D2(currentPrice, strikePrice, expiration, r, derta);
        d1 = d1.normsDist();
        d2 = d2.normsDist();
        d1.numerator = (d1.denominator - d1.numerator)*int256(currentPrice);
        d2.numerator = (d2.denominator - d2.numerator)*int256(strikePrice);
        if (r.numerator == 0){
            d1 = d2.sub(d1);
        }else{
            r = r.mul(Fraction.fractionNumber(int256(expiration),Year));
    //        r = r.exp().invert();
            d1 = d2.div(r.exp()).sub(d1);
        }
        return uint256(d1.numerator/d1.denominator);
    }
    /**
     * @dev An auxiliary function, calculate call option price using B_S formulas.
     * @param currentPrice current underlying price.
     * @param strikePrice option's strike price.
     * @param expiration option's expiration left time. Equal option's expiration timestamp - now.
     * @param r parameter r in B_S formulas.
     * @param derta implied volatility value in B-S formulas.
     */
    //S*N(d1)-L*pow(e,-rT)*N(d2)
    function callOptionsPrice(uint256 currentPrice, uint256 strikePrice, uint256 expiration,
            Fraction.fractionNumber memory r, Fraction.fractionNumber memory derta) 
                internal pure returns (uint256) {
       (Fraction.fractionNumber memory d1, Fraction.fractionNumber memory d2) = calculateD1D2(currentPrice, strikePrice, expiration, r, derta);
        d1 = d1.normsDist();
        d2 = d2.normsDist();
        d1.numerator = d1.numerator*int256(currentPrice);
        d2.numerator = d2.numerator*int256(strikePrice);
//        r = r.exp().invert();
        if (r.numerator == 0){
            d1 = d1.sub(d2);
        }else{
            r = r.mul(Fraction.fractionNumber(int256(expiration),Year));
    //        r = r.exp().invert();
            d1 = d1.sub(d2.div(r.exp()));
        }
        return uint256(d1.numerator/d1.denominator);
    }
    function calOptionsPriceRatio(uint256 selfOccupied,uint256 totalOccupied,uint256 totalCollateral) public view returns (uint256,uint256){
        //r1 + 0.5
        if (selfOccupied*2<=totalOccupied){
            return(1,1);
        }
        //r1 + 0.5
        Fraction.fractionNumber memory r1 = Fraction.fractionNumber(int256(selfOccupied*2+totalOccupied),int256(totalOccupied*2));
        Fraction.fractionNumber memory r2 = Fraction.fractionNumber(int256(totalOccupied),int256(totalCollateral)).mul(ratioR2);
        //pow(r1,r2)
        r1 = r1.pow(r2);
        return (uint256(r1.numerator),uint256(r1.denominator));
    }
}