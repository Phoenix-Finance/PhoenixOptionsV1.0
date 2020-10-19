pragma solidity =0.5.16;
import "./modules/Operator.sol";
import "./modules/SmallNumbers.sol";
/**
 * @title Options Implied volatility calculation.
 * @dev A Smart-contract to calculate options Implied volatility.
 *
 */
contract ImpliedVolatilityNew is Operator {
    //Implied volatility decimal, is same with oracle's price' decimal. 
    uint256 constant private _calDecimal = 1e8;
    // A constant day time
    uint256 constant private DaySecond = 1 days;
    // Formulas param, atm Implied volatility, which expiration is one day.
    mapping(uint32=>uint256) internal ATMIv0;
    // Formulas param A,B,C,D,E
    mapping(uint32=>int256) internal paramA;
    mapping(uint32=>int256) internal paramB;
    mapping(uint32=>int256) internal paramC;
    mapping(uint32=>int256) internal paramD;
    mapping(uint32=>int256) internal paramE;
    // Formulas param ATM Iv Rate, sort by time
    mapping(uint32=>uint64[]) internal ATMIvRate;

    constructor () public{
        ATMIv0[1] = 48730000;
        ATMIv0[2] = 48730000;
        paramA[1] = -214479761754;
        paramA[2] = -214479761754;
        paramB[1] = 214748364800;
        paramB[2] = 214748364800;
        paramC[1] = -214748365;
        paramC[2] = -214748365;
        paramD[1] = 214748365;
        paramD[2] = 214748365;
        paramE[1] = 4294967296;
        paramE[2] = 4294967296;
        ATMIvRate[1] = [4294967296,4667490694,4900206836,5072324858,5209982467,5325225602,5424648794,5512272257,5590735710,5661869580,
                        5726997367,5787108313,5842962022,5895154961,5944164400,5990378433,6034117070,6075647403,6115194762,6152951059,
                        6189081143,6223727697,6257015079,6289052356,6319935737,6349750530,6378572747,6406470416,6433504677,6459730682,
                        6485198365,6509953083,6534036167,6557485384,6580335345,6602617845,6624362167,6645595339,6666342365,6686626424,
                        6706469040,6725890245,6744908708,6763541863,6781806011,6799716421,6817287416,6834532448,6851464169,6868094495,
                        6884434659,6900495269,6916286348,6931817377,6947097338,6962134747,6976937683,6991513820,7005870457,7020014534,
                        7033952666,7047691153,7061236008,7074592969,7087767518,7100764896,7113590116,7126247978,7138743079,7151079827,
                        7163262447,7175294996,7187181369,7198925308,7210530411,7222000137,7233337816,7244546654,7255629739,7266590047,
                        7277430448,7288153711,7298762505,7309259411,7319646919,7329927438,7340103293,7350176736,7360149944,7370025023];
         ATMIvRate[2] =  ATMIvRate[1];
    }
    /**
     * @dev set underlying's atm implied volatility. Foundation operator will modify it frequently.
     * @param underlying underlying ID.,1 for BTC, 2 for ETH
     * @param _Iv0 underlying's atm implied volatility. 
     */ 
    function SetAtmIv(uint32 underlying,uint256 _Iv0)public onlyOperatorIndex(0){
        ATMIv0[underlying] = _Iv0;
    }
    /**
     * @dev set implied volatility surface Formulas param. 
     * @param underlying underlying ID.,1 for BTC, 2 for ETH
     */ 
    function SetFormulasParam(uint32 underlying,int256 _paramA,int256 _paramB,int256 _paramC,int256 _paramD,int256 _paramE)
        public onlyOwner{
        paramA[underlying] = _paramA;
        paramB[underlying] = _paramB;
        paramC[underlying] = _paramC;
        paramD[underlying] = _paramD;
        paramE[underlying] = _paramE;
    }
    /**
     * @dev set implied volatility surface Formulas param IvRate. 
     * @param underlying underlying ID.,1 for BTC, 2 for ETH
     */ 
    function SetATMIvRate(uint32 underlying,uint64[] memory IvRate)public onlyOwner{
        ATMIvRate[underlying] = IvRate;
    }
    /**
     * @dev Interface, calculate option's iv. 
     * @param underlying underlying ID.,1 for BTC, 2 for ETH
     * optType option's type.,0 for CALL, 1 for PUT
     * @param expiration Option's expiration, left time to now.
     * @param currentPrice underlying current price
     * @param strikePrice option's strike price
     */ 
    function calculateIv(uint32 underlying,uint8 /*optType*/,uint256 expiration,uint256 currentPrice,uint256 strikePrice)public view returns (uint256){
        uint256 iv = calATMIv(underlying,expiration);
        if (currentPrice == strikePrice){
            return iv;
        }
        return calImpliedVolatility(underlying,iv,currentPrice,strikePrice);
    }
    /**
     * @dev calculate option's atm iv. 
     * @param underlying underlying ID.,1 for BTC, 2 for ETH
     * @param expiration Option's expiration, left time to now.
     */ 
    function calATMIv(uint32 underlying,uint256 expiration)internal view returns(uint256){
        uint256 index = expiration/DaySecond;
        
        if (index == 0){
            return ATMIv0[underlying];
        }
        uint256 len = ATMIvRate[underlying].length;
        if (index>=len){
            index = len-1;
        }
        uint256 rate = insertValue(index*DaySecond,(index+1)*DaySecond,ATMIvRate[underlying][index-1],ATMIvRate[underlying][index],expiration);
        return ATMIv0[underlying]*rate/_calDecimal;
    }
    /**
     * @dev calculate option's implied volatility. 
     * @param underlying underlying ID.,1 for BTC, 2 for ETH
     * @param _ATMIv atm iv, calculated by calATMIv
     * @param currentPrice underlying current price
     * @param strikePrice option's strike price
     */ 
    function calImpliedVolatility(uint32 underlying,uint256 _ATMIv,uint256 currentPrice,uint256 strikePrice)internal view returns(uint256){
        int256 ln = calImpliedVolLn(underlying,currentPrice,strikePrice);
        //ln*ln+e
        uint256 lnSqrt = uint256(((ln*ln)>>32) + paramE[underlying]);
        lnSqrt = SmallNumbers.sqrt(lnSqrt);
        //ln*c+sqrt
        ln = ((ln*paramC[underlying])>>32) + int256(lnSqrt);
        ln = (ln* paramB[underlying] + int256(_ATMIv*_ATMIv))>>32;
        return SmallNumbers.sqrt(uint256(ln+paramA[underlying]));
    }
    /**
     * @dev An auxiliary function, calculate ln price. 
     * @param underlying underlying ID.,1 for BTC, 2 for ETH
     * @param currentPrice underlying current price
     * @param strikePrice option's strike price
     */ 
    //ln(k) - ln(s) + d
    function calImpliedVolLn(uint32 underlying,uint256 currentPrice,uint256 strikePrice)internal view returns(int256){
        if (currentPrice == strikePrice){
            return paramD[underlying];
        }else if (currentPrice > strikePrice){
            return int256(SmallNumbers.fixedLoge((currentPrice<<32)/strikePrice))+paramD[underlying];
        }else{
            return -int256(SmallNumbers.fixedLoge((strikePrice<<32)/currentPrice))+paramD[underlying];
        }
    }
    /**
     * @dev An auxiliary function, Linear interpolation. 
     */ 
    function insertValue(uint256 x0,uint256 x1,uint256 y0, uint256 y1,uint256 x)internal pure returns (uint256){
        require(x1 != x0,"input values are duplicated!");
        return y0 + (y1-y0)*(x-x0)/(x1-x0);
    }

}
