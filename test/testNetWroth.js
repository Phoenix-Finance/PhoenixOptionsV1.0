const OptionsManagerV2 = artifacts.require("OptionsManagerV2");
const OptionsPool = artifacts.require("OptionsPoolTest");
const OptionsPrice = artifacts.require("OptionsPrice");
let CollateralPool = artifacts.require("CollateralPool");
let FNXCoin = artifacts.require("FNXCoin");
const BN = require("bn.js");
let month = 30;
let collateral0 = "0x0000000000000000000000000000000000000000";
let testFunc = require("./testFunction.js")
let FNXMinePool = artifacts.require("FNXMinePool");
let curtime;
contract('OptionsManagerV2', function (accounts){
    it('OptionsManagerV2 cal networth', async function (){
        let OptionsManger = await OptionsManagerV2.deployed();
        let collateralInstance = await CollateralPool.deployed();
        let options = await OptionsPool.deployed();
        let fnx = await FNXCoin.deployed();
        let amount = 1e14;
        await logNetWroth(1,options,OptionsManger);
        await OptionsManger.addCollateral(collateral0,amount,{value : amount});
        await logNetWroth(2,options,OptionsManger);
        await OptionsManger.addCollateral(collateral0,amount,{value : amount});
        await logNetWroth(3,options,OptionsManger);
        tx = await OptionsManger.calSharedPayment();
        curtime = Date.now();
        tx = await OptionsManger.buyOption(collateral0,1000000000000000,9000e8,1,month,10000000000,0,{value : 1000000000000000});
        await logNetWroth(4,options,OptionsManger);
        tx = await OptionsManger.buyOption(collateral0,1000000000000000,9000e8,1,month,10000000000,0,{value : 1000000000000000});
//        console.log(tx);
        tx = await OptionsManger.buyOption(collateral0,200000000000000,8000e8,1,month,10000000000,0,{value : 200000000000000});
        tx = await OptionsManger.buyOption(collateral0,200000000000000,8000e8,1,month,20000000000,0,{from:accounts[1],value : 200000000000000});
//        console.log(tx);
        await logNetWroth(5,options,OptionsManger);
        await calculateNetWroth(options,OptionsManger,fnx);
        await logNetWroth(6,options,OptionsManger);
        for (var i=0;i<50;i++){
            await options.addExpiration(month);
        }
        await calculateNetWroth(options,OptionsManger,fnx);
        await logNetWroth(7,options,OptionsManger);
        tx = await OptionsManger.sellOption(1,10000000000);
        await logNetWroth(8,options,OptionsManger);
        tx = await OptionsManger.sellOption(2,10000000000);
        await logNetWroth(9,options,OptionsManger);
        tx = await OptionsManger.sellOption(3,10000000000);
        await logNetWroth(10,options,OptionsManger);
        console.log("-----------------------------------------");
        await calculateNetWroth(options,OptionsManger,fnx);
        await logNetWroth(11,options,OptionsManger);
        for (var i=0;i<100;i++){
            await options.addExpiration(month);
        }
        await calculateNetWroth(options,OptionsManger,fnx);
        await logNetWroth(12,options,OptionsManger);
    });
    it('OptionsManagerV2 exercise networth', async function (){
        
        let OptionsManger = await OptionsManagerV2.deployed();
        let collateralInstance = await CollateralPool.deployed();
        let options = await OptionsPool.deployed();
        let fnx = await FNXCoin.deployed();
        let Index = await options.getOptionInfoLength();
        Index = Index.toNumber();
        let amount = 1e14;
        await OptionsManger.addCollateral(collateral0,amount,{value : amount});
        await logNetWroth(21,options,OptionsManger);
        await OptionsManger.addCollateral(collateral0,amount,{value : amount});
        await logNetWroth(22,options,OptionsManger);
       
        tx = await OptionsManger.buyOption(collateral0,1000000000000000,9000e8,1,month,10000000000,0,{value : 1000000000000000});
//        console.log(tx);
        tx = await OptionsManger.buyOption(collateral0,1000000000000000,9000e8,1,month,10000000000,0,{value : 1000000000000000});
//        console.log(tx);
        tx = await OptionsManger.buyOption(collateral0,200000000000000,8000e8,1,month,10000000000,0,{value : 200000000000000});
        tx = await OptionsManger.buyOption(collateral0,200000000000000,8000e8,1,month,20000000000,0,{from:accounts[1],value : 200000000000000});
//        console.log(tx);
        await logNetWroth(23,options,OptionsManger);
        await calculateNetWroth(options,OptionsManger,fnx);
        await logNetWroth(24,options,OptionsManger);
        for (var i=0;i<50;i++){
            await options.addExpiration(month);
        }
        await calculateNetWroth(options,OptionsManger,fnx);
        await logNetWroth(25,options,OptionsManger);
        tx = await OptionsManger.exerciseOption(Index+1,10000000000);
        await logNetWroth(26,options,OptionsManger);
        tx = await OptionsManger.exerciseOption(Index+2,10000000000);
        await logNetWroth(27,options,OptionsManger);
        tx = await OptionsManger.exerciseOption(Index+3,10000000000);
        await logNetWroth(28,options,OptionsManger);
        await calculateNetWroth(options,OptionsManger,fnx);
        await logNetWroth(29,options,OptionsManger);
        for (var i=0;i<100;i++){
            await options.addExpiration(month);
        }
        await calculateNetWroth(options,OptionsManger,fnx);
        await logNetWroth(30,options,OptionsManger);
    });
});
async function logBalance(fnx,addr){
        let colBalance = await web3.eth.getBalance(addr);
        console.log("eth : ",addr,colBalance);
        let fnxBalance = await fnx.balanceOf(addr);
        console.log("fnx : ",addr,fnxBalance.toString(10));
}
async function logNetWroth(id,options,OptionsManger){
    console.log(id,Date.now()-curtime)
    let result = await OptionsManger.getTotalCollateral();
    console.log(id,"TotalCollateral : ",result.toString(10));
    result = await options.getNetWrothLatestWorth(collateral0);
    console.log(id,"LatestWorth : ",result.toString(10));
    result = await options.getTotalOccupiedCollateral();
    console.log(id,"TotalOccupied : ",result.toString(10));
    result = await OptionsManger.getOccupiedCollateral();
    console.log(id,"TotalOccupied*5 : ",result.toString(10));
    result = await OptionsManger.getLeftCollateral();
    console.log(id,"LeftCollateral : ",result.toString(10));
    result = await OptionsManger.getTokenNetworth();
    console.log(id,"Networth : ",result.toString(10));
}
async function calculateNetWroth(options,OptionsManger,fnx){
    let whiteList = [collateral0,fnx.address];
    optionsLen = await options.getOptionCalRangeAll(whiteList);
    console.log(optionsLen[0].toString(10),optionsLen[1].toString(10),optionsLen[2].toString(10),optionsLen[4].toString(10));

    let result =  await options.calculatePhaseOccupiedCollateral(optionsLen[4],optionsLen[0],optionsLen[4]);
    console.log(result[0].toString(10),result[1].toString(10));
    let tx = await options.setOccupiedCollateral();
    result =  await options.calRangeSharedPayment(optionsLen[4],optionsLen[2],optionsLen[4],whiteList);
    console.log(result[0][0].toString(10),result[0][1].toString(10));

//                return;
    tx = await OptionsManger.calSharedPayment();
//    console.log(tx);
}