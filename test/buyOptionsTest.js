const OptionsManagerV2 = artifacts.require("OptionsManagerV2");
const OptionsPool = artifacts.require("OptionsPoolTest");
const ImpliedVolatility = artifacts.require("ImpliedVolatility");
const FNXOracle = artifacts.require("TestFNXOracle");
let FNXCoin = artifacts.require("FNXCoin");
let month = 30*60*60*24;
let collateral0 = "0x0000000000000000000000000000000000000000";
const BN = require("bn.js");
contract('OptionsManagerV2', function (accounts){
    it('OptionsManagerV2 buy options', async function (){
        let OptionsManger = await OptionsManagerV2.deployed();
        let options = await OptionsPool.deployed();
        let oracle = await FNXOracle.deployed();
        let fnx = await FNXCoin.deployed();
        let tx = await OptionsManger.addWhiteList(collateral0);
        tx = await OptionsManger.addWhiteList(fnx.address);
        await options.addUnderlyingAsset(1);
        await OptionsManger.addWhiteList(fnx.address);     
        await oracle.setUnderlyingPrice(1,1179262000000);
        await oracle.setPrice(fnx.address,38737698);
        let amount = new BN(1);
        amount = amount.ushln(90);
        await fnx.approve(OptionsManger.address,amount);
        await OptionsManger.addCollateral(fnx.address,amount);
        amount = new BN("1044468046152007500",10);
        await fnx.approve(OptionsManger.address,amount);
        await OptionsManger.buyOption(fnx.address,amount,1155837000000,1,604800,1000000000000000,0);
     });
});