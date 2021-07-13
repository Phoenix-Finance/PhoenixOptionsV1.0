pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */
import "../proxyModules/proxyOperator.sol";
import "../modules/ReentrancyGuard.sol";
import "../proxyModules/versionUpdater.sol";
import "../modules/safeTransfer.sol";
import "../modules/whiteListAddress.sol";
import "../proxyModules/Halt.sol";
/**
 * @title new Phoenix Options Pool token mine pool.
 * @dev A smart-contract which distribute some mine coins when you stake some PHX coins.
 *      Users who both stake some PHX coins will get more bonus in mine pool.
 *      Users who Lock PHX coins will get several times than normal miners.
 */
 interface IPHXVestingPool {
    function getAcceleratedBalance(address account,address minePool)external view returns(uint256,uint64); 
    function getAcceleratorPeriodInfo()external view returns (uint256,uint256);
}
contract acceleratedMinePoolData is versionUpdater,Halt,proxyOperator,safeTransfer,ReentrancyGuard {
    uint256 constant internal currentVersion = 1;
    function implementationVersion() public pure returns (uint256) 
    {
        return currentVersion;
    }
    using whiteListAddress for address[];
    // The eligible adress list
    address[] internal whiteList;
    //Special decimals for calculation
    uint256 constant calDecimals = 1e18;
    uint256 constant internal rateDecimal = 1e8;

    //The max loop when user does nothing to this pool for long long time .
    uint256 constant internal _maxLoop = 120;

    IPHXVestingPool public vestingPool;
    uint256 public acceleratorStart;
    uint256 public acceleratorPeriod;
    struct userInfo {
        //user's PPT staked balance
        uint256 pptBalance;
        //User's mine distribution.You can get base mine proportion by your distribution divided by total distribution.
        uint256 distribution;
        uint256 maxPeriodID;
        uint256[] periodRates;
        //User's settled mine coin balance.
        mapping(address=>uint256) minerBalances;
        //User's latest settled distribution net worth.
        mapping(address=>uint256) minerOrigins;
        //user's latest settlement period for each token.
        mapping(address=>uint256) settlePeriod;
    }
    struct tokenMineInfo {
        //mine distribution amount
        uint256 mineAmount;
        //mine distribution time interval
        uint256 mineInterval;
        //mine distribution first period
        uint256 startPeriod;
        //mine coin latest settlement time
        uint256 latestSettleTime;
        //latest distribution net worth;
        uint256 minedNetWorth;
        //period latest distribution net worth;
        mapping(uint256=>uint256) periodMinedNetWorth;
    }

    //User's staking and mining info.
    mapping(address=>userInfo) internal userInfoMap;
    //each mine coin's mining info.
    mapping(address=>tokenMineInfo) internal mineInfoMap;
    //total Distribution
    uint256 internal totalDistribution;
    uint256 public startTime;

    /**
     * @dev Emitted when `account` stake `amount` PPT coin.
     */
    event StakePPT(address indexed account,uint256 amount);
    /**
     * @dev Emitted when `account` unstake `amount` PPT coin.
     */
    event UnstakePPT(address indexed account,uint256 amount);

    /**
     * @dev Emitted when `account` redeem `value` mineCoins.
     */
    event RedeemMineCoin(address indexed account, address indexed mineCoin, uint256 value);

}
