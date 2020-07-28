const BN = require("bn.js");
let testFunc = require("./testFunction.js")
const OptionsManagerV2 = artifacts.require("OptionsManagerV2");
const OptionsPoolTest = artifacts.require("OptionsPoolTest");
const imVolatility32 = artifacts.require("imVolatility32");
const OptionsPrice = artifacts.require("OptionsPrice");
const FNXOracle = artifacts.require("TestFNXOracle");
let collateral0 = "0x0000000000000000000000000000000000000000";
contract('OptionsPoolTest', function (accounts){
    it('OptionsPoolTest add collateral', async function (){
        let optionsInstance = await OptionsPoolTest.deployed();
        let volInstance = await imVolatility32.deployed();
        let priceInstance = await OptionsPrice.deployed();
        let oracle = await FNXOracle.deployed();
        await testFunc.AddImpliedVolatility(volInstance,false);
        let OptionsManger = await OptionsManagerV2.deployed();
        await OptionsManger.addWhiteList(collateral0);
        let deposit = new BN(1000*1e6);
        let decemal = new BN(1e12);
        deposit = deposit.mul(decemal);
        let wanPrice = 278*1e5;
        await oracle.setPrice(collateral0,wanPrice);
        let btcPrice = 9500*1e8;
        await oracle.setUnderlyingPrice(1,btcPrice);
        await OptionsManger.addCollateral(collateral0,deposit,{value : deposit});
        let amount = 1000000000;
        let optionInfos = [];
        for (var i=0;i<1;i++){
            info1 = {
                strikePrice : (9000+i*100)*1e8,
                expiration : 24*3600,
                opType : 0,
                optionId: i*2+1,
                amount : amount,
            }
            await addBuyOptions(wanPrice,btcPrice,priceInstance,OptionsManger,info1.strikePrice,
                info1.expiration,info1.opType,amount);
            optionInfos.push(info1);
            info1 = {
                strikePrice : (9000+i*100)*1e8,
                expiration : 24*3600,
                opType : 1,
                optionId: i*2+2,
                amount : amount,
            }
            await addBuyOptions(wanPrice,btcPrice,priceInstance,OptionsManger,info1.strikePrice,
                info1.expiration,info1.opType,amount);
            optionInfos.push(info1);
        }
        await setPhaseCollateral(optionsInstance);
        
        for (var i=0;i<optionInfos.length;i++){
            
            info1 = optionInfos[i];
            let sellAmount = info1.amount/100*info1.optionId;
            console.log("sellOption :",info1.optionId,sellAmount)
            await OptionsManger.sellOption(info1.optionId,sellAmount);
            info1.amount -= sellAmount;
        }
        return;
        let totalCollateral = new BN(0);
        for (var i=0;i<optionInfos.length;i++){
            info1 = optionInfos[i];
            let amountBn = new BN(info1.amount);
            if (info1.opType == 0){
                let expect = new BN(Math.max(btcPrice,info1.strikePrice));
                totalCollateral = totalCollateral.add(expect.mul(amountBn));
            }else{
                let expect = new BN(Math.min(btcPrice,info1.strikePrice));
                totalCollateral = totalCollateral.add(expect.mul(amountBn));
            }
        }
        console.log(totalCollateral.toString(10));
        let result = await optionsInstance.getTotalOccupiedCollateral();
        assert.equal(totalCollateral.toString(10),result.toString(10),"getTotalOccupiedCollateral error");
        btcPrice = 11000*1e8;
        await oracle.setUnderlyingPrice(1,btcPrice);
        totalCollateral = new BN(0);
        for (var i=0;i<optionInfos.length;i++){
            info1 = optionInfos[i];
            let amountBn = new BN(info1.amount);
            if (info1.opType == 0){
                let expect = new BN(Math.max(btcPrice,info1.strikePrice));
                totalCollateral = totalCollateral.add(expect.mul(amountBn));
            }else{
                let expect = new BN(Math.min(btcPrice,info1.strikePrice));
                totalCollateral = totalCollateral.add(expect.mul(amountBn));
            }
        }
        console.log(totalCollateral.toString(10));
        await setPhaseCollateral(optionsInstance);
        result = await optionsInstance.getTotalOccupiedCollateral();
        assert.equal(totalCollateral.toString(10),result.toString(10),"getTotalOccupiedCollateral error");
        btcPrice = 8000*1e8;
        await oracle.setUnderlyingPrice(1,btcPrice);
        totalCollateral = new BN(0);
        for (var i=0;i<optionInfos.length;i++){
            info1 = optionInfos[i];
            let amountBn = new BN(info1.amount);
            if (info1.opType == 0){
                let expect = new BN(Math.max(btcPrice,info1.strikePrice));
                totalCollateral = totalCollateral.add(expect.mul(amountBn));
            }else{
                let expect = new BN(Math.min(btcPrice,info1.strikePrice));
                totalCollateral = totalCollateral.add(expect.mul(amountBn));
            }
        }
        console.log(totalCollateral.toString(10));
        await setPhaseCollateral(optionsInstance);
        result = await optionsInstance.getTotalOccupiedCollateral();
        assert.equal(totalCollateral.toString(10),result.toString(10),"getTotalOccupiedCollateral error");
    })
})
async function setPhaseCollateral(optionsInstance){
    let phaseRange =  await optionsInstance.getOptionPhaseCalRange();
    let bn = new BN(0);
    let bn1 = phaseRange[1];
    let bn2 = phaseRange[2];
    bn1 = bn1.ushln(64);
    bn2 = bn2.ushln(128);
    bn = bn.add(bn1).add(bn2);
    console.log(bn.toString(16));
    await optionsInstance.setPhaseOccupiedCollateral(bn);
}
async function addBuyOptions(wanPrice,btcPrice,priceInstance,OptionsManger,strikePrice,expiration,optType,amount){
    console.log(strikePrice,expiration,optType,amount);
    let opPrice = await priceInstance.getOptionsPrice(btcPrice,strikePrice,expiration,1,optType);
    let payfor = opPrice*amount;
    payfor = Math.ceil(payfor*1.003/wanPrice);
    console.log("-----------buy option",payfor,amount);
    await OptionsManger.buyOption(collateral0,0,strikePrice,1,expiration,amount,optType,{value:payfor});
}