pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */
import "../phxMinePool/phxAutoMinePool.sol";
/**
 * @title PHX mine pool, which manager contract is FPTCoin.
 * @dev A smart-contract which distribute some mine coins by PHX balance.
 *
 */
contract phxAutoMinePoolTest is phxAutoMinePool {
    uint256 public timeAccumulation;
    using SafeMath for uint256;
    constructor(address multiSignature)public phxAutoMinePool(multiSignature){
    }
    function totalDistribute() public view returns (uint256){
        return totalSupply();
    }
    function setTime(uint256 _time) public{
        timeAccumulation = _time;
    }
    function currentTime() internal view returns (uint256){
        return timeAccumulation;
    }
}