const OptionsManagerV2 = artifacts.require("OptionsManagerV2");
const OptionsPool = artifacts.require("OptionsPoolTest");
const FPTCoin = artifacts.require("FPTCoin");
const OptionsPrice = artifacts.require("OptionsPrice");
let CollateralPool = artifacts.require("CollateralPool");
let FNXCoin = artifacts.require("FNXCoin");
const BN = require("bn.js");
let month = 30*60*60*24;
//let collateral0 = "0x0000000000000000000000000000000000000000";
let testFunc = require("./testFunction.js")
let FNXMinePool = artifacts.require("FNXMinePool");
contract('OptionsManagerV2', function (accounts){
    it('OptionsManagerV2 redeem collateral', async function (){
        let OptionsManger = await OptionsManagerV2.deployed();
        let collateralInstance = await CollateralPool.deployed();
        let options = await OptionsPool.deployed();
        let fnx = await FNXCoin.deployed();
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
        await OptionsManger.redeemCollateral(500000000000000,fnx.address);
        await logBalance(fnx,collateralInstance.address);
        await logBalance(fnx,accounts[0]);
        
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