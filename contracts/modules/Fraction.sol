pragma solidity ^0.4.26;
library Fraction {
//    using Fraction for fractionNumber;
    int256 constant private sqrtNum = 1<<120;
    int256 constant private shl = 80;
    uint8 constant private PRECISION   = 32;  // fractional bits
    uint256 constant private FIXED_ONE = uint256(1) << PRECISION; // 0x100000000
    uint256 constant private FIXED_TWO = uint256(2) << PRECISION; // 0x200000000
    uint256 constant private MAX_VAL   = uint256(1) << (256 - PRECISION); // 0x0000000100000000000000000000000000000000000000000000000000000000

    struct fractionNumber{
        int256 numerator;
        int256 denominator;
    }
    function isNeg(fractionNumber memory a)  internal pure returns (bool) {
	    return a.numerator<0 != a.denominator < 0;
    }
    function intAbs(int256 a)internal pure returns (int256){
        return (a<0) ? -a:a;
    }
    function abs(fractionNumber memory a) internal pure returns (fractionNumber){
        if (a.numerator<0){
            a.numerator = -a.numerator;
        }
        if(a.denominator<0){
            a.denominator = -a.denominator; 
        }
        return a;
    }
    function invert(fractionNumber memory a) internal pure returns (fractionNumber){
        return fractionNumber(a.denominator,a.numerator);
    }
    function sqrt(fractionNumber memory a) internal pure returns (fractionNumber) {
        require(a.numerator>=0 && a.denominator>=0,"Sqrt must input a positive value");
        return fractionNumber(int256(sqrt(uint256(a.numerator))),int256(sqrt(uint256(a.denominator))));
    }
    function fractionAddInt(fractionNumber memory a,int64 b) internal pure returns (fractionNumber) {
        a = safeFractionNumber(a);
        return fractionNumber(a.numerator+a.denominator*b,a.denominator);
    }
    function div(fractionNumber memory a,fractionNumber memory b) internal pure returns (fractionNumber) {
        return safeFractionNumber(fractionDiv(a,b));
    }
    function mul(fractionNumber memory a,fractionNumber memory b) internal pure returns (fractionNumber) {
        return safeFractionNumber(fractionMul(a,b));
    }
    function add(fractionNumber memory a,fractionNumber memory b) internal pure returns (fractionNumber)  {
        return safeFractionNumber(fractionAdd(a,b));
    }
    function sub(fractionNumber memory a,fractionNumber memory b) internal pure returns (fractionNumber)  {
        return safeFractionNumber(fractionSub(a,b));
    }

    function zoomOut(fractionNumber memory a, int256 rate) internal pure returns (fractionNumber) {
        require(a.denominator>rate,"fraction number is overflow");
        return fractionNumber(a.numerator/rate,a.denominator/rate);
    }
    function zoomin(fractionNumber memory a, int256 rate) internal pure returns (fractionNumber) {
        return safeFractionNumber(fractionNumber(a.numerator*rate,a.denominator*rate));
    }
    function ln(fractionNumber memory a)  internal pure returns (fractionNumber) {
        uint256 _x = uint256((a.numerator << PRECISION)/a.denominator);
        return fractionNumber(int256(fixedLoge(_x)),int256(FIXED_ONE));
    }
    function safeFractionNumber(fractionNumber memory a) internal pure returns (fractionNumber) {
        int256 num = intAbs(a.numerator);
        int256 deno = intAbs(a.denominator);
        if(deno>num){
            if (deno>sqrtNum) {
                int256 rate = deno>>shl;
                return zoomOut(a,rate);
            }
        } else {
            if (num>sqrtNum) {
                rate = num>>shl;
                return zoomOut(a,rate);
            }
        }
        return a;
    }
    function fractionDiv(fractionNumber memory a,fractionNumber memory b) internal pure returns (fractionNumber) {
        return fractionNumber(a.numerator*b.denominator,a.denominator*b.numerator);
    }
    function fractionMul(fractionNumber memory a,fractionNumber memory b) internal pure returns (fractionNumber) {
        return fractionNumber(a.numerator*b.numerator,a.denominator*b.denominator);
    }
    function fractionAdd(fractionNumber memory a,fractionNumber memory b) internal pure returns (fractionNumber) {
        return fractionNumber(a.numerator*b.denominator+b.numerator*a.denominator,a.denominator*b.denominator);
    }
    function fractionSub(fractionNumber memory a,fractionNumber memory b) internal pure returns (fractionNumber) {
        return fractionNumber(a.numerator*b.denominator-b.numerator*a.denominator,a.denominator*b.denominator);
    }

    function normsDist(fractionNumber memory xNum) internal pure returns (fractionNumber) {
        bool _isNeg = isNeg(xNum);
        if (_isNeg) {
            xNum = abs(xNum);
        }
        int256 value = xNum.numerator/xNum.denominator;
        if (value > 10){
            return _isNeg ? fractionNumber(0,1) : fractionNumber(1,1);
        } 
        fractionNumber[5] memory b = [
            fractionNumber(31938153,1e8),
            fractionNumber(-356563782,1e9),
            fractionNumber(1781477937,1e9),
            fractionNumber(-1821255978,1e9),
            fractionNumber(1330274429,1e9)];
        fractionNumber memory t = mul(xNum,fractionNumber(2316419, 1e7));
        t.numerator += t.denominator;
        t = invert(t);
        xNum = mul(xNum,xNum);
        xNum.denominator *= -2;
        xNum = exp(xNum);
        xNum = mul(fractionNumber(39894228040143267793,1e20),xNum);
        fractionNumber memory secondArg = fractionNumber(0,1);
        fractionNumber memory tt = t;
        for (uint256 i = 0; i < b.length; i++) {
            secondArg = add(secondArg,mul(b[i],tt));
            tt = mul(tt,t);
        }
        xNum = mul(xNum,secondArg);
        if (!_isNeg) {
            xNum.numerator = xNum.denominator - xNum.numerator;
        }
        return xNum;
    }
    function exp(fractionNumber memory _x) internal pure returns (fractionNumber){
        bool _isNeg = isNeg(_x);
        if (_isNeg) {
            _x = abs(_x);
        }
        _x = safeFractionNumber(_x);
        _x.numerator = _x.numerator << PRECISION;
        _x =  fractionExp_sub(_x);
        if (_isNeg) {
            _x = invert(_x);
        }
        return _x;
    }
    function fractionExp_sub(fractionNumber memory _x) internal pure returns (fractionNumber){
        uint256 intValue = uint256(_x.numerator/_x.denominator);
        if (intValue > 0x386bfdba29){
            fractionNumber memory _x1 = fractionNumber(_x.numerator/2,_x.denominator);
            fractionNumber memory _x2 = fractionNumber(_x.numerator-_x1.numerator,_x.denominator);
            _x1 = fractionExp_sub(_x1);
            _x2 = fractionExp_sub(_x2);
            return mul(_x1,_x2);
        }else{
            return fractionNumber(int256(fixedExp(intValue)),int256(FIXED_ONE));
        }
    }
    //This is where all your gas goes, sorry
    //Not sorry, you probably only paid 1 gwei
    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
    function ln(uint256 _x)  internal pure returns (fractionNumber) {
        _x = _x << PRECISION;
        return fractionNumber(int256(fixedLoge(_x)),int256(FIXED_ONE));
    }
        /**
        input range: 
            [0x100000000,uint256_max]
        output range:
            [0, 0x9b43d4f8d6]

        This method asserts outside of bounds

    */
    function fixedLoge(uint256 _x) internal pure returns (uint256 logE) {
        /*
        Since `fixedLog2_min` output range is max `0xdfffffffff` 
        (40 bits, or 5 bytes), we can use a very large approximation
        for `ln(2)`. This one is used since it’s the max accuracy 
        of Python `ln(2)`

        0xb17217f7d1cf78 = ln(2) * (1 << 56)
        
        */
        //Cannot represent negative numbers (below 1)
        require(_x >= FIXED_ONE,"loge function input is too small");

        uint256 _log2 = fixedLog2(_x);
        logE = (_log2 * 0xb17217f7d1cf78) >> 56;
    }

    /**
        Returns log2(x >> 32) << 32 [1]
        So x is assumed to be already upshifted 32 bits, and 
        the result is also upshifted 32 bits. 
        
        [1] The function returns a number which is lower than the 
        actual value

        input-range : 
            [0x100000000,uint256_max]
        output-range: 
            [0,0xdfffffffff]

        This method asserts outside of bounds

    */
    function fixedLog2(uint256 _x) internal pure returns (uint256) {
        // Numbers below 1 are negative. 
        require( _x >= FIXED_ONE,"Log2 input is too small");

        uint256 hi = 0;
        while (_x >= FIXED_TWO) {
            _x >>= 1;
            hi += FIXED_ONE;
        }

        for (uint8 i = 0; i < PRECISION; ++i) {
            _x = (_x * _x) / FIXED_ONE;
            if (_x >= FIXED_TWO) {
                _x >>= 1;
                hi += uint256(1) << (PRECISION - 1 - i);
            }
        }

        return hi;
    }

    /**
        fixedExp is a ‘protected’ version of `fixedExpUnsafe`, which 
        asserts instead of overflows
    */
    function fixedExp(uint256 _x) internal pure returns (uint256) {
        require(_x <= 0x386bfdba29,"exp function input is overflow");
        return fixedExpUnsafe(_x);
    }
       /**
        fixedExp 
        Calculates e^x according to maclauren summation:

        e^x = 1+x+x^2/2!...+x^n/n!

        and returns e^(x>>32) << 32, that is, upshifted for accuracy

        Input range:
            - Function ok at    <= 242329958953 
            - Function fails at >= 242329958954

        This method is is visible for testcases, but not meant for direct use. 
 
        The values in this method been generated via the following python snippet: 

        def calculateFactorials():
            “”"Method to print out the factorials for fixedExp”“”

            ni = []
            ni.append( 295232799039604140847618609643520000000) # 34!
            ITERATIONS = 34
            for n in range( 1,  ITERATIONS,1 ) :
                ni.append(math.floor(ni[n - 1] / n))
            print( “\n        “.join([“xi = (xi * _x) >> PRECISION;\n        res += xi * %s;” % hex(int(x)) for x in ni]))

    */
    function fixedExpUnsafe(uint256 _x) internal pure returns (uint256) {
    
        uint256 xi = FIXED_ONE;
        uint256 res = 0xde1bc4d19efcac82445da75b00000000 * xi;

        xi = (xi * _x) >> PRECISION;
        res += xi * 0xde1bc4d19efcb0000000000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x6f0de268cf7e58000000000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x2504a0cd9a7f72000000000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x9412833669fdc800000000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x1d9d4d714865f500000000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x4ef8ce836bba8c0000000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0xb481d807d1aa68000000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x16903b00fa354d000000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x281cdaac677b3400000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x402e2aad725eb80000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x5d5a6c9f31fe24000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x7c7890d442a83000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x9931ed540345280000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0xaf147cf24ce150000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0xbac08546b867d000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0xbac08546b867d00000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0xafc441338061b8000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x9c3cabbc0056e000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x839168328705c80000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x694120286c04a0000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x50319e98b3d2c400;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x3a52a1e36b82020;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x289286e0fce002;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x1b0c59eb53400;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x114f95b55400;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0xaa7210d200;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x650139600;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x39b78e80;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x1fd8080;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x10fbc0;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x8c40;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x462;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x22;

        return res / 0xde1bc4d19efcac82445da75b00000000;
    }  
}