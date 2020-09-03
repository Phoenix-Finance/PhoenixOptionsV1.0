pragma solidity =0.5.16;
import "../optionsPrice.sol";
contract OptionsPriceTest is OptionsPrice{
    uint256 expirationZoom = 1;
    constructor (address ivContract) OptionsPrice(ivContract) public{
    }
    function setExpirationZoom(uint256 zoom) public{
        expirationZoom = zoom;
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
        /**
     * @dev calculate option's price using B_S formulas
     * @param currentPrice current underlying price.
     * @param strikePrice option's strike price.
     * @param expiration option's expiration left time. Equal option's expiration timestamp - now.
     * @param underlying option's underlying id, 1 for BTC, 2 for ETH.
     * @param optType option's type, 0 for CALL, 2 for PUT.
     */
    function getOptionsPrice(uint256 currentPrice, uint256 strikePrice, uint256 expiration,uint32 underlying,uint8 optType)public view returns (uint256){
        expiration = expiration * expirationZoom;
        (uint256 ivNumerator,uint256 ivDenominator) = _volatility.calculateIv(underlying,optType,expiration,currentPrice,strikePrice);
        Fraction.fractionNumber memory _iv = Fraction.fractionNumber(int256(ivNumerator),int256(ivDenominator));
        if (optType == 0) {
            return callOptionsPrice(currentPrice,strikePrice,expiration,rate,_iv);
        }else{
            return putOptionsPrice(currentPrice,strikePrice,expiration,rate,_iv);
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
                expiration = expiration * expirationZoom;
        Fraction.fractionNumber memory _iv = Fraction.fractionNumber(int256(ivNumerator),int256(ivDenominator));
        if (optType == 0) {
            return callOptionsPrice(currentPrice,strikePrice,expiration,rate,_iv);
        }else{
            return putOptionsPrice(currentPrice,strikePrice,expiration,rate,_iv);
        }
    }
}