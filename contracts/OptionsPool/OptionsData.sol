pragma solidity ^0.5.1;
import "../modules/Managerable.sol";
import "../interfaces/IFNXOracle.sol";
import "../modules/underlyingAssets.sol";
import "../interfaces/IVolatility.sol";
import "../interfaces/IOptionsPrice.sol";
import "../modules/Operator.sol";
contract OptionsData is UnderlyingAssets,Managerable,ImportOracle,ImportVolatility,ImportOptionsPrice,Operator{
        // store option info
    struct OptionsInfo {
        uint64     optionID;    //an increasing nubmer id, begin from one.
        address     owner;      // option's owner
        uint8   	optType;    //0 for call, 1 for put
        uint32		underlying; // underlying ID, 1 for BTC,2 for ETH
        uint256		expiration; // Expiration timestamp
        uint256     strikePrice;    //strike price
        uint256     amount;         // mint amount
    }
    // store option extra info
    struct OptionsInfoEx{
        uint256		 createdTime;   //option's created timestamp
        address      settlement;    //user's settlement paying for option. 
        uint256      tokenTimePrice; //option's buying price based on settlement, used for options share calculation
        uint256      underlyingPrice;//underlying price when option is created.
        uint256      fullPrice;      //option's buying price.
        uint256      ivNumerator;   // option's iv numerator when option is created.
        uint256      ivDenominator;// option's iv denominator when option is created.
    }
    //all options information list
    OptionsInfo[] internal allOptions;
    // all option's extra information map
    mapping(uint256=>OptionsInfoEx) internal optionExtraMap;
    // option share value calculation's decimal
    uint256 constant internal calDecimals = 1e18;
    //user options balances
    mapping(address=>uint256[]) internal optionsBalances;
    //expiration whitelist
    uint256[] internal expirationList;
    //option burn limit time from option's created.
    uint256 internal burnTimeLimit = 1 hours;


    
    // first option position which is needed calculate.
    uint256 internal netWorthirstOption;
    // options latest networth balance. store all options's net worth share started from first option.
    mapping(address=>int256) internal optionsLatestNetWorth;

    // first option position which is needed calculate.
    uint256 internal occupiedFirstOption; 
    //latest calcutated Options Occupied value.
    uint256 internal optionsOccupied;
    //latest Options volatile occupied value when bought or selled options.
    int256 internal optionsLatestOccupied;

    /**
     * @dev Emitted when `owner` create a new option. 
     * @param owner new option's owner
     * @param optionID new option's id
     * @param optionID new option's type 
     * @param underlying new option's underlying 
     * @param expiration new option's expiration timestamp
     * @param strikePrice  new option's strikePrice
     * @param amount  new option's amount
     */
    event CreateOption(address indexed owner,uint256 indexed optionID,uint8 optType,uint32 underlying,uint256 expiration,uint256 strikePrice,uint256 amount);
    /**
     * @dev Emitted when `owner` burn `amount` his option which id is `optionID`. 
     */    
    event BurnOption(address indexed owner,uint256 indexed optionID,uint amount);
}