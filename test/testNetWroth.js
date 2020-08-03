const OptionsManagerV2 = artifacts.require("OptionsManagerV2");
const OptionsPool = artifacts.require("OptionsPoolTest");
const imVolatility32 = artifacts.require("imVolatility32");
const OptionsPrice = artifacts.require("OptionsPrice");
let CollateralPool = artifacts.require("CollateralPool");
let FNXCoin = artifacts.require("FNXCoin");
const BN = require("bn.js");
let month = 100;
let collateral0 = "0x0000000000000000000000000000000000000000";
let testFunc = require("./testFunction.js")
let FNXMinePool = artifacts.require("FNXMinePool");
contract('OptionsManagerV2', function (accounts){
    it('OptionsManagerV2 cal networth', async function (){
        let volInstance = await imVolatility32.deployed();
        await testFunc.AddImpliedVolatility(volInstance,false);
        let OptionsManger = await OptionsManagerV2.deployed();
        let collateralInstance = await CollateralPool.deployed();
        let options = await OptionsPool.deployed();
        let fnx = await FNXCoin.deployed();
        let amount = 1e14;
        await OptionsManger.addCollateral(collateral0,amount,{value : amount});
        await logNetWroth(options,OptionsManger);
        await OptionsManger.addCollateral(collateral0,amount,{value : amount});
        await logNetWroth(options,OptionsManger);
       
        tx = await OptionsManger.buyOption(collateral0,1000000000000000,20000000000,1,month,10000000000,0,{value : 1000000000000000});
//        console.log(tx);
        tx = await OptionsManger.buyOption(collateral0,1000000000000000,20000000000,1,month,10000000000,0,{value : 1000000000000000});
//        console.log(tx);
        tx = await OptionsManger.buyOption(collateral0,200000000000000,10000000000,1,month,10000000000,0,{value : 200000000000000});
//        console.log(tx);
        await logNetWroth(options,OptionsManger);
        await calculateNetWroth(options,OptionsManger,fnx);
        await logNetWroth(options,OptionsManger);
        for (var i=0;i<100;i++){
            await options.addExpiration(month);
        }
        await calculateNetWroth(options,OptionsManger,fnx);
        await logNetWroth(options,OptionsManger);
        tx = await OptionsManger.sellOption(1,10000000000);
        await logNetWroth(options,OptionsManger);
        tx = await OptionsManger.sellOption(2,10000000000);
        await logNetWroth(options,OptionsManger);
        tx = await OptionsManger.sellOption(3,10000000000);
        await logNetWroth(options,OptionsManger);
        await calculateNetWroth(options,OptionsManger,fnx);
        await logNetWroth(options,OptionsManger);
    });
    it('OptionsManagerV2 exercise networth', async function (){
        
        let volInstance = await imVolatility32.deployed();
        await testFunc.AddImpliedVolatility(volInstance,false);
        let OptionsManger = await OptionsManagerV2.deployed();
        let collateralInstance = await CollateralPool.deployed();
        let options = await OptionsPool.deployed();
        let fnx = await FNXCoin.deployed();
        let Index = await options.getOptionInfoLength();
        Index = Index.toNumber();
        let amount = 1e14;
        await OptionsManger.addCollateral(collateral0,amount,{value : amount});
        await logNetWroth(options,OptionsManger);
        await OptionsManger.addCollateral(collateral0,amount,{value : amount});
        await logNetWroth(options,OptionsManger);
       
        tx = await OptionsManger.buyOption(collateral0,1000000000000000,20000000000,1,month,10000000000,0,{value : 1000000000000000});
//        console.log(tx);
        tx = await OptionsManger.buyOption(collateral0,1000000000000000,20000000000,1,month,10000000000,0,{value : 1000000000000000});
//        console.log(tx);
        tx = await OptionsManger.buyOption(collateral0,200000000000000,10000000000,1,month,10000000000,0,{value : 200000000000000});
//        console.log(tx);
        await logNetWroth(options,OptionsManger);
        await calculateNetWroth(options,OptionsManger,fnx);
        await logNetWroth(options,OptionsManger);
        for (var i=0;i<100;i++){
            await options.addExpiration(month);
        }
        await calculateNetWroth(options,OptionsManger,fnx);
        await logNetWroth(options,OptionsManger);
        tx = await OptionsManger.exerciseOption(Index+1,10000000000);
        await logNetWroth(options,OptionsManger);
        tx = await OptionsManger.exerciseOption(Index+2,10000000000);
        await logNetWroth(options,OptionsManger);
        tx = await OptionsManger.exerciseOption(Index+3,10000000000);
        await logNetWroth(options,OptionsManger);
        await calculateNetWroth(options,OptionsManger,fnx);
        await logNetWroth(options,OptionsManger);
    });
});
async function logBalance(fnx,addr){
        let colBalance = await web3.eth.getBalance(addr);
        console.log("eth : ",addr,colBalance);
        let fnxBalance = await fnx.balanceOf(addr);
        console.log("fnx : ",addr,fnxBalance.toString(10));
}
async function logNetWroth(options,OptionsManger){
    let result = await OptionsManger.getTotalCollateral();
    console.log("TotalCollateral : ",result.toString(10));
    result = await options.getTotalOccupiedCollateral();
    console.log("TotalOccupied : ",result.toString(10));
    result = await OptionsManger.getOccupiedCollateral();
    console.log("TotalOccupied*5 : ",result.toString(10));
    result = await OptionsManger.getLeftCollateral();
    console.log("LeftCollateral : ",result.toString(10));
    result = await OptionsManger.getTokenNetworth();
    console.log("Networth : ",result.toString(10));
}
async function calculateNetWroth(options,OptionsManger,fnx){
    optionsLen = await options.getOptionCalRangeAll()
    console.log(optionsLen[0].toNumber(),optionsLen[1].toNumber(),optionsLen[2].toNumber(),optionsLen[3].toNumber());
    let bn = new BN(0);
    let bn1 = new BN(optionsLen[2]);
    bn1 = bn1.ushln(64);
    bn = bn.add(bn1);
    bn1 = new BN(optionsLen[3]);
    bn1 = bn1.ushln(128);
    bn = bn.add(bn1);
    let result =  await options.calculatePhaseOccupiedCollateral(bn);
    console.log(result[0].toString(10),result[1].toString(10));
    let tx = await options.setPhaseOccupiedCollateral(bn);
    bn = new BN(0);
    bn1 = new BN(optionsLen[2]);
    bn1 = bn1.ushln(64);
    bn = bn.add(bn1);
    bn1 = new BN(optionsLen[3]);
    bn1 = bn1.ushln(128);
    bn = bn.add(bn1);
    let whiteList = [collateral0,fnx.address];
    result =  await options.calRangeSharedPayment(bn,0,optionsLen[2],whiteList);
    console.log(result[0][0].toString(10),result[0][1].toString(10));

//                return;
    tx = await OptionsManger.setPhaseSharedPayment(bn);
}