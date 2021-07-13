pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */
interface IPPTCoin {
    function lockedBalanceOf(address account) external view returns (uint256);
    function getLockedBalance(address account) external view returns (uint256,uint256);
    function setTimeLimitation(uint256 _limitation) external;
    function changeTokenName(string calldata _name, string calldata _symbol,uint8 _decimals)external;
    function lockedWorthOf(address account) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
    function setMinePool(address acceleratedMinePool) external;
    function getTotalLockedWorth() external view returns (uint256);
    function redeemLockedCollateral(address account,uint256 tokenAmount,uint256 leftCollateral)external returns (uint256,uint256);
    function addlockBalance(address account, uint256 amount,uint256 lockedWorth)external; 
}
