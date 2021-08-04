pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * FinNexus
 * Copyright (C) 2020 FinNexus Options Protocol
 */
import "../PhoenixModules/modules/SafeMath.sol";
import "../PhoenixModules/PHXVestingPool/PHXVestingPool.sol";
/**
 * @title FPTCoin mine pool, which manager contract is FPTCoin.
 * @dev A smart-contract which distribute some mine coins by FPTCoin balance.
 *
 */
contract PHXVestingPool_Timed is PHXVestingPool {
    uint256 _timeAccumulation;
    using SafeMath for uint256;
    constructor(address multiSignature)public PHXVestingPool(multiSignature){
    }
    function setTime(uint256 _time) public{
        _timeAccumulation = _time;
    }
    function getPeriodIndex(uint256 _time) public view returns (uint64) {
        if (_time<startTime){
            return 0;
        }
        return (uint64(_time-startTime)/10+1);
    }
    function getPeriodFinishTime(uint64 periodID)public view returns (uint256) {
        return periodID*10+startTime;
    }
    function currentTime() internal view returns (uint256){
        return _timeAccumulation;
    }
}