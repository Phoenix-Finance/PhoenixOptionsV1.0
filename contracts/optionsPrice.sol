pragma solidity ^0.4.26;

import "./modules/Ownable.sol";
import "./modules/Fraction.sol";
import "./interfaces/IVolatility.sol";
contract OptionsPrice is ImportVolatility{
    constructor (address ivContract) public{
        setVolatilityAddress(ivContract);
    }
    uint256 constant internal Year = 365 days;
    Fraction.fractionNumber internal rate = Fraction.fractionNumber(5,1000);
    uint256 private maxPrice = 1e20;
    uint256 private minPrice = 1e3;
    //B_S formulas r
    function getRate()public view returns(int256,int256){
        return (rate.numerator,rate.denominator);
    }
    function setRate(int256 numerator,int256 denominator)public onlyOwner{
        rate.numerator = numerator;
        rate.denominator = denominator;
    }
    function setPriceRange(uint256 _minPrice,uint256 _maxPrice) public onlyOwner{
        minPrice = _minPrice;
        maxPrice = _maxPrice;
    }
    function getOptionsPrice(uint256 currentPrice, uint256 strikePrice, uint256 expiration,uint32 underlying,uint8 optType)public view returns (uint256){
        (uint256 ivNumerator,uint256 ivDenominator) = _volatility.calculateIv(underlying,optType,expiration,currentPrice,strikePrice);
        Fraction.fractionNumber memory _iv = Fraction.fractionNumber(int256(ivNumerator),int256(ivDenominator));
        if (optType == 0) {
            return callOptionsPrice(currentPrice,strikePrice,expiration,rate,_iv);
        }else{
            return putOptionsPrice(currentPrice,strikePrice,expiration,rate,_iv);
        }
    }
    function getOptionsPrice_iv(uint256 currentPrice, uint256 strikePrice, uint256 expiration,
            uint256 ivNumerator,uint256 ivDenominator,uint8 optType)public view returns (uint256){
        Fraction.fractionNumber memory _iv = Fraction.fractionNumber(int256(ivNumerator),int256(ivDenominator));
        if (optType == 0) {
            return callOptionsPrice(currentPrice,strikePrice,expiration,rate,_iv);
        }else{
            return putOptionsPrice(currentPrice,strikePrice,expiration,rate,_iv);
        }
    }
    function calculateD1D2(uint256 currentPrice, uint256 strikePrice, uint256 expiration,
         Fraction.fractionNumber memory r, Fraction.fractionNumber memory derta) 
            internal pure returns (Fraction.fractionNumber, Fraction.fractionNumber) {
        Fraction.fractionNumber memory d1 = Fraction.fractionNumber(0,1);
        if (currentPrice != strikePrice){
            Fraction.fractionNumber memory lns = Fraction.fractionLn(currentPrice);
            Fraction.fractionNumber memory lnl = Fraction.fractionLn(strikePrice);
            d1 = Fraction.safeFractionSub(lns, lnl);
        }
        Fraction.fractionNumber memory derta2 = Fraction.safeFractionMul(derta, derta);
        derta2 = Fraction.safeFractionMul(derta2, Fraction.fractionNumber(1,2));
        derta2 = Fraction.safeFractionAdd(derta2, r);
        derta2 = Fraction.safeFractionMul(derta2, Fraction.fractionNumber(int256(expiration),int256(Year)));
        d1 = Fraction.safeFractionAdd(d1, derta2);
        Fraction.fractionNumber memory dertaT = Fraction.safeFractionMul(Fraction.fractionSqrt(Fraction.fractionNumber(int256(expiration*1e10),int256(Year*1e10))), derta);
        d1 = Fraction.safeFractionDiv(d1, dertaT);
        Fraction.fractionNumber memory d2 = Fraction.safeFractionSub(d1, dertaT);
        return (d1, d2);
    }

    //L*pow(e,-rT)*(1-N(d2)) - S*(1-N(d1))
    function putOptionsPrice(uint256 currentPrice, uint256 strikePrice, uint256 expiration,
            Fraction.fractionNumber memory r, Fraction.fractionNumber memory derta) 
                internal view returns (uint256) {
       (Fraction.fractionNumber memory d1, Fraction.fractionNumber memory d2) = calculateD1D2(currentPrice, strikePrice, expiration, r, derta);
        d1 = Fraction.normsDist(d1);
        d2 = Fraction.normsDist(d2);
        d1 = Fraction.safeFractionSub(Fraction.fractionNumber(1,1), d1);
        d2 = Fraction.safeFractionSub(Fraction.fractionNumber(1,1), d2);
        d1 = Fraction.safeFractionMul(d1, Fraction.fractionNumber(int256(currentPrice),1));
        d2 = Fraction.safeFractionMul(d2, Fraction.fractionNumber(int256(strikePrice),1));
        Fraction.fractionNumber memory rt = Fraction.safeFractionMul(r,Fraction.fractionNumber(int256(expiration),int256(Year)));
        rt = Fraction.invert(Fraction.fractionExp(rt));
        Fraction.fractionNumber memory price = Fraction.safeFractionMul(d2, rt);
        price = Fraction.safeFractionSub(price, d1);
        return uint256(price.numerator/price.denominator);
    }

    /*
        r := FloatNum{
            big.NewInt(5),
            big.NewInt(1000)}
    */
    //S*N(d1)-L*pow(e,-rT)*N(d2)
    function callOptionsPrice(uint256 currentPrice, uint256 strikePrice, uint256 expiration,
            Fraction.fractionNumber memory r, Fraction.fractionNumber memory derta) 
                internal view returns (uint256) {
       (Fraction.fractionNumber memory d1, Fraction.fractionNumber memory d2) = calculateD1D2(currentPrice, strikePrice, expiration, r, derta);
        d1 = Fraction.normsDist(d1);
        d2 = Fraction.normsDist(d2);
        d1 = Fraction.safeFractionMul(d1, Fraction.fractionNumber(int256(currentPrice),1));
        d2 = Fraction.safeFractionMul(d2, Fraction.fractionNumber(int256(strikePrice),1));
        Fraction.fractionNumber memory rt = Fraction.safeFractionMul(r,Fraction.fractionNumber(int256(expiration),int256(Year)));
        rt = Fraction.invert(Fraction.fractionExp(rt));
        Fraction.fractionNumber memory price = Fraction.safeFractionMul(d2, rt);
        price = Fraction.safeFractionSub(d1, price);
        return uint256(price.numerator/price.denominator);
    }
}