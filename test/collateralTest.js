const OptionsManagerV2 = artifacts.require("OptionsManagerV2");
const OptionsPool = artifacts.require("OptionsPoolTest");
const imVolatility32 = artifacts.require("imVolatility32");
const OptionsPrice = artifacts.require("OptionsPrice");
let CollateralPool = artifacts.require("CollateralPool");
let FNXCoin = artifacts.require("FNXCoin");
const BN = require("bn.js");
let month = 30*60*60*24;
let collateral0 = "0x0000000000000000000000000000000000000000";
let testFunc = require("./testFunction.js")
let FNXMinePool = artifacts.require("FNXMinePool");
contract('OptionsManagerV2', function (accounts){
        /*
    it('OptionsManagerV2 redeem collateral', async function (){
        let OptionsManger = await OptionsManagerV2.deployed();
        let collateralInstance = await CollateralPool.deployed();
        let options = await OptionsPool.deployed();
        let fnx = await FNXCoin.deployed();
        let tx = await OptionsManger.addWhiteList(collateral0);
//        console.log(tx);
        tx = await OptionsManger.addWhiteList(fnx.address);
        await options.addUnderlyingAsset(1);
        let minePool = await FNXMinePool.deployed();
//        console.log(tx);
//        return;
        await OptionsManger.addWhiteList(fnx.address);
        await fnx.approve(OptionsManger.address,10000000000000);
        await OptionsManger.addCollateral(fnx.address,10000000000000);
        await logBalance(fnx,collateralInstance.address);
        await logBalance(fnx,accounts[0]);
        for (var i=0;i<10;i++){
                await OptionsManger.addWhiteList(fnx.address);
        }
        await OptionsManger.redeemCollateral(500000000000000,collateral0);
        await logBalance(fnx,collateralInstance.address);
        await logBalance(fnx,accounts[0]);
        await OptionsManger.addCollateral(collateral0,10000000000000,{value:10000000000000});
        await logBalance(fnx,collateralInstance.address);
        await logBalance(fnx,accounts[0]);
        for (var i=0;i<10;i++){
                await OptionsManger.addWhiteList(fnx.address);
        }
        await OptionsManger.redeemCollateral(500000000000000,fnx.address);
        await logBalance(fnx,collateralInstance.address);
        await logBalance(fnx,accounts[0]);
        await fnx.approve(OptionsManger.address,10000000000000);
        await OptionsManger.addCollateral(fnx.address,10000000000000);
        await logBalance(fnx,collateralInstance.address);
        await logBalance(fnx,accounts[0]);
        for (var i=0;i<10;i++){
                await OptionsManger.addWhiteList(fnx.address);
        }
        await OptionsManger.redeemCollateral(500000000000000,collateral0);
        await logBalance(fnx,collateralInstance.address);
        await logBalance(fnx,accounts[0]);
        await OptionsManger.addCollateral(collateral0,10000000000000,{value:10000000000000});
        await logBalance(fnx,collateralInstance.address);
        await logBalance(fnx,accounts[0]);
        for (var i=0;i<10;i++){
                await OptionsManger.addWhiteList(fnx.address);
        }
        await OptionsManger.redeemCollateral(500000000000000,fnx.address);
        await logBalance(fnx,collateralInstance.address);
        await logBalance(fnx,accounts[0]);
        
    });
    */
    it('OptionsManagerV2 add collateral', async function (){
        let collateralInstance = await CollateralPool.deployed();
        let OptionsManger = await OptionsManagerV2.deployed();
        let options = await OptionsPool.deployed();
        let fnx = await FNXCoin.deployed();
        let tx = await OptionsManger.addWhiteList(collateral0);
//        console.log(tx);
        tx = await OptionsManger.addWhiteList(fnx.address);
        await options.addUnderlyingAsset(1);
        let minePool = await FNXMinePool.deployed();
        await web3.eth.sendTransaction({from:accounts[0],to:minePool.address,value:9e18});
        await fnx.transfer(minePool.address,new BN("100000000000000000000",10));
//        console.log(tx);
//        return;
        await OptionsManger.addWhiteList(fnx.address);
        await OptionsManger.addCollateral(collateral0,10000000000000,{value : 10000000000000});
        let minebalance = await minePool.getMinerBalance(accounts[0],collateral0);
        console.log(33333333333333,minebalance.toString(10));
        minebalance = await minePool.getMinerBalance(accounts[0],fnx.address);
        console.log(33333333333333,minebalance.toString(10));
        for (var i=0;i<100;i++){
                await options.addExpiration(month);
        }
        await logBalance(fnx,collateralInstance.address);
        await OptionsManger.addCollateral(collateral0,1000000000000000,{from : accounts[1],value : 1000000000000000});
        minebalance = await minePool.getMinerBalance(accounts[0],collateral0);
        console.log(33333333333333,minebalance.toString(10));
        minebalance = await minePool.getMinerBalance(accounts[0],fnx.address);
        console.log(33333333333333,minebalance.toString(10));
        for (var i=0;i<100;i++){
                await options.addExpiration(month);
        }
        await logBalance(fnx,collateralInstance.address);
        await fnx.approve(OptionsManger.address,1000000000000000);
        await OptionsManger.addCollateral(fnx.address,1000000000000000);
        await logBalance(fnx,collateralInstance.address);
        let result = await options.getTotalOccupiedCollateral();
        console.log(result.toString(10));
        result = await OptionsManger.getTotalCollateral();
        console.log(result.toString(10));
        result = await OptionsManger.getOccupiedCollateral();
        console.log(result.toString(10));
        result = await OptionsManger.getLeftCollateral();
        console.log(result.toString(10));
        result = await OptionsManger.getTokenNetworth();
        console.log("1-----------------------------------",result.toString(10));

        minebalance = await minePool.getMinerBalance(accounts[0],collateral0);
        console.log(33333333333333,minebalance.toString(10));
        minebalance = await minePool.getMinerBalance(accounts[0],fnx.address);
        console.log(33333333333333,minebalance.toString(10));
        minebalance = await minePool.getMinerBalance(accounts[1],collateral0);
        console.log(44444444444444,minebalance.toString(10));
        minebalance = await minePool.getMinerBalance(accounts[1],fnx.address);
        console.log(44444444444444,minebalance.toString(10));

//        fnx.approve(OptionsManger.address,1000000000000000);
//        tx = await OptionsManger.buyOption(fnx.address,1000000000000000,20000000000,1,month,10000000000,0);
//        console.log(tx)
       
        tx = await OptionsManger.buyOption(collateral0,1000000000000000,9000e8,1,month,10000000000,0,{value : 1000000000000000});
//        console.log(tx);
        tx = await OptionsManger.buyOption(collateral0,1000000000000000,9500e8,1,month,10000000000,0,{value : 1000000000000000});
//        console.log(tx);
        tx = await OptionsManger.buyOption(collateral0,200000000000000,8000e8,1,month,10000000000,0,{value : 200000000000000});
//        console.log(tx);
        result = await options.getTotalOccupiedCollateral();
        console.log(result.toString(10));
        result = await OptionsManger.getTotalCollateral();
        console.log(result.toString(10));
        result = await OptionsManger.getOccupiedCollateral();
        console.log(result.toString(10));
        result = await OptionsManger.getLeftCollateral();
        console.log(result.toString(10));
        result = await OptionsManger.getTokenNetworth();
        console.log("2-----------------------------------",result.toString(10));
        result = await options.getOptionsById(1);
        console.log(result[0].toString(10),result[1],result[2].toString(10),result[3].toString(10),result[4].toString(10),result[5].toString(10),result[6].toString(10));
        result = await options.getOptionsById(2);
        console.log(result[0].toString(10),result[1],result[2].toString(10),result[3].toString(10),result[4].toString(10),result[5].toString(10),result[6].toString(10));
        result = await options.getOptionsById(3);
        console.log(result[0].toString(10),result[1],result[2].toString(10),result[3].toString(10),result[4].toString(10),result[5].toString(10),result[6].toString(10));
        for (var i=0;i<100;i++){
                await options.addExpiration(month);
        }
//        tx = await OptionsManger.sellOption(1,10000000000);
//        console.log(tx);
//        tx = await OptionsManger.exerciseOption(3,10000000000);
        result = await options.getOptionsById(1);
        console.log(result[0].toString(10),result[1],result[2].toString(10),result[3].toString(10),result[4].toString(10),result[5].toString(10),result[6].toString(10));
        result = await options.getOptionsById(2);
        console.log(result[0].toString(10),result[1],result[2].toString(10),result[3].toString(10),result[4].toString(10),result[5].toString(10),result[6].toString(10));
        result = await options.getOptionsById(3);
        console.log(result[0].toString(10),result[1],result[2].toString(10),result[3].toString(10),result[4].toString(10),result[5].toString(10),result[6].toString(10));
//        console.log(tx);
        result = await options.getTotalOccupiedCollateral();
        console.log(result.toString(10));
        result = await OptionsManger.getTotalCollateral();
        console.log(result.toString(10));
        result = await OptionsManger.getOccupiedCollateral();
        console.log(result.toString(10));
        result = await OptionsManger.getLeftCollateral();
        console.log(result.toString(10));
        result = await OptionsManger.getTokenNetworth();
        console.log("3-----------------------------------",result.toString(10));
        await calculateNetWroth(options,OptionsManger,fnx);
        result = await options.getTotalOccupiedCollateral();
        console.log(result.toString(10));
        result = await OptionsManger.getTotalCollateral();
        console.log(result.toString(10));
        result = await OptionsManger.getOccupiedCollateral();
        console.log(result.toString(10));
        result = await OptionsManger.getLeftCollateral();
        console.log(result.toString(10));
        result = await OptionsManger.getTokenNetworth();
        console.log("4-----------------------------------",result.toString(10));
        for (var i=0;i<100;i++){
                await options.addExpiration(month);
        }
        await logBalance(fnx,collateralInstance.address);
        await OptionsManger.redeemCollateral(498500000000000,collateral0);
        await calculateNetWroth(options,OptionsManger,fnx);
        await logBalance(fnx,collateralInstance.address);
        result = await options.getTotalOccupiedCollateral();
        console.log(result.toString(10));
        result = await OptionsManger.getTotalCollateral();
        console.log(result.toString(10));
        result = await OptionsManger.getOccupiedCollateral();
        console.log(result.toString(10));
        result = await OptionsManger.getLeftCollateral();
        console.log(result.toString(10));
        result = await OptionsManger.getTokenNetworth();
        console.log("5-----------------------------------",result.toString(10));
        await OptionsManger.redeemCollateral(498500000000000,fnx.address);
        await logBalance(fnx,collateralInstance.address);
        await OptionsManger.redeemCollateral(498500000000000,fnx.address,{from:accounts[1]});
        await logBalance(fnx,collateralInstance.address);
//        await OptionsManger.redeemCollateral(0,fnx.address,{from:accounts[2]});
 //       await logBalance(fnx,collateralInstance.address);
        result = await options.getTotalOccupiedCollateral();
        console.log(result.toString(10));
        result = await OptionsManger.getTotalCollateral();
        console.log(result.toString(10));
        result = await OptionsManger.getOccupiedCollateral();
        console.log(result.toString(10));
        result = await OptionsManger.getLeftCollateral();
        console.log(result.toString(10));
        result = await OptionsManger.getAvailableCollateral();
        console.log(result.toString(10));
        result = await OptionsManger.getTokenNetworth();

        console.log("5-----------------------------------",result.toString(10));
        minebalance = await minePool.getMinerBalance(accounts[0],collateral0);
        await minePool.redeemMinerCoin(collateral0,minebalance);
        minebalance = await minePool.getMinerBalance(accounts[0],collateral0);
        console.log(33333333333333,minebalance.toString(10));
        minebalance = await minePool.getMinerBalance(accounts[0],fnx.address);
        await minePool.redeemMinerCoin(fnx.address,minebalance);
        minebalance = await minePool.getMinerBalance(accounts[0],fnx.address);
        console.log(33333333333333,minebalance.toString(10));
        minebalance = await minePool.getMinerBalance(accounts[1],collateral0);
        await minePool.redeemMinerCoin(collateral0,minebalance,{from:accounts[1]});
        minebalance = await minePool.getMinerBalance(accounts[1],collateral0);        
        console.log(44444444444444,minebalance.toString(10));
        minebalance = await minePool.getMinerBalance(accounts[1],fnx.address);
        await minePool.redeemMinerCoin(fnx.address,minebalance,{from:accounts[1]});
        minebalance = await minePool.getMinerBalance(accounts[1],fnx.address);    
        console.log(44444444444444,minebalance.toString(10));
    });
});
async function logBalance(fnx,addr){
        let colBalance = await web3.eth.getBalance(addr);
        console.log("eth : ",addr,colBalance);
        let fnxBalance = await fnx.balanceOf(addr);
        console.log("fnx : ",addr,fnxBalance.toString(10));
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