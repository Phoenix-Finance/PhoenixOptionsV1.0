pragma solidity =0.5.16;
import "../PhoenixModules/proxyModules/versionUpdater.sol";
import "../PhoenixModules/proxyModules/proxyOperator.sol";
import "../PhoenixModules/modules/ReentrancyGuard.sol";
import "../PhoenixModules/modules/safeTransfer.sol";
import "../OptionsPool/IOptionsPool.sol";
/**
 * @title collateral pool contract with coin and necessary storage data.
 * @dev A smart-contract which stores user's deposited collateral.
 *
 */
contract CollateralData is versionUpdater,proxyOperator,ReentrancyGuard,safeTransfer{
    uint256 constant internal currentVersion = 1;
    function implementationVersion() public pure returns (uint256) 
    {
        return currentVersion;
    }
    IOptionsPool public optionsPool;
    // The total fees accumulated in the contract
    mapping (address => uint256) 	internal feeBalances;
    uint32[] internal FeeRates;
     /**
     * @dev Returns the rate of trasaction fee.
     */   
    uint256 constant internal buyFee = 0;
    uint256 constant internal sellFee = 1;
    uint256 constant internal exerciseFee = 2;
    uint256 constant internal addColFee = 3;
    uint256 constant internal redeemColFee = 4;
    event AddFee(address indexed settlement,uint256 payback);

    //token net worth balance
    mapping (address => int256) internal netWorthBalances;
    //total user deposited collateral balance
    // map from collateral address to amount
    mapping (address => uint256) internal collateralBalances;
    //user total paying for collateral, priced in usd;
    mapping (address => uint256) internal userCollateralPaying;
    //user original deposited collateral.
    //map account -> collateral -> amount
    mapping (address => mapping (address => uint256)) internal userInputCollateral;

}