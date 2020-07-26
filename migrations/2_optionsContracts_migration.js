
const imVolatility32 = artifacts.require("imVolatility32");
const OptionsPrice = artifacts.require("OptionsPrice");
const OptionsPool = artifacts.require("OptionsPool");
const OptionsManagerV2 = artifacts.require("OptionsManagerV2");
let FNXCoin = artifacts.require("FNXCoin");
let collateral0 = "0x0000000000000000000000000000000000000000";
module.exports = async function(deployer, network,accounts) {
    if (network != "wanTest"){
        const CompoundOracle = artifacts.require("TestCompoundOracle");
//        let ivAddress = "0x97b95c36FB7adE536527d4dBe41544a65E8391a7";
            await deployer.deploy(imVolatility32);
            let ivAddress = imVolatility32.address;
        //    let ivInstance = await ImpliedVolatility.at(ivAddress);
        //    await ivInstance.transferOwnership("0xc5f5f51D7509A42F0476E74878BdA887ce9791bD");
        
            await deployer.deploy(FNXCoin);
            //await deployer.deploy(imVolatilityTest);
            await deployer.deploy(CompoundOracle);
            await deployer.deploy(OptionsPrice,ivAddress);
            let optionsPool  = await deployer.deploy(OptionsPool,CompoundOracle.address,OptionsPrice.address,ivAddress);
            let manager = await deployer.deploy(OptionsManagerV2,CompoundOracle.address,OptionsPrice.address,optionsPool.address);
        
            await optionsPool.setManager(OptionsManagerV2.address);
            console.log("fnx:",FNXCoin.address)
            console.log("Oracle:",CompoundOracle.address);
            console.log("iv:",ivAddress);
            console.log("OptionsPrice:",OptionsPrice.address);
            console.log("optionsPool:",OptionsPool.address);
            console.log("OptionsManagerV2:",OptionsManagerV2.address);
    }else{
        const CompoundOracle = artifacts.require("CompoundOracle");
//        let ivAddress = "0xEdac2C1764aF7887A896402254E9Ee5Fb1312E8F";
            await deployer.deploy(imVolatility32);
            let ivAddress = imVolatility32.address;
            let ivInstance = await imVolatility32.at(ivAddress);
            await ivInstance.transferOwnership("0xc5f5f51D7509A42F0476E74878BdA887ce9791bD");
//            let oracleAddr = "0x6E51eB7234a9fb2D7610255db478B27aa521Dc6D";
            let OracleInstance =  await deployer.deploy(CompoundOracle);
            await OracleInstance.transferOwnership("0xc5f5f51D7509A42F0476E74878BdA887ce9791bD");
            let oracleAddr = CompoundOracle.address;
            let fnxAddr = "0xdF228001e053641FAd2BD84986413Af3BeD03E0B";
            //await deployer.deploy(FNXCoin);
//            await deployer.deploy(CompoundOracle);
            await deployer.deploy(OptionsPrice,ivAddress);
            let optionsPool  = await deployer.deploy(OptionsPool,oracleAddr,OptionsPrice.address,ivAddress);
            let manager = await deployer.deploy(OptionsManagerV2,oracleAddr,OptionsPrice.address,optionsPool.address);
            await optionsPool.setManager(OptionsManagerV2.address);
            await optionsPool.setOperator("0xc5f5f51D7509A42F0476E74878BdA887ce9791bD");
            await manager.setOperator("0xc5f5f51D7509A42F0476E74878BdA887ce9791bD");
            await manager.addWhiteList(collateral0);
            await manager.addWhiteList(fnxAddr);
            console.log("fnx:",fnxAddr);
            console.log("Oracle:",oracleAddr);
            console.log("iv:",ivAddress);
            console.log("OptionsPrice:",OptionsPrice.address);
            console.log("optionsPool:",OptionsPool.address);
            console.log("OptionsManagerV2:",OptionsManagerV2.address);
    }
};
