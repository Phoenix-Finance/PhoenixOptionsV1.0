
const imVolatility32 = artifacts.require("imVolatility32");
const OptionsPrice = artifacts.require("OptionsPrice");

const OptionsManagerV2 = artifacts.require("OptionsManagerV2");
let FNXCoin = artifacts.require("FNXCoin");
let FPTCoin = artifacts.require("FPTCoin");
let FNXMinePool = artifacts.require("FNXMinePool");
let CollateralPool = artifacts.require("CollateralPool");
let collateral0 = "0x0000000000000000000000000000000000000000";
module.exports = async function(deployer, network,accounts) {
    if (network != "wanTest"){
        const FNXOracle = artifacts.require("TestFNXOracle");
        const OptionsPool = artifacts.require("OptionsPoolTest");
//        let ivAddress = "0x97b95c36FB7adE536527d4dBe41544a65E8391a7";
            await deployer.deploy(imVolatility32);
            let ivAddress = imVolatility32.address;
        //    let ivInstance = await ImpliedVolatility.at(ivAddress);
        //    await ivInstance.transferOwnership("0xc5f5f51D7509A42F0476E74878BdA887ce9791bD");
        
            await deployer.deploy(FNXCoin);
            //await deployer.deploy(imVolatilityTest);
            await deployer.deploy(FNXOracle);
            await deployer.deploy(OptionsPrice,ivAddress);
            let optionsPool  = await deployer.deploy(OptionsPool,FNXOracle.address,OptionsPrice.address,ivAddress);
            let minePool = await deployer.deploy(FNXMinePool);
            let CoinInstance = await deployer.deploy(FPTCoin,minePool.address);
            let CollateralPoolInstance = await deployer.deploy(CollateralPool);
            let manager = await deployer.deploy(OptionsManagerV2,FNXOracle.address,OptionsPrice.address,
                            optionsPool.address,CollateralPool.address,FPTCoin.address);
            await minePool.setManager(FPTCoin.address);
            await CoinInstance.setManager(OptionsManagerV2.address);
            await optionsPool.setManager(OptionsManagerV2.address);
            await CollateralPoolInstance.setManager(OptionsManagerV2.address);
            await optionsPool.addOperator(accounts[0]);
            await manager.addOperator(accounts[0]);
            await minePool.setMineCoinInfo(collateral0,1500000000000000,1);
            await minePool.setMineCoinInfo(FNXCoin.address,500000000000000,1);
            await minePool.setBuyingMineInfo(collateral0,150000000);
            await minePool.setBuyingMineInfo(FNXCoin.address,300000000);
            await optionsPool.setBurnTimeLimit(0);
            console.log("fnx:",FNXCoin.address)
            console.log("Oracle:",FNXOracle.address);
            console.log("iv:",ivAddress);
            console.log("OptionsPrice:",OptionsPrice.address);
            console.log("optionsPool:",OptionsPool.address);
            console.log("OptionsManagerV2:",OptionsManagerV2.address);
    }else{
        const FNXOracle = artifacts.require("FNXOracle");
        const OptionsPool = artifacts.require("OptionsPool");
//        let ivAddress = "0xEdac2C1764aF7887A896402254E9Ee5Fb1312E8F";
            await deployer.deploy(imVolatility32);
            let ivAddress = imVolatility32.address;
            let ivInstance = await imVolatility32.at(ivAddress);
            await ivInstance.transferOwnership("0xc5f5f51D7509A42F0476E74878BdA887ce9791bD");
//            let oracleAddr = "0x6E51eB7234a9fb2D7610255db478B27aa521Dc6D";
            let OracleInstance =  await deployer.deploy(FNXOracle);
            await OracleInstance.transferOwnership("0xc5f5f51D7509A42F0476E74878BdA887ce9791bD");
            let oracleAddr = FNXOracle.address;
            let fnxAddr = "0xdF228001e053641FAd2BD84986413Af3BeD03E0B";
            //await deployer.deploy(FNXCoin);
//            await deployer.deploy(FNXOracle);
            await deployer.deploy(OptionsPrice,ivAddress);
            let optionsPool  = await deployer.deploy(OptionsPool,FNXOracle.address,OptionsPrice.address,ivAddress);
            let minePool = await deployer.deploy(FNXMinePool);
            let CoinInstance = await deployer.deploy(FPTCoin,minePool.address);
            let CollateralPoolInstance = await deployer.deploy(CollateralPool);
            let manager = await deployer.deploy(OptionsManagerV2,FNXOracle.address,OptionsPrice.address,
                            optionsPool.address,CollateralPool.address,FPTCoin.address);
            await minePool.setManager(FPTCoin.address);
            await CoinInstance.setManager(OptionsManagerV2.address);
            await optionsPool.setManager(OptionsManagerV2.address);
            await CollateralPoolInstance.setManager(OptionsManagerV2.address);
            await optionsPool.addOperator("0xc5f5f51D7509A42F0476E74878BdA887ce9791bD");
            await manager.addOperator("0xc5f5f51D7509A42F0476E74878BdA887ce9791bD");
            await manager.addWhiteList(collateral0);
            await manager.addWhiteList(fnxAddr);
            await minePool.setMineCoinInfo(collateral0,500000000000000,300);
            await minePool.setMineCoinInfo(fnxAddr,500000000000000,300);
            console.log("fnx:",fnxAddr);
            console.log("Oracle:",oracleAddr);
            console.log("iv:",ivAddress);
            console.log("minePool:",FNXMinePool.address);
            console.log("FPTCoin:",FPTCoin.address);
            console.log("OptionsPrice:",OptionsPrice.address);
            console.log("optionsPool:",OptionsPool.address);
            console.log("OptionsManagerV2:",OptionsManagerV2.address);
    }
};
