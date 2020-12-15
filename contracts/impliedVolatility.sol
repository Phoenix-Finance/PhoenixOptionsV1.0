pragma solidity =0.5.16;
import "./modules/Operator.sol";
import "./modules/SmallNumbers.sol";
/**
 * @title Options Implied volatility calculation.
 * @dev A Smart-contract to calculate options Implied volatility.
 *
 */
contract ImpliedVolatility is Operator {
    //Implied volatility decimal, is same with oracle's price' decimal. 
    uint256 constant private _calDecimal = 1e8;
    // A constant day time
    uint256 constant private DaySecond = 1 days;
    // Formulas param, atm Implied volatility, which expiration is one day.
    struct ivParam {
        int48 a;
        int48 b;
        int48 c;
        int48 d;
        int48 e; 
    }
    mapping(uint32=>uint256) internal ATMIv0;
    // Formulas param A,B,C,D,E
    mapping(uint32=>ivParam) internal ivParamMap;
    // Formulas param ATM Iv Rate, sort by time
    mapping(uint32=>uint64[]) internal ATMIvRate;

    constructor () public{
        ATMIv0[1] = 48730000;
        ivParamMap[1] = ivParam(-38611755991,38654705664,-214748365,214748365,4294967296);
        ATMIvRate[1] = [4294967296,4446428991,4537492540,4603231970,4654878626,4697506868,4733852952,4765564595,4793712531,4819032567,
                4842052517,4863164090,4882666130,4900791915,4917727094,4933621868,4948599505,4962762438,4976196728,4988975383,
                5001160887,5012807130,5023960927,5034663202,5044949946,5054852979,5064400575,5073617969,5082527781,5091150366,
                5099504108,5107605667,5115470191,5123111489,5130542192,5137773878,5144817188,5151681926,5158377145,5164911220,
                5171291916,5177526445,5183621518,5189583392,5195417907,5201130526,5206726363,5212210216,5217586590,5222859721,
                5228033600,5233111985,5238098426,5242996276,5247808706,5252538720,5257189164,5261762736,5266262001,5270689395,
                5275047237,5279337732,5283562982,5287724992,5291825675,5295866857,5299850284,5303777626,5307650478,5311470372,
                5315238771,5318957082,5322626652,5326248774,5329824691,5333355597,5336842639,5340286922,5343689509,5347051421,
                5350373645,5353657131,5356902795,5360111520,5363284160,5366421536,5369524445,5372593655,5375629909,5378633924];
        ATMIv0[2] = 48730000;
        ivParamMap[2] = ivParam(-38611755991,38654705664,-214748365,214748365,4294967296);
        ATMIvRate[2] =  ATMIvRate[1];
        //mkr
        ATMIv0[3] = 150000000;
        ivParamMap[3] = ivParam(-38611755991,38654705664,-214748365,214748365,4294967296);
        ATMIvRate[3] =  ATMIvRate[1];
        //snx
        ATMIv0[4] = 200000000;
        ivParamMap[4] = ivParam(-38611755991,38654705664,-214748365,214748365,4294967296);
        ATMIvRate[4] =  ATMIvRate[1];
        //link
        ATMIv0[5] = 180000000;
        ivParamMap[5] = ivParam(-38611755991,38654705664,-214748365,214748365,4294967296);
        ATMIvRate[5] =  ATMIvRate[1];
    }
    /**
     * @dev set underlying's atm implied volatility. Foundation operator will modify it frequently.
     * @param underlying underlying ID.,1 for BTC, 2 for ETH
     * @param _Iv0 underlying's atm implied volatility. 
     */ 
    function SetAtmIv(uint32 underlying,uint256 _Iv0)public onlyOperatorIndex(0){
        ATMIv0[underlying] = _Iv0;
    }
    function getAtmIv(uint32 underlying)public view returns(uint256){
        return ATMIv0[underlying];
    }
    /**
     * @dev set implied volatility surface Formulas param. 
     * @param underlying underlying ID.,1 for BTC, 2 for ETH
     */ 
    function SetFormulasParam(uint32 underlying,int48 _paramA,int48 _paramB,int48 _paramC,int48 _paramD,int48 _paramE)
        public onlyOwner{
        ivParamMap[underlying] = ivParam(_paramA,_paramB,_paramC,_paramD,_paramE);
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
        if (underlying>2){
            return (ATMIv0[underlying]<<32)/_calDecimal;
        }
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
            return (ATMIv0[underlying]<<32)/_calDecimal;
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
        ivParam memory param = ivParamMap[underlying];
        int256 ln = calImpliedVolLn(underlying,currentPrice,strikePrice,param.d);
        //ln*ln+e
        uint256 lnSqrt = uint256(((ln*ln)>>32) + param.e);
        lnSqrt = SmallNumbers.sqrt(lnSqrt);
        //ln*c+sqrt
        ln = ((ln*param.c)>>32) + int256(lnSqrt);
        ln = (ln* param.b + int256(_ATMIv*_ATMIv))>>32;
        return SmallNumbers.sqrt(uint256(ln+param.a));
    }
    /**
     * @dev An auxiliary function, calculate ln price. 
     * @param underlying underlying ID.,1 for BTC, 2 for ETH
     * @param currentPrice underlying current price
     * @param strikePrice option's strike price
     */ 
    //ln(k) - ln(s) + d
    function calImpliedVolLn(uint32 underlying,uint256 currentPrice,uint256 strikePrice,int48 paramd)internal pure returns(int256){
        if (currentPrice == strikePrice){
            return paramd;
        }else if (currentPrice > strikePrice){
            return int256(SmallNumbers.fixedLoge((currentPrice<<32)/strikePrice))+paramd;
        }else{
            return -int256(SmallNumbers.fixedLoge((strikePrice<<32)/currentPrice))+paramd;
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
