pragma solidity =0.5.16;
import "../modules/Managerable.sol";
import "../interfaces/IFNXOracle.sol";
import "../modules/underlyingAssets.sol";
import "../interfaces/IVolatility.sol";
import "../interfaces/IOptionsPrice.sol";
import "../modules/Operator.sol";
import "../modules/ImputRange.sol";
contract OptionsData is UnderlyingAssets,ImputRange,Managerable,ImportOracle,ImportVolatility,ImportOptionsPrice,Operator{

        // store option info
        struct OptionsInfo {
        address     owner;      // option's owner
        uint8   	optType;    //0 for call, 1 for put
        uint24		underlying; // underlying ID, 1 for BTC,2 for ETH
        uint64      optionsPrice;

        address     settlement;    //user's settlement paying for option. 
        uint64      createTime;
        uint32		expiration; //


        uint128     amount; 
        uint128     settlePrice;

        uint128     strikePrice;    //  strike price		
        uint32      priceRate;    //underlying Price	
        uint64      iv;
        uint32      extra;
    }

    uint256 internal limitation = 1 hours;
    //all options information list
    OptionsInfo[] internal allOptions;
    //user options balances
    mapping(address=>uint64[]) internal optionsBalances;
    //expiration whitelist
    uint32[] internal expirationList;
    
    // first option position which is needed calculate.
    uint256 internal netWorthirstOption;
    // options latest networth balance. store all options's net worth share started from first option.
    mapping(address=>int256) internal optionsLatestNetWorth;

    // first option position which is needed calculate.
    uint256 internal occupiedFirstOption; 
    //latest calcutated Options Occupied value.
    uint256 internal callOccupied;
    uint256 internal putOccupied;
    //latest Options volatile occupied value when bought or selled options.
    int256 internal callLatestOccupied;
    int256 internal putLatestOccupied;

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
/*
contract OptionsDataV2 is OptionsData{
        // store option info
    struct OptionsInfoV2 {
        uint64     optionID;    //an increasing nubmer id, begin from one.
        uint64		expiration; // Expiration timestamp
        uint128     strikePrice;    //strike price
        uint8   	optType;    //0 for call, 1 for put
        uint32		underlying; // underlying ID, 1 for BTC,2 for ETH
        address     owner;      // option's owner
        uint256     amount;         // mint amount
    }
    // store option extra info
    struct OptionsInfoExV2 {
        address      settlement;    //user's settlement paying for option. 
        uint128      tokenTimePrice; //option's buying price based on settlement, used for options share calculation
        uint128      underlyingPrice;//underlying price when option is created.
        uint128      fullPrice;      //option's buying price.
        uint128      ivNumerator;   // option's iv numerator when option is created.
//        uint256      ivDenominator;// option's iv denominator when option is created.
    }
        //all options information list
    OptionsInfoV2[] internal allOptionsV2;
    // all option's extra information map
    mapping(uint256=>OptionsInfoExV2) internal optionExtraMapV2;
        //user options balances
//    mapping(address=>uint64[]) internal optionsBalancesV2;
}
*/