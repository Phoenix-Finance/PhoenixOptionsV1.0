pragma solidity >=0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */
import './proxyOwner.sol';

contract poolLimit is proxyOwner {
    uint256 public totalLimit;
    uint256 public userLimit;
    function modifyLimitation(uint256 _totalLimit,uint256 _userLimit)public OwnerOrOrigin {
        totalLimit = _totalLimit;
        userLimit = _userLimit;
    }
    modifier belowTotalLimit(uint256 allInput){
        require(allInput<=totalLimit, "Input amount is exceeded pool total limit!");
        _;
    }
    modifier belowUserLimit(uint256 userInput){
        require(userInput<=userLimit, "Input amount is exceeded user limit!");
        _;
    }
}