pragma solidity =0.5.16;

import "../PhoenixModules/proxyModules/versionUpdater.sol";
import "../PhoenixModules/proxyModules/ImputRange.sol";
import "../PhoenixModules/interface/IPHXOracle.sol";
import "../interfaces/IVolatility.sol";
import "../interfaces/IOptionsPrice.sol";
contract OptionsData is versionUpdater,ImputRange,ImportOracle{
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
    struct underlyingOccupied {
        //latest calcutated Options Occupied value.
        uint256 callOccupied;
        uint256 putOccupied;
        //latest Options volatile occupied value when bought or selled options.
        int256 callLatestOccupied;
        int256 putLatestOccupied;
    }
    uint256 constant internal currentVersion = 1;
    function implementationVersion() public pure returns (uint256) 
    {
        return currentVersion;
    }
    IVolatility public volatility;
    IOptionsPrice public optionsPrice;
    uint32[] public underlyingAssets;
    uint256 public limitation;
    //all options information list
    OptionsInfo[] public allOptions;
    //user options balances
    mapping(address=>uint64[]) public optionsBalances;
    //expiration whitelist
    uint32[] public expirationList;
    
    // first option position which is needed calculate.
    uint256 public netWorthFirstOption;
    // options latest networth balance. store all options's net worth share started from first option.
    mapping(address=>int256) public optionsLatestNetWorth;

    // first option position which is needed calculate.
    uint256 internal occupiedFirstOption; 
    mapping(uint32=>underlyingOccupied) public underlyingOccupiedMap;
    uint256 public underlyingTotalOccupied;
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