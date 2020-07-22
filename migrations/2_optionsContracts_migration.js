const CompoundOracle = artifacts.require("TestCompoundOracle");
const ImpliedVolatility = artifacts.require("ImpliedVolatility");
const OptionsPrice = artifacts.require("OptionsPriceTest");
const OptionsPool = artifacts.require("OptionsPool");
const OptionsMangerV2 = artifacts.require("OptionsMangerV2");
let FNXCoin = artifacts.require("FNXCoin");
module.exports = async function(deployer, network,accounts) {
    let ivAddress = "0x97b95c36FB7adE536527d4dBe41544a65E8391a7";
//    await deployer.deploy(ImpliedVolatility);
//    let ivAddress = ImpliedVolatility.address;
//    let ivInstance = await ImpliedVolatility.at(ivAddress);
//    await ivInstance.transferOwnership("0xc5f5f51D7509A42F0476E74878BdA887ce9791bD");
    await web3.eth.sendTransaction({from:accounts[0],to:"0xc5f5f51D7509A42F0476E74878BdA887ce9791bD",value:50*1e18});
    await deployer.deploy(FNXCoin);
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
};
