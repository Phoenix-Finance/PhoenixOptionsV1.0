pragma solidity ^0.4.26;

import "./Ownable.sol";
import "./Fraction.sol";

contract OptionsPrice is Ownable{
    uint256 private Year = 365 days;
    Fraction.fractionNumber private rate = Fraction.fractionNumber(5,1000);
    Fraction.fractionNumber private iv = Fraction.fractionNumber(50,100);
    function setIV(int256 ivNumerator,int256 ivDenominator)public onlyOwner{
        iv.numerator = ivNumerator;
        iv.denominator = ivDenominator;
    }
    function getIV()public view returns (int256,int256){
        return (iv.numerator,iv.denominator);
    }
    function getOptionsPrice(uint256 currentPrice, uint256 strikePrice, uint256 expiration,uint8 optType)public view returns (uint256){
        if (optType == 0) {
            return callOptionsPrice(currentPrice,strikePrice,expiration,rate,iv);
        }else{
            return putOptionsPrice(currentPrice,strikePrice,expiration,rate,iv);
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
            internal view returns (Fraction.fractionNumber, Fraction.fractionNumber) {
        Fraction.fractionNumber memory lns = Fraction.fractionLn(currentPrice);
        Fraction.fractionNumber memory lnl = Fraction.fractionLn(strikePrice);
        Fraction.fractionNumber memory d1 = Fraction.safeFractionSub(lns, lnl);
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
        Fraction.fractionNumber memory nd1 = Fraction.normsDist(d1);
        Fraction.fractionNumber memory nd2 = Fraction.normsDist(d2);
        nd1 = Fraction.safeFractionSub(Fraction.fractionNumber(1,1), nd1);
        nd2 = Fraction.safeFractionSub(Fraction.fractionNumber(1,1), nd2);
        nd1 = Fraction.safeFractionMul(nd1, Fraction.fractionNumber(int256(currentPrice),1));
        nd2 = Fraction.safeFractionMul(nd2, Fraction.fractionNumber(int256(strikePrice),1));
        Fraction.fractionNumber memory rt = Fraction.safeFractionMul(r,Fraction.fractionNumber(int256(expiration),int256(Year)));
        rt = Fraction.invert(Fraction.fractionExp(rt));
        Fraction.fractionNumber memory price = Fraction.safeFractionMul(nd2, rt);
        price = Fraction.safeFractionSub(price, nd1);
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
        Fraction.fractionNumber memory nd1 = Fraction.normsDist(d1);
        Fraction.fractionNumber memory nd2 = Fraction.normsDist(d2);
        nd1 = Fraction.safeFractionMul(nd1, Fraction.fractionNumber(int256(currentPrice),1));
        nd2 = Fraction.safeFractionMul(nd2, Fraction.fractionNumber(int256(strikePrice),1));
        Fraction.fractionNumber memory rt = Fraction.safeFractionMul(r,Fraction.fractionNumber(int256(expiration),int256(Year)));
        rt = Fraction.invert(Fraction.fractionExp(rt));
        Fraction.fractionNumber memory price = Fraction.safeFractionMul(nd2, rt);
        price = Fraction.safeFractionSub(nd1, price);
        return uint256(price.numerator/price.denominator);
    }
}