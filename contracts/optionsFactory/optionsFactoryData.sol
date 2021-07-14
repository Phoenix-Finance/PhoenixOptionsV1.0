pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */
import "../PhoenixModules/proxyModules/versionUpdater.sol";
import "../PhoenixModules/proxyModules/proxyOperator.sol";
contract optionsFactoryData is versionUpdater,proxyOperator{

    uint256 constant internal currentVersion = 1;
    function implementationVersion() public pure returns (uint256) 
    {
        return currentVersion;
    }
    string public baseCoinName;
    uint256 constant public optionsPoolID = 0;
    uint256 constant public collateralPoolID = 1;
    uint256 constant public optionsManagerID = 2;
    uint256 constant public PPTTokenID = 3;
    uint256 constant public MinePoolID = 4;
    struct proxyInfo {
        address implementation;
        address payable[] proxyList;
    }
    mapping(uint256=>proxyInfo) public proxyinfoMap;
    struct managerInfo {
        address optionsManager;
        address collateralPool;
        address optionsPool;
        address pptCoin;
    }
    managerInfo[] internal optionsManagerInfo;
    address public optionsCal;
    address public phxOracle;
    uint64 public PPTTimeLimit;
    uint8 public PPTname;
    address public impliedVolatility;
    address public optionsPrice;
    address public vestingPool;
    event CreateOptionsManager(address indexed optionsManager,address collateralPool,address optionsPool,address pptCoin);
}