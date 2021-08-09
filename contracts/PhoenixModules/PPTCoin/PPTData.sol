pragma solidity =0.5.16;
import "../proxyModules/versionUpdater.sol";
import "../ERC20/Erc20Data.sol";
import "../proxyModules/timeLimitation.sol";
import "../acceleratedMinePool/IAcceleratedMinePool.sol";
import "../proxyModules/proxyOperator.sol";
import "../proxyModules/poolLimit.sol";
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */
contract PPTData is Erc20Data,timeLimitation,poolLimit,proxyOperator,versionUpdater{
    /**
    * @dev lock mechanism is used when user redeem collateral and left collateral is insufficient.
    * _totalLockedWorth stores total locked worth, priced in USD.
    * lockedBalances stores user's locked PPTCoin.
    * lockedTotalWorth stores user's locked worth, priced in USD. For locked PPTCoin's net worth is constant when It was locked.
    */
    uint256 constant internal currentVersion = 3;
    function implementationVersion() public pure returns (uint256) 
    {
        return currentVersion;
    }
    uint256 internal _totalLockedWorth;
    IAcceleratedMinePool public minePool;
    mapping (address => uint256) internal lockedBalances;
    mapping (address => uint256) internal lockedTotalWorth;
    /**
     * @dev Emitted when `owner` locked  `amount` PPT, which net worth is  `worth` in USD. 
     */
    event AddLocked(address indexed owner, uint256 amount,uint256 worth);
    /**
     * @dev Emitted when `owner` burned locked  `amount` PPT, which net worth is  `worth` in USD. 
     */
    event BurnLocked(address indexed owner, uint256 amount,uint256 worth);

}