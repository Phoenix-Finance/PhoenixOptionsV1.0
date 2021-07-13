pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */
interface IAcceleratedMinePool {
    function setPHXVestingPool(address _accelerator) external;
    function changeAcceleratedInfo(address account,uint256[] calldata newRates,uint256 maxLockedPeriod) external;
    function transferPPTCoin(address account,address recieptor) external;
    function changePPTStake(address account) external;
}