const BN = require("bn.js");

const ImpliedVolatility = artifacts.require("ImpliedVolatility");

let FNXCoin = artifacts.require("FNXCoin");
let Erc20Proxy = artifacts.require("Erc20Proxy");
let USDCoin = artifacts.require("USDCoin");
let USDTCoin = artifacts.require("USDTCoin");

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
contract('OptionsManagerV2', function (accounts){
    it('deploy All contracts', async function (){
        let ivInstance = await ImpliedVolatility.new();
        console.log("iv : ",ivInstance.address)
        let oracleInstance = await FNXOracle.new();
        console.log("oracle : ",oracleInstance.address)
        let price = await OptionsPrice.new(ivInstance.address);
        console.log("price : ",price.address)

        let pool = await OptionsPool.new(oracleInstance.address,price.address,ivInstance.address);
        let optionsA = await OptionsProxy.new(pool.address,oracleInstance.address,price.address,ivInstance.address);
        console.log("optionsA : ",optionsA.address)
        let optionsB = await OptionsProxy.new(pool.address,oracleInstance.address,price.address,ivInstance.address);
        console.log("optionsB : ",optionsB.address)
        pool = await FNXMinePool.new();
        let poolProxyA = await MinePoolProxy.new(pool.address);
        console.log("minePoolA : ",poolProxyA.address)
        let poolProxyB = await MinePoolProxy.new(pool.address);
        console.log("minePoolB : ",poolProxyB.address)

        let fptimpl = await FPTCoin.new(poolProxyA.address,"FPT-A");
        let fptA = await FPTProxy.new(fptimpl.address,poolProxyA.address,"FPT-A");
        console.log("fptA : ",fptA.address)
        let fptB = await FPTProxy.new(fptimpl.address,poolProxyB.address,"FPT-B");
        console.log("fptB : ",fptB.address)

        let collateral = await CollateralPool.new(optionsA.address);
        let collateralPoolA = await CollateralProxy.new(collateral.address,optionsA.address);
        console.log("collateralPoolA : ",collateralPoolA.address)
        let collateralPoolB = await CollateralProxy.new(collateral.address,optionsB.address);
        console.log("collateralPoolB : ",collateralPoolB.address)

        let managerV2 = await OptionsManagerV2.new(oracleInstance.address,price.address,
            optionsA.address,collateralPoolA.address,fptA.address);
        let managerA = await ManagerProxy.new(managerV2.address,oracleInstance.address,price.address,
            optionsA.address,collateralPoolA.address,fptA.address);
        console.log("managerA : ",managerA.address)
        let managerB = await ManagerProxy.new(managerV2.address,oracleInstance.address,price.address,
            optionsB.address,collateralPoolB.address,fptB.address);
        console.log("managerB : ",managerB.address)

        await managerA.setValid(false);
        await managerB.setValid(false);
        await poolProxyA.setManager(fptA.address);
        await poolProxyB.setManager(fptB.address);
        await fptA.setManager(managerA.address);
        await fptB.setManager(managerB.address);
        await optionsA.setManager(managerA.address);
        await optionsB.setManager(managerB.address);
        await collateralPoolA.setManager(managerA.address);
        await collateralPoolB.setManager(managerB.address);
        await ivInstance.addOperator(accounts[0]);
        await oracleInstance.addOperator(accounts[0]);
        await optionsA.addOperator(collateralPoolA.address);
        await optionsB.addOperator(collateralPoolB.address);
        await optionsA.addOperator(accounts[0]);
        await optionsB.addOperator(accounts[0]);
        await collateralPoolA.addOperator(accounts[0]);
        await collateralPoolB.addOperator(accounts[0]);
        await optionsA.setTimeLimitation(0);
        await optionsB.setTimeLimitation(0);
        await fptA.setTimeLimitation(0);
        await fptB.setTimeLimitation(0);

        let fnx = await FNXCoin.new();
        let erc20 = await Erc20Proxy.new(fnx.address);

        console.log("FNX : ",erc20.address)
        await managerB.setCollateralRate(erc20.address,5000);
        await oracleInstance.setPrice(erc20.address,28000000);

        let usdc = await USDCoin.new();
        erc20 = await Erc20Proxy.new(usdc.address);
        console.log("USDC : ",erc20.address)
        await managerA.setCollateralRate(erc20.address,1200);
        await oracleInstance.setPrice(erc20.address,"100000000000000000000");

        let usdt = await USDTCoin.new();
        erc20 = await Erc20Proxy.new(usdt.address);
        console.log("USDT : ",erc20.address)
        await managerA.setCollateralRate(erc20.address,1200);
        await oracleInstance.setPrice(erc20.address,"100000000000000000000");
    })
})
