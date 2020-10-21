
const ImpliedVolatility = artifacts.require("ImpliedVolatility");

let FNXCoin = artifacts.require("FNXCoin");
let Erc20Proxy = artifacts.require("Erc20Proxy");

let OptionsPool = artifacts.require("OptionsPool");
let OptionsProxy = artifacts.require("OptionsProxy");

let FNXMinePool = artifacts.require("FNXMinePool");
let MinePoolProxy = artifacts.require("MinePoolProxy");

const OptionsManagerV2 = artifacts.require("OptionsManagerV2");
const ManagerProxy = artifacts.require("ManagerProxy");

let FPTCoin = artifacts.require("FPTCoin");
let FPTProxy = artifacts.require("FPTProxy");

let CollateralPool = artifacts.require("CollateralPool");
let CollProxy = artifacts.require("CollateralProxy");

let collateral0 = "0x0000000000000000000000000000000000000000";
module.exports = async function(deployer, network,accounts) {
    const FNXOracle = artifacts.require("TestFNXOracle");
    const OptionsPrice = artifacts.require("OptionsPrice");
    await deployer.deploy(ImpliedVolatility);
    let ivAddress = ImpliedVolatility.address;
    let ivInstance = await ImpliedVolatility.at(ivAddress);
    let oracleInstance = await deployer.deploy(FNXOracle);
    await deployer.deploy(OptionsPrice,ivAddress);
    return;
    await migrate(deployer,FNXCoin,Erc20Proxy);
    return;
    let optionsPool = await migrate(deployer,OptionsPool,OptionsProxy,FNXOracle.address,OptionsPrice.address,ivAddress);
    let minePool = await migrate(deployer,FNXMinePool,MinePoolProxy);
    let CoinInstance = await migrate(deployer,FPTCoin,FPTProxy,MinePoolProxy.address);

    let CollateralPoolInstance = await migrate(deployer,CollateralPool,CollProxy);

    let manager = await migrate(deployer,OptionsManagerV2,ManagerProxy,MinePoolProxy.address,FNXOracle.address,OptionsPrice.address,
        OptionsProxy.address,CollateralProxy.address,FPTProxy.address);


    await minePool.setManager(FPTCoin.address);
    await CoinInstance.setManager(OptionsManagerV2.address);
    await optionsPool.setManager(OptionsManagerV2.address);
    await CollateralPoolInstance.setManager(OptionsManagerV2.address);
    await ivInstance.addOperator(accounts[0]);
    await oracleInstance.addOperator(accounts[0]);
    await optionsPool.addOperator(accounts[0]);
    await manager.addOperator(accounts[0]);
    //await minePool.setMineCoinInfo(collateral0,1500000000000000,2);
    await minePool.setMineCoinInfo(FNXCoin.address,500000000000000,2);
    //await minePool.setBuyingMineInfo(collateral0,150000000);
    await minePool.setBuyingMineInfo(FNXCoin.address,300000000);
    await optionsPool.setBurnTimeLimit(0);
    await CoinInstance.setBurnTimeLimited(0);
    await manager.setCollateralRate(collateral0,1500);
    await manager.setCollateralRate(FNXCoin.address,5000);
    console.log("fnx:",FNXCoin.address)
    console.log("Oracle:",FNXOracle.address);
    console.log("iv:",ivAddress);
    console.log("OptionsPrice:",OptionsPrice.address);
    console.log("optionsPool:",OptionsPool.address);
    console.log("OptionsManagerV2:",OptionsManagerV2.address);
};
async function migrate(deployer,contractImpl,contractProxy,...args){
    await deployer.deploy(contractImpl);
    return await deployer.deploy(contractProxy,contractImpl.address,...args);
}