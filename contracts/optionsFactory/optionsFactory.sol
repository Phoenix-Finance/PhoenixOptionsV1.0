pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */
import "../PhoenixModules/modules/SafeMath.sol";
import "./optionsFactoryData.sol";
import "../PhoenixModules/proxy/phxProxy.sol";
import "../PhoenixModules/ERC20/IERC20.sol";
import "../PhoenixModules/acceleratedMinePool/IAcceleratedMinePool.sol";
import "../PhoenixModules/PPTCoin/IPPTCoin.sol";
import "../PhoenixModules/modules/Address.sol";
import "../OptionsPool/IOptionsPool.sol";
import "../CollateralPool/ICollateralPool.sol";
import "../OptionsManager/IOptionsManager.sol";
/**
 * @title leverage contract factory.
 * @dev A smart-contract which manage leverage smart-contract's and peripheries.
 *
 */
contract optionsFactory is optionsFactoryData{
    using SafeMath for uint256;
    using Address for address;
    /**
     * @dev constructor.
     */
    constructor (address multiSignature) proxyOwner(multiSignature) public{
    }

    function initialize() public{
        versionUpdater.initialize();
        //debug
        PPTTimeLimit = 3600;
        PPTname = 65;
    }
    function update() public versionUpdate {
    }

    function setImplementAddress(string memory _baseCoinName,
        address _optionsCalImpl,address _optionsPoolImpl,address _collateralPoolImpl,address _optionsManagerImpl,address _PPTCoinImpl,
        address acceleratedMinePool,address phxVestingPool,address _phxOracle,address _volatility,address _optionsPrice)public originOnce{
        baseCoinName = _baseCoinName;
        proxyinfoMap[optionsPoolID].implementation = _optionsPoolImpl;
        proxyinfoMap[collateralPoolID].implementation = _collateralPoolImpl;
        proxyinfoMap[optionsManagerID].implementation = _optionsManagerImpl;
        proxyinfoMap[PPTTokenID].implementation = _PPTCoinImpl;
        proxyinfoMap[MinePoolID].implementation = acceleratedMinePool;
        optionsCal = _optionsCalImpl;
        vestingPool = phxVestingPool;  
        phxOracle = _phxOracle;
        impliedVolatility = _volatility;
        optionsPrice = _optionsPrice;
    }
    function createOptionsManager(address[] calldata collateral,uint256[] calldata rate,uint32[] calldata underlyings)external onlyOrigin {
        address payable optionsPool = createOptionsPool(underlyings);
        address pptCoin = createPPTCoin();
        address payable collateralPool = createCollateralPool(optionsPool);
        address payable optionsManager = createPhxProxy(optionsManagerID);
        proxyOperator(collateralPool).setManager(optionsManager);
        proxyOperator(optionsPool).setManager(optionsManager);
        proxyOperator(pptCoin).setManager(optionsManager);
        IOptionsManager(optionsManager).initAddresses(collateral,rate,phxOracle,optionsPrice,
            optionsPool,collateralPool,pptCoin);
        optionsManagerInfo.push(managerInfo(optionsManager,collateralPool,optionsPool,pptCoin));
    }
    function getOptionsMangerLength()external view returns (uint256){
        return optionsManagerInfo.length;
    }
    function getOptionsMangerAddress(uint256 index)external view returns (address,address,address,address){
        require(index<optionsManagerInfo.length,"options manager index is overflow!");
        return (optionsManagerInfo[index].optionsManager,optionsManagerInfo[index].collateralPool,
            optionsManagerInfo[index].optionsPool,optionsManagerInfo[index].pptCoin);
    }
    function createCollateralPool(address optionsPool)internal returns(address payable){
        address payable collateralPool = createPhxProxy(collateralPoolID);
        ICollateralPool(collateralPool).setOptionsPoolAddress(optionsPool);
        proxyOperator(optionsPool).setOperator(99, collateralPool);
        return collateralPool;        
    }
    function createOptionsPool(uint32[] memory underlyings)internal returns(address payable){
        address payable optionsPool = createPhxProxy(optionsPoolID);
        IOptionsPool(optionsPool).initAddresses(optionsCal,phxOracle,optionsPrice,impliedVolatility,underlyings);
        return optionsPool;
    }
    function createPPTCoin()internal returns(address){
        address payable newCoin = createPhxProxy(PPTTokenID);
        string memory tokenName = string(abi.encodePacked("PPT_", PPTname));
        PPTname++;
        IPPTCoin(newCoin).changeTokenName(tokenName,tokenName,18);
        IPPTCoin(newCoin).setTimeLimitation(PPTTimeLimit);
        address minePool = createAcceleratedMinePool();
        proxyOperator(minePool).setManager(newCoin);
        IPPTCoin(newCoin).setMinePool(minePool);
        return newCoin;
    }
    function createAcceleratedMinePool()internal returns(address){
        address payable newCoin = createPhxProxy(MinePoolID);
        IAcceleratedMinePool(newCoin).setPHXVestingPool(vestingPool);
        return newCoin;
    }
    function createPhxProxy(uint256 index) internal returns (address payable){
        proxyInfo storage curInfo = proxyinfoMap[index];
        phxProxy newProxy = new phxProxy(curInfo.implementation,getMultiSignatureAddress());
        curInfo.proxyList.push(address(newProxy));
        return address(newProxy);
    }
    function setContractsInfo(uint256 index,bytes memory data)internal{
        proxyInfo storage curInfo = proxyinfoMap[index];
        uint256 len = curInfo.proxyList.length;
        for(uint256 i = 0;i<len;i++){
            Address.functionCall(curInfo.proxyList[i],data,"setContractsInfo error");
        }
    }
    function setPHXVestingPool(address _PHXVestingPool) public onlyOrigin{
        vestingPool = _PHXVestingPool;
        setContractsInfo(MinePoolID,abi.encodeWithSignature("setPHXVestingPool(address)",_PHXVestingPool));
    }
    function setOracleAddress(address _phxOracle)public onlyOrigin{
        phxOracle = _phxOracle;
        setContractsInfo(optionsPoolID,abi.encodeWithSignature("setOracleAddress(address)",_phxOracle));
        setContractsInfo(optionsManagerID,abi.encodeWithSignature("setOracleAddress(address)",_phxOracle));
    }
    function setPPTTimeLimit(uint32 _PPTTimeLimit) public onlyOrigin{
        PPTTimeLimit = _PPTTimeLimit;
        setContractsInfo(PPTTokenID,abi.encodeWithSignature("setTimeLimitation(uint256)",_PPTTimeLimit));
    }
    function upgradePhxProxy(uint256 index,address implementation) public onlyOrigin{
        proxyInfo storage curInfo = proxyinfoMap[index];
        curInfo.implementation = implementation;
        uint256 len = curInfo.proxyList.length;
        for(uint256 i = 0;i<len;i++){
            phxProxy(curInfo.proxyList[i]).upgradeTo(implementation);
        }        
    }

}