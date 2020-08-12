pragma solidity ^0.4.26;
import "./modules/Operator.sol";
import "./modules/Fraction.sol";
contract ImpliedVolatility is Operator {
    using Fraction for Fraction.fractionNumber;
    uint256 constant private _calDecimal = 1e8;
    uint256 constant private DaySecond = 1 days;
    mapping(uint32=>uint256) internal ATMIv0;
    mapping(uint32=>int256) internal paramA;
    mapping(uint32=>int256) internal paramB;
    mapping(uint32=>int256) internal paramC;
    mapping(uint32=>int256) internal paramD;
    mapping(uint32=>int256) internal paramE;
    mapping(uint32=>uint256[]) internal ATMIvRate;
    event DebugEvent(uint256 indexed value1,uint256 indexed value2,uint256 indexed value3);
    event DebugEventInt(int256 value1,int256 value2,int256 value3);
    mapping(address=>uint256) internal debugMap;
    constructor () public{
        ATMIv0[1] = 48730000;
        ATMIv0[2] = 48730000;
        paramA[1] = -4993746098;
        paramA[2] = -4993746098;
        paramB[1] = 50e8;
        paramB[2] = 50e8;
        paramC[1] = -5000000;
        paramC[2] = -5000000;
        paramD[1] = 5000000;
        paramD[2] = 5000000;
        paramE[1] = 1e8;
        paramE[2] = 1e8;
        ATMIvRate[1] = [100000000,108673486,114091831,118099266,121304357,123987570,126302447,128342590,130169459,131825674,
                        133342048,134741615,136042061,137257272,138398362,139474367,140492736,141459690,142380473,143259556,
                        144100775,144907453,145682485,146428411,147147471,147841650,148512720,149162263,149791703,150402325,
                        150995291,151571657,152132385,152678354,153210371,153729176,154235451,154729824,155212878,155685153,
                        156147150,156599335,157042144,157475981,157901226,158318235,158727342,159128859,159523081,159910286,
                        160290735,160664676,161032340,161393950,161749714,162099831,162444489,162783866,163118133,163447450,
                        163771973,164091847,164407212,164718203,165024947,165327566,165626177,165920890,166211815,166499052,
                        166782701,167062855,167339606,167613041,167883244,168150294,168414270,168675246,168933294,169188484,
                        169440882,169690552,169937557,170181957,170423810,170663172,170900097,171134638,171366845,171596767];
         ATMIvRate[2] =  ATMIvRate[1];
    }
    function SetAtmIv(uint32 underlying,uint256 _Iv0)public onlyOperatorIndex(0){
        ATMIv0[underlying] = _Iv0;
    }
    function SetFormulasParam(uint32 underlying,int256 _paramA,int256 _paramB,int256 _paramC,int256 _paramD,int256 _paramE)
        public onlyOwner{
        paramA[underlying] = _paramA;
        paramB[underlying] = _paramB;
        paramC[underlying] = _paramC;
        paramD[underlying] = _paramD;
        paramE[underlying] = _paramE;
    }
    function SetATMIvRate(uint32 underlying,uint256[] IvRate)public onlyOwner{
        ATMIvRate[underlying] = IvRate;
    }
    function calculateIv(uint32 underlying,uint8 optType,uint256 expiration,uint256 currentPrice,uint256 strikePrice)public view returns (uint256,uint256){
        uint256 iv = calATMIv(underlying,expiration);
        if (currentPrice == strikePrice){
            return (iv,_calDecimal);
        }
        return (calImpliedVolatility(underlying,iv,currentPrice,strikePrice),_calDecimal);
    }
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
    function calImpliedVolatility(uint32 underlying,uint256 _ATMIv,uint256 currentPrice,uint256 strikePrice)internal view returns(uint256){
        int256 intDecimal = int256(_calDecimal);
        Fraction.fractionNumber memory ln = calImpliedVolLn(underlying,currentPrice,strikePrice);
        //ln*ln+e
        Fraction.fractionNumber memory lnSqrt = ln.mul(ln).add(Fraction.fractionNumber(paramE[underlying],intDecimal)); 
        lnSqrt.numerator = lnSqrt.numerator*intDecimal*intDecimal;
        lnSqrt = lnSqrt.sqrt();  
        lnSqrt.numerator = lnSqrt.numerator*intDecimal;
        //ln*c+sqrt
        ln.numerator = ln.numerator*paramC[underlying]*intDecimal;
        ln = ln.add(lnSqrt);

        ln = ln.mul(Fraction.fractionNumber(paramB[underlying],intDecimal));
        ln = ln.add(Fraction.fractionNumber(paramA[underlying]*intDecimal,1));
        ln = ln.add(Fraction.fractionNumber(int256(_ATMIv*_ATMIv),1));
        uint256 sqrtNum = uint256(ln.numerator/ln.denominator);
        return Fraction.sqrt(sqrtNum);
    }
    //ln(k) - ln(s) + d
    function calImpliedVolLn(uint32 underlying,uint256 currentPrice,uint256 strikePrice)internal view returns(Fraction.fractionNumber memory){
        if (currentPrice == strikePrice){
            return Fraction.fractionNumber(paramD[underlying],int256(_calDecimal));
        }
        Fraction.fractionNumber memory ln = Fraction.ln(currentPrice).sub(Fraction.ln(strikePrice));
        return ln.add(Fraction.fractionNumber(paramD[underlying],int256(_calDecimal)));
    }
    function insertValue(uint256 x0,uint256 x1,uint256 y0, uint256 y1,uint256 x)internal pure returns (uint256){
        require(x1 != x0,"input values are duplicated!");
        return y0 + (y1-y0)*(x-x0)/(x1-x0);
    }

}
