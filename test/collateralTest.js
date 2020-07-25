const OptionsMangerV2 = artifacts.require("OptionsMangerV2");
const OptionsPool = artifacts.require("OptionsPool");
const imVolatility32 = artifacts.require("imVolatility32");
const OptionsPrice = artifacts.require("OptionsPrice");
let FNXCoin = artifacts.require("FNXCoin");
let month = 30*60*60*24;
let collateral0 = "0x0000000000000000000000000000000000000000";
let testFunc = require("./testFunction.js")
contract('OptionsMangerV2', function (accounts){
    it('OptionsMangerV2 add collateral', async function (){
        let volInstance = await imVolatility32.deployed();
        await testFunc.AddImpliedVolatility(volInstance,false);
        let OptionsManger = await OptionsMangerV2.deployed();
        let options = await OptionsPool.deployed();
        let fnx = await FNXCoin.deployed();
        let tx = await OptionsManger.addWhiteList(collateral0);
//        console.log(tx);
        tx = await OptionsManger.addWhiteList(fnx.address);
        await options.addUnderlyingAsset(1);
//        console.log(tx);
//        return;
        await OptionsManger.addWhiteList(fnx.address);
        await OptionsManger.addCollateral(collateral0,10000000000000,{value : 10000000000000});
        await fnx.approve(OptionsManger.address,10000000000000);
        await OptionsManger.addCollateral(fnx.address,10000000000000);
        await options.addExpiration(month);
        fnx.approve(OptionsManger.address,1000000000000000);
        tx = await OptionsManger.buyOption(fnx.address,1000000000000000,20000000000,1,month,10000000000,0);
        console.log(tx)
       
        tx = await OptionsManger.buyOption(collateral0,1000000000000000,20000000000,1,month,10000000000,0,{value : 1000000000000000});
//        console.log(tx);
        tx = await OptionsManger.buyOption(collateral0,1000000000000000,20000000000,1,month,10000000000,0,{value : 1000000000000000});
//        console.log(tx);
//        tx = await OptionsManger.buyOption(collateral0,200000000000000,10000000000,1,month,10000000000,0,{value : 200000000000000});
//        console.log(tx);
        let result = await options.getOptionsById(1);
        console.log(result[0].toString(10),result[1],result[2].toString(10),result[3].toString(10),result[4].toString(10),result[5].toString(10),result[6].toString(10));
        result = await options.getOptionsById(2);
        console.log(result[0].toString(10),result[1],result[2].toString(10),result[3].toString(10),result[4].toString(10),result[5].toString(10),result[6].toString(10));
        result = await options.getOptionsById(3);
        console.log(result[0].toString(10),result[1],result[2].toString(10),result[3].toString(10),result[4].toString(10),result[5].toString(10),result[6].toString(10));
        tx = await OptionsManger.sellOption(1,10000000000);
//        console.log(tx);
        tx = await OptionsManger.exerciseOption(3,10000000000);
        result = await options.getOptionsById(1);
        console.log(result[0].toString(10),result[1],result[2].toString(10),result[3].toString(10),result[4].toString(10),result[5].toString(10),result[6].toString(10));
        result = await options.getOptionsById(2);
        console.log(result[0].toString(10),result[1],result[2].toString(10),result[3].toString(10),result[4].toString(10),result[5].toString(10),result[6].toString(10));
        result = await options.getOptionsById(3);
        console.log(result[0].toString(10),result[1],result[2].toString(10),result[3].toString(10),result[4].toString(10),result[5].toString(10),result[6].toString(10));
//        console.log(tx);
    });
});