pragma solidity =0.5.16;
import "../modules/Managerable.sol";
import "../modules/AddressWhiteList.sol";
import "../OptionsPool/IOptionsPool.sol";
import "../modules/Operator.sol";
/**
 * @title collateral pool contract with coin and necessary storage data.
 * @dev A smart-contract which stores user's deposited collateral.
 *
 */
contract CollateralData is AddressWhiteList,Managerable,Operator,ImportOptionsPool{
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
    event RedeemFee(address indexed recieptor,address indexed settlement,uint256 payback);
    event AddFee(address indexed settlement,uint256 payback);
    event TransferPayback(address indexed recieptor,address indexed settlement,uint256 payback);

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