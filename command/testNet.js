let Web3 = require("Web3")
const fs = require('fs');
let web3 = new Web3(new Web3.providers.HttpProvider("https://demodex.wandevs.org:48545"));
let contract = require("./contract/Contract.js")
let contractfunc = require("./contract/ContractFunc.js")
let OptionsPool = require("../build/contracts/OptionsPool.json");
let OptionsManagerV2 = require("../build/contracts/OptionsManagerV2.json");
let OptionsPrice = require("../build/contracts/OptionsPrice.json");
let FNXOracle = require("../build/contracts/FNXOracle.json");
let FPTCoin = require("../build/contracts/FPTCoin.json");
let collateral0 = "0x0000000000000000000000000000000000000000";
async function wanTest(){

    let fpt = await new web3.eth.Contract(FPTCoin.abi,"0xa9df04d91bd857eaa8122fc239ac1d9ed9d2a15e");
    let times = await fpt.methods.getUserBurnTimeLimite("0xa936B6F2557c096C0052a9A4765963B381D33896").call();
    console.log("burn limted time : ",times.toString(10));
    let manager = await new web3.eth.Contract(OptionsManagerV2.abi,"0x2c245224c24718644f0e3964b5cfd4d507e1deef");
    let netWorth = await manager.methods.getTokenNetworth().call();
    console.log("netWorth :",netWorth.toString(10));
    let result = await manager.methods.getTotalCollateral().call();
    console.log("TotalCollateral :",result.toString(10));
    result = await manager.methods.getOccupiedCollateral().call();
    console.log("OccupiedCollateral :",result.toString(10));
    result = await manager.methods.getLeftCollateral().call();
    console.log("LeftCollateral :",result.toString(10));
    result = await manager.methods.getWhiteList().call();
    console.log("getWhiteList :",result.toString(10));
    let oracle = await new web3.eth.Contract(FNXOracle.abi,"0xfc344e9cd3e20dfe497d29df6a072e9afd8f024e");
    let btcPrice = await oracle.methods.getUnderlyingPrice(1).call();
    console.log("btcPrice :",btcPrice.toString(10));
    let ethPrice = await oracle.methods.getUnderlyingPrice(2).call();
    console.log("ethPrice :",ethPrice.toString(10));
    result = await oracle.methods.getPrice("0x8ebff0b39363f40b22a9f7a079a9b9ee1b448a03").call();
    console.log("fnx price :",result.toString(10));
    result = await oracle.methods.getPrice(collateral0).call();
    console.log("wan price :",result.toString(10));
    // btcPrice = await oracle.methods.getPrice("0x4738635C82BED8F474D9A078F4E5797fa5d5f460").call();
    // console.log("USDC Price :",btcPrice.toString(10));
    let price = await new web3.eth.Contract(OptionsPrice.abi,"0x3b3f33b83ea9212d8892e8d521aae743076576a8");
    result = await price.methods.getOptionsPrice(btcPrice,1155837000000,604800,1,0).call();
    console.log("price :",result.toString(10));

    let Options = await new web3.eth.Contract(OptionsPool.abi,"0xb90a8e8a770d67dd67192cbc2b4994082f438b61");
    result = await Options.methods.getOptionInfoLength().call();
    console.log("getOptionInfoLength :",result.toString(10));
    result = await Options.methods.getUserOptionsID("0xc864f6c8f8a75c4885f8208964a85a7f517bdecb").call();
    console.log("getUserOptionsID :",result);
    result = await Options.methods.getOptionsById(1).call();
    console.log("getOptionsById :",result);
    result = await Options.methods.getOptionsExtraById(1).call();
    console.log("getOptionsExtraById :",result);
    result = await Options.methods.getOptionsById(100).call();
    console.log("getOptionsById :",result);
    result = await Options.methods.getOptionsExtraById(100).call();
    console.log("getOptionsExtraById :",result);
}
wanTest();