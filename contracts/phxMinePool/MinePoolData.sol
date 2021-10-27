// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.5.16;
import "../PhoenixModules/proxyModules/versionUpdater.sol";
import "../PhoenixModules/modules/whiteListAddress.sol";
import "../PhoenixModules/modules/ReentrancyGuard.sol";
import "../PhoenixModules/modules/safeTransfer.sol";
import "../PhoenixModules/proxyModules/Halt.sol";
/**
 * @title systemCoin mine pool, which manager contract is systemCoin.
 * @dev A smart-contract which distribute some mine coins by systemCoin balance.
 *
 */
contract MinePoolData is Halt,versionUpdater,safeTransfer,ReentrancyGuard {
    uint256 constant internal currentVersion = 2;
    function implementationVersion() public pure returns (uint256) 
    {
        return currentVersion;
    }
    address public stakeCoin;
    // The eligible adress list
    address[] internal whiteList;
    //Special decimals for calculation
    uint256 constant calDecimals = 1e18;
    uint256 constant rayDecimals = 1e27;
    // miner's balance
    // map mineCoin => user => balance
    mapping(address=>mapping(address=>uint256)) internal minerBalances;
    // miner's origins, specially used for mine distribution
    // map mineCoin => user => balance
    mapping(address=>mapping(address=>uint256)) internal minerOrigins;
    
    // mine coins total worth, specially used for mine distribution
    mapping(address=>uint256) internal mineNetworth;
    // total distributed mine coin amount
    mapping(address=>uint256) internal totalMinedCoin;
    // latest time to settlement
    mapping(address=>uint256) internal latestSettleTime;
    //distributed mine amount
    mapping(address=>uint256) internal mineAmount;
    //distributed time interval
    mapping(address=>uint256) internal mineInterval;

    mapping(address=>uint256) internal distributeBalance;
    uint256 internal _totalsupply;

    event SetMineCoinInfo(address indexed from,address indexed mineCoin,uint256 _mineAmount,uint256 _mineInterval);
    event Stake(address indexed from, uint256 amount);
    event UnStake(address indexed from, uint256 amount);
    event ChangeUserbalance(address indexed Account,int256 amount);
    event RedeemMineCoin(address indexed from, address indexed mineCoin, uint256 value);    
}