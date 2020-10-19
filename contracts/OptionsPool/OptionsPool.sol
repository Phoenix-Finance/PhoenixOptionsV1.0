pragma solidity =0.5.16;
import "./OptionsNetWorthCal.sol";
/**
 * @title Options pool contract.
 * @dev store options' information and nessesary options' calculation.
 *
 */
contract OptionsPool is OptionsNetWorthCal {
    /**
     * @dev constructor function , setting contract address.
     * @param oracleAddr FNX oracle contract address
     * @param optionsPriceAddr options price contract address
     * @param ivAddress implied volatility contract address
     */  
    constructor (address oracleAddr,address optionsPriceAddr,address ivAddress)public{
        _oracle = IFNXOracle(oracleAddr);
        _optionsPrice = IOptionsPrice(optionsPriceAddr);
        _volatility = IVolatility(ivAddress);
    }
    function update() onlyOwner public {
        
    }
    /**
     * @dev retrieve all information for collateral occupied and net worth calculation.
     * @param whiteList settlement address whitelist.
     */ 
    function getOptionCalRangeAll(address[] memory whiteList)public view returns(uint256,int256,int256,uint256,int256[] memory,uint256,uint256){
        (uint256 occupiedFirst,int256 callOccupiedlatest,int256 putOccupiedlatest) = getOccupiedCalInfo();
        (uint256 netFirst,int256[] memory netLatest) = getNetWrothCalInfo(whiteList);
        return (occupiedFirst,callOccupiedlatest,putOccupiedlatest,netFirst,netLatest,allOptions.length,block.number);
    }
    /**
     * @dev create new option,modify collateral occupied and net worth value, only manager contract can invoke this.
     * @param from user's address.
     * @param settlement user's input settlement coin.
     * @param type_ly_exp tuple64 for option type,underlying,expiration.
     * @param strikePrice user's input new option's strike price.
     * @param optionPrice current new option's price, calculated by options price contract.
     * @param amount user's input new option's amount.
     */ 
    function createOptions(address from,address settlement,uint256 type_ly_exp,uint256 strikePrice,uint256 optionPrice,
                uint256 amount) onlyManager  Smaller(amount) public {
        _createOptions(from,settlement,type_ly_exp,strikePrice,optionPrice,amount);
        OptionsInfo memory info = _getOptionsById(allOptions.length);
        _addOptionsCollateral(info);
//        _addNewOptionsNetworth(info);
    }
    /**
     * @dev burn option,modify collateral occupied and net worth value, only manager contract can invoke this.
     * @param from user's address.
     * @param id user's input option's id.
     * @param amount user's input burned option's amount.
     * @param optionPrice current new option's price, calculated by options price contract.
     */ 
    function burnOptions(address from,uint256 id,uint256 amount,uint256 optionPrice)public onlyManager Smaller(amount) OutLimitation(id){
        _burnOptions(from,id,amount);
        OptionsInfo memory info = _getOptionsById(id);
        uint256 currentPrice = oracleUnderlyingPrice(info.underlying);
        _burnOptionsCollateral(info,amount,currentPrice);
        _burnOptionsNetworth(info,amount,currentPrice,optionPrice);
    }
}