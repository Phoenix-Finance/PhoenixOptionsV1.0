pragma solidity ^0.5.1;
import "../optionsPrice.sol";
contract OptionsPriceTest is OptionsPrice{
    constructor (address ivContract) OptionsPrice(ivContract) public{
    }
    function testCalculateD1D2_iv(uint256 currentPrice, uint256 strikePrice, uint256 expiration,uint256 ivNumerator,uint256 ivDenominator)
        public view returns(int256,int256,int256,int256){
        Fraction.fractionNumber memory _iv = Fraction.fractionNumber(int256(ivNumerator),int256(ivDenominator));
        (Fraction.fractionNumber memory d1, Fraction.fractionNumber memory d2) = calculateD1D2(currentPrice,strikePrice,expiration,rate,_iv);
        return (d1.numerator,d1.denominator,d2.numerator,d2.denominator);
    }
    function testCalculateND1ND2_iv(uint256 currentPrice, uint256 strikePrice, uint256 expiration,uint256 ivNumerator,uint256 ivDenominator)
        public view returns(int256,int256,int256,int256){
        Fraction.fractionNumber memory _iv = Fraction.fractionNumber(int256(ivNumerator),int256(ivDenominator));
        (Fraction.fractionNumber memory d1, Fraction.fractionNumber memory d2) = calculateD1D2(currentPrice,strikePrice,expiration,rate,_iv);
        d1 = d1.normsDist();
        d2 = d2.normsDist();
        return (d1.numerator,d1.denominator,d2.numerator,d2.denominator);
    }
}