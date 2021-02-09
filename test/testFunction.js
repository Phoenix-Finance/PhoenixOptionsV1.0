const BN = require("bn.js");

const ImpliedVolatility = artifacts.require("ImpliedVolatility");

let FNXCoin = artifacts.require("FNXCoin");
let Erc20Proxy = artifacts.require("Erc20Proxy");
let USDCoin = artifacts.require("USDCoin");

let OptionsPool = artifacts.require("OptionsPool");
let OptionsProxy = artifacts.require("OptionsProxy");

let FNXMinePool = artifacts.require("FNXMinePool");
let MinePoolProxy = artifacts.require("MinePoolProxy");

const OptionsManagerV2 = artifacts.require("OptionsManagerV2");
const ManagerProxy = artifacts.require("ManagerProxy");

let FPTCoin = artifacts.require("FPTCoin");
let FPTProxy = artifacts.require("FPTProxy");
let IERC20 = artifacts.require("IERC20");

let CollateralPool = artifacts.require("CollateralPool");
let CollateralProxy = artifacts.require("CollateralProxy");
const FNXOracle = artifacts.require("TestFNXOracle");
const OptionsPrice = artifacts.require("OptionsPriceTest");

let collateral0 = "0x0000000000000000000000000000000000000000";
exports.migration =  async function (accounts){
    let ivInstance = await ImpliedVolatility.new();
    let oracleInstance = await FNXOracle.new();
    let price = await OptionsPrice.new(ivInstance.address);
    let pool = await OptionsPool.new(oracleInstance.address,price.address,ivInstance.address);
    let options = await OptionsProxy.new(pool.address,oracleInstance.address,price.address,ivInstance.address);
    pool = await FNXMinePool.new();
    let poolProxy = await MinePoolProxy.new(pool.address);
    let fptimpl = await FPTCoin.new(poolProxy.address,"FPT-A");
    let fpt = await FPTProxy.new(fptimpl.address,poolProxy.address,"FPT-A");

    let collateral = await CollateralPool.new(options.address);
    let poolInstance = await CollateralProxy.new(collateral.address,options.address);

    let managerV2 = await OptionsManagerV2.new(oracleInstance.address,price.address,
        options.address,poolInstance.address,fpt.address);
    let manager = await ManagerProxy.new(managerV2.address,oracleInstance.address,price.address,
        options.address,poolInstance.address,fpt.address)
    await manager.setValid(false);
    await poolProxy.setManager(fpt.address);
    await fpt.setManager(manager.address);
    await options.setManager(manager.address);
    await poolInstance.setManager(manager.address);
    await ivInstance.addOperator(accounts[0]);
    await oracleInstance.addOperator(accounts[0]);
    await options.addOperator(poolInstance.address);
    await options.addOperator(accounts[0]);
    await poolInstance.addOperator(accounts[0]);
    await options.setTimeLimitation(0);
    await fpt.setTimeLimitation(0);
    return {
        oracle : oracleInstance,
        iv : ivInstance,
        price : price,
        options : options,
        mine : poolProxy,
        FPT : fpt,
        collateral : poolInstance,
        manager : manager
    }
}
exports.createAndAddErc20 =  async function (contracts){
   let fnx = await FNXCoin.new();
    let erc20 = await Erc20Proxy.new(fnx.address);
//    let erc20 = await IERC20.at("0x42090c3bBa634698440b11DB6fDeff0Ac357c353");
    await contracts.mine.setMineCoinInfo(erc20.address,500000000000000,2);
    await contracts.mine.setBuyingMineInfo(erc20.address,300000000);
    await contracts.manager.setCollateralRate(erc20.address,5000);
    contracts.FNX = erc20;
}
exports.createAndAddUSDC =  async function (contracts){
    let usdc = await USDCoin.new();
    let erc20 = await Erc20Proxy.new(usdc.address);
//    await contracts.mine.setMineCoinInfo(erc20.address,500000000000000,2);
//    await contracts.mine.setBuyingMineInfo(erc20.address,300000000);
    await contracts.manager.setCollateralRate(erc20.address,1200);
    contracts.USDC = erc20;
}
exports.AddCollateral0 =  async function (contracts){
    await contracts.mine.setMineCoinInfo(collateral0,500000000000,2);
    await contracts.mine.setBuyingMineInfo(collateral0,300000000);
    await contracts.manager.setCollateralRate(collateral0,3000);
}