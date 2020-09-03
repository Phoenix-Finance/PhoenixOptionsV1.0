pragma solidity =0.5.16;
import "../modules/Managerable.sol";
import "../modules/AddressWhiteList.sol";
import "../modules/ReentrancyGuard.sol";
/**
 * @title FPTCoin mine pool, which manager contract is FPTCoin.
 * @dev A smart-contract which distribute some mine coins by FPTCoin balance.
 *
 */
contract MinePoolData is Managerable,AddressWhiteList,ReentrancyGuard {
    //Special decimals for calculation
    uint256 constant calDecimals = 1e18;
    // miner's balance
    // map mineCoin => user => balance
    mapping(address=>mapping(address=>uint256)) internal minerBalances;
    // miner's origins, specially used for mine distribution
    // map mineCoin => user => balance
    mapping(address=>mapping(address=>uint256)) internal minerOrigins;
    
    // mine coins total worth, specially used for mine distribution
    mapping(address=>uint256) internal totalMinedWorth;
    // total distributed mine coin amount
    mapping(address=>uint256) internal totalMinedCoin;
    // latest time to settlement
    mapping(address=>uint256) internal latestSettleTime;
    //distributed mine amount
    mapping(address=>uint256) internal mineAmount;
    //distributed time interval
    mapping(address=>uint256) internal mineInterval;
    //distributed mine coin amount for buy options user.
    mapping(address=>uint256) internal buyingMineMap;
    // user's Opterator indicator 
    uint256 constant internal opBurnCoin = 1;
    uint256 constant internal opMintCoin = 2;
    uint256 constant internal opTransferCoin = 3;
    /**
     * @dev Emitted when `account` mint `amount` miner shares.
     */
    event MintMiner(address indexed account,uint256 amount);
    /**
     * @dev Emitted when `account` burn `amount` miner shares.
     */
    event BurnMiner(address indexed account,uint256 amount);
    /**
     * @dev Emitted when `from` redeem `value` mineCoins.
     */
    event RedeemMineCoin(address indexed from, address indexed mineCoin, uint256 value);
    /**
     * @dev Emitted when `from` transfer to `to` `amount` mineCoins.
     */
    event TranserMiner(address indexed from, address indexed to, uint256 amount);
    /**
     * @dev Emitted when `account` buying options get `amount` mineCoins.
     */
    event BuyingMiner(address indexed account,address indexed mineCoin,uint256 amount);
}