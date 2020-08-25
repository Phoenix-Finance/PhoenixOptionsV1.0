const OptionsManagerV2 = artifacts.require("OptionsManagerV2");
const OptionsPool = artifacts.require("OptionsPoolTest");
const OptionsPrice = artifacts.require("OptionsPrice");
let CollateralPool = artifacts.require("CollateralPool");
let FNXCoin = artifacts.require("FNXCoin");
const BN = require("bn.js");
let month = 30*60*60*24;
let collateral0 = "0x0000000000000000000000000000000000000000";
let testFunc = require("./testFunction.js")
let FNXMinePool = artifacts.require("FNXMinePool");
contract('OptionsManagerV2', function (accounts){
    it('OptionsManagerV2 add small collateral', async function (){
        let collateralInstance = await CollateralPool.deployed();
        let OptionsManger = await OptionsManagerV2.deployed();
        let options = await OptionsPool.deployed();
        let fnx1 = await FNXCoin.new();
        let fnx2 = await FNXCoin.new();
        let fnx3 = await FNXCoin.new();
        await OptionsManger.addWhiteList(fnx1.address);
        await OptionsManger.addWhiteList(fnx2.address);
        await OptionsManger.addWhiteList(fnx3.address);
        fnx3 = await FNXCoin.new();
        await OptionsManger.addWhiteList(fnx3.address);
        let result = await OptionsManger.getWhiteList();
        console.log(result);
        for (var i=0;i<10;i++){
            for (var j=0;j<5;j++){
                let fnx = await FNXCoin.at(result[j]);
                await fnx.approve(OptionsManger.address,1000000000000000);
                await OptionsManger.addCollateral(result[j],1000000000000000);
            }
            await OptionsManger.addWhiteList(collateral0);
            OptionsManger.buyOption(collateral0,1000000000000000,9150*1e8,1,month,10000000000,0,{value : 1000000000000000});
            OptionsManger.buyOption(collateral0,1000000000000000,8250*1e8,1,month,10000000000,0,{value : 1000000000000000});
            OptionsManger.buyOption(collateral0,1000000000000000,9257*1e8,1,month,10000000000,0,{value : 1000000000000000});
            OptionsManger.buyOption(collateral0,1000000000000000,9251*1e8,1,month,10000000000,0,{value : 1000000000000000});
            OptionsManger.buyOption(collateral0,1000000000000000,11250*1e8,1,month,10000000000,0,{value : 1000000000000000});
            OptionsManger.buyOption(collateral0,1000000000000000,9253*1e8,1,month,10000000000,0,{value : 1000000000000000});
            OptionsManger.buyOption(collateral0,1000000000000000,9260*1e8,1,month,10000000000,0,{value : 1000000000000000});

            OptionsManger.buyOption(collateral0,1000000000000000,11050*1e8,1,month,10000000000,1,{value : 1000000000000000});
            OptionsManger.buyOption(collateral0,1000000000000000,9056*1e8,1,month,10000000000,1,{value : 1000000000000000});
    //        console.log(tx);
            await OptionsManger.buyOption(collateral0,200000000000000,9258*1e8,1,month,10000000000,1,{value : 200000000000000});
    //        console.log(tx);
            await calculateNetWroth(options,OptionsManger);
            for (var j=0;j<5;j++){
                await OptionsManger.redeemCollateral(4985000000000,result[j]);
                await OptionsManger.sellOption(j+1,10000000000);
            }
            return;
        }
    });
});
async function calculateNetWroth(options,OptionsManger){
    let whiteList = await OptionsManger.getWhiteList();
    optionsLen = await options.getOptionCalRangeAll(whiteList);
    console.log(optionsLen[0].toString(10),optionsLen[1].toString(10),optionsLen[2].toString(10),optionsLen[4].toString(10));

    let result =  await options.calculatePhaseOccupiedCollateral(optionsLen[4],optionsLen[0],optionsLen[4]);
    console.log(result[0].toString(10),result[1].toString(10));
    let tx = await options.setOccupiedCollateral();
//    result =  await options.calRangeSharedPayment(optionsLen[4],optionsLen[2],optionsLen[4],whiteList);
//    console.log(result[0][0].toString(10),result[0][1].toString(10));

//                return;q
    tx = await OptionsManger.calSharedPayment();
    console.log(tx);
}