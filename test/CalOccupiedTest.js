const OptionsManagerV2 = artifacts.require("OptionsManagerV2");
const OptionsPool = artifacts.require("OptionsPool");
const ImpliedVolatility = artifacts.require("ImpliedVolatility");
const OptionsPrice = artifacts.require("OptionsPrice");
let FNXCoin = artifacts.require("FNXCoin");
let month = 30*60*60*24;
let collateral0 = "0x0000000000000000000000000000000000000000";
const BN = require("bn.js");
const imVolatility32 = artifacts.require("imVolatility32");
let testFunc = require("./testFunction.js")
contract('OptionsManagerV2', function (accounts){
    it('OptionsManagerV2 add collateral', async function (){
        let volInstance = await imVolatility32.deployed();
        await testFunc.AddImpliedVolatility(volInstance,false);
        let OptionsManger = await OptionsManagerV2.deployed();
        let options = await OptionsPool.deployed();
//        let ivInstance = await ImpliedVolatility.at("0x54E8BB9dEC82B695C0Fa977070e74a06BE68001d");
//        let iv = await ivInstance.calculateIv(month,10000000000);
//        console.log(iv[0].toString(10),iv[1].toString(10))
//        let optionPrice = await OptionsPrice.deployed();
//        let temp = await optionPrice.getOptionsPrice_iv(20000000000,20000000000,month,iv[0],iv[1],0);
//        console.log(temp.toString(10))
        let fnx = await FNXCoin.deployed();
        let tx = await OptionsManger.addWhiteList(collateral0);
        tx = await OptionsManger.addWhiteList(fnx.address);
        await options.addUnderlyingAsset(1);
        await OptionsManger.addWhiteList(fnx.address); 
        await options.addExpiration(month);      
        for (var i=0;i<10;i++){
            for (var j=0;j<10;j++){
                OptionsManger.addCollateral(collateral0,1000000000000000,{value : 1000000000000000});
                OptionsManger.addCollateral(collateral0,1000000000000000,{value : 1000000000000000});
                OptionsManger.buyOption(collateral0,1000000000000000,9250*1e8,1,month,10000000000,0,{value : 1000000000000000});
                OptionsManger.buyOption(collateral0,1000000000000000,9250*1e8,1,month,10000000000,0,{value : 1000000000000000});
                OptionsManger.buyOption(collateral0,1000000000000000,9250*1e8,1,month,10000000000,0,{value : 1000000000000000});
                OptionsManger.buyOption(collateral0,1000000000000000,9250*1e8,1,month,10000000000,0,{value : 1000000000000000});

                OptionsManger.buyOption(collateral0,1000000000000000,9250*1e8,1,month,10000000000,0,{value : 1000000000000000});
                OptionsManger.buyOption(collateral0,1000000000000000,9250*1e8,1,month,10000000000,0,{value : 1000000000000000});
        //        console.log(tx);
                await OptionsManger.buyOption(collateral0,200000000000000,9250*1e8,1,month,10000000000,0,{value : 200000000000000});
        //        console.log(tx);
            }
            optionsLen = await options.getOptionInfoLength()
            for (j=0;j<Math.floor(optionsLen/400)+1;j++){
                let bn = new BN(j);
                let bn1 = new BN(20);
                bn1 = bn1.ushln(64);
                bn = bn.add(bn1);
                console.log(bn.toString(16));
                let result =  await options.calculatePhaseOccupiedCollateral(bn);
                console.log(result[0].toString(10),result[1].toString(10));
                let tx = await options.setPhaseOccupiedCollateral(bn);
                console.log(tx);
                let whiteList = [collateral0,fnx.address];
                result =  await options.calRangeSharedPayment(0,0,20,whiteList);
//                console.log(result[1].toString(10),result[2].toString(10));
//                return;
                tx = await OptionsManger.setPhaseSharedPayment(bn);
                console.log(tx);
                return;
            }  
        }
     });
});