const CompoundOracle = artifacts.require("TestCompoundOracle");
const ImpliedVolatility = artifacts.require("ImpliedVolatility");
const imVolatility32 = artifacts.require("imVolatility32");
const imVolatilityTest = artifacts.require("imVolatilityTest");
const OptionsPrice = artifacts.require("OptionsPrice");
const OptionsPool = artifacts.require("OptionsPool");
const OptionsMangerV2 = artifacts.require("OptionsMangerV2");
let FNXCoin = artifacts.require("FNXCoin");
let collateral0 = "0x0000000000000000000000000000000000000000";
module.exports = async function(deployer, network,accounts) {
    if (network != "wanTest"){
        let ivAddress = "0x97b95c36FB7adE536527d4dBe41544a65E8391a7";
        //    await deployer.deploy(ImpliedVolatility);
        //    let ivAddress = ImpliedVolatility.address;
        //    let ivInstance = await ImpliedVolatility.at(ivAddress);
        //    await ivInstance.transferOwnership("0xc5f5f51D7509A42F0476E74878BdA887ce9791bD");
        
            await deployer.deploy(FNXCoin);
            await deployer.deploy(imVolatilityTest);
            await deployer.deploy(CompoundOracle);
            await deployer.deploy(OptionsPrice,ivAddress);
            let optionsPool  = await deployer.deploy(OptionsPool,CompoundOracle.address,OptionsPrice.address,ivAddress);
            let manager = await deployer.deploy(OptionsMangerV2,CompoundOracle.address,OptionsPrice.address,optionsPool.address);
        
            await optionsPool.setManager(OptionsMangerV2.address);
            console.log("fnx:",FNXCoin.address)
            console.log("Oracle:",CompoundOracle.address);
            console.log("iv:",ivAddress);
            console.log("OptionsPrice:",OptionsPrice.address);
            console.log("optionsPool:",OptionsPool.address);
            console.log("OptionsMangerV2:",OptionsMangerV2.address);
    }else{
        let ivAddress = "0xEdac2C1764aF7887A896402254E9Ee5Fb1312E8F";
//            await deployer.deploy(ImpliedVolatility);
//            let ivAddress = ImpliedVolatility.address;
            let ivInstance = await ImpliedVolatility.at(ivAddress);
//            await ivInstance.transferOwnership("0xc5f5f51D7509A42F0476E74878BdA887ce9791bD");
            let oracleAddr = "0x6E51eB7234a9fb2D7610255db478B27aa521Dc6D";
            let fnxAddr = "0xdF228001e053641FAd2BD84986413Af3BeD03E0B";
            //await deployer.deploy(FNXCoin);
//            await deployer.deploy(CompoundOracle);
            await deployer.deploy(OptionsPrice,ivAddress);
            let optionsPool  = await deployer.deploy(OptionsPool,oracleAddr,OptionsPrice.address,ivAddress);
            let manager = await deployer.deploy(OptionsMangerV2,oracleAddr,OptionsPrice.address,optionsPool.address);
            await optionsPool.setManager(OptionsMangerV2.address);
            await manager.addWhiteList(collateral0);
            await manager.addWhiteList(fnxAddr);
            console.log("fnx:",fnxAddr);
            console.log("Oracle:",oracleAddr);
            console.log("iv:",ivAddress);
            console.log("OptionsPrice:",OptionsPrice.address);
            console.log("optionsPool:",OptionsPool.address);
            console.log("OptionsMangerV2:",OptionsMangerV2.address);
    }
};
