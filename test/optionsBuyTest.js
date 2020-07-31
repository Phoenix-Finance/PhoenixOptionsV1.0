const OptionsManagerV2 = artifacts.require("OptionsManagerV2");
const OptionsPool = artifacts.require("OptionsPoolTest");
const imVolatility32 = artifacts.require("imVolatility32");
const OptionsPrice = artifacts.require("OptionsPrice");
let FNXCoin = artifacts.require("FNXCoin");
const BN = require("bn.js");
let month = 30*60*60*24;
let collateral0 = "0x0000000000000000000000000000000000000000";
let testFunc = require("./testFunction.js")
let FNXMinePool = artifacts.require("FNXMinePool");
contract('OptionsManagerV2', function (accounts){
    it('OptionsManagerV2 buy options', async function (){
        let volInstance = await imVolatility32.deployed();
        await testFunc.AddImpliedVolatility(volInstance,false);
        let OptionsManger = await OptionsManagerV2.deployed();
        let options = await OptionsPool.deployed();
        let fnx = await FNXCoin.deployed();
        await options.addUnderlyingAsset(1);
        let minePool = await FNXMinePool.deployed();
//        console.log(tx);
//        return;
        let collAmount = new BN("1000000000000000000000000",10);
        await OptionsManger.addWhiteList(fnx.address);
        await fnx.approve(OptionsManger.address,collAmount);
        await OptionsManger.addCollateral(fnx.address,collAmount);
        let days = 24*60*60;
        let expiration = [days,3*days, 7*days, 10*days, 15*days, 30*days,90*days];
        for (var i=0;i<20;i++){
            await fnx.approve(OptionsManger.address,2000000000000000);
            let strikePrice = 50 + i*2000;
            await OptionsManger.buyOption(fnx.address,1000000000000000,strikePrice,1,expiration[i%expiration.length],
                100000000000,1);
        }
        for (var i=0;i<20;i++){
            await OptionsManger.sellOption(i+1,100000000000);
        }
    });
});