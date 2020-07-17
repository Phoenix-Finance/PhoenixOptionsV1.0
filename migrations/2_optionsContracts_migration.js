const CompoundOracle = artifacts.require("TestCompoundOracle");
const OptionsPrice = artifacts.require("OptionsPriceTest");
const OptionsMangerV2 = artifacts.require("OptionsMangerV2");
let FNXCoin = artifacts.require("FNXCoin");
module.exports = async function(deployer, network,accounts) {
    await deployer.deploy(FNXCoin);
    let oracleInstance = await deployer.deploy(CompoundOracle);
    await deployer.deploy(OptionsPrice);
    let manager = await deployer.deploy(OptionsMangerV2);
    console.log(FNXCoin.address,CompoundOracle.address,OptionsPrice.address,OptionsMangerV2.address);
    await manager.setOracleAddress(CompoundOracle.address);
    await manager.setOptionsPriceAddress(OptionsPrice.address);
};
