const BN = require("bn.js");
let collateral0 = "0x0000000000000000000000000000000000000000";
let {migration ,createAndAddErc20,AddCollateral0} = require("./testFunction.js");
contract('OptionsPool', function (accounts){
    it('OptionsPool add collateral', async function (){
        let contracts = await migration(accounts);
        await AddCollateral0(contracts);
        await createAndAddErc20(contracts);
        let deposit = new BN(1000*1e6);
        let decemal = new BN(1e12);
        deposit = deposit.mul(decemal);
        let wanPrice = 278*1e5;
        await contracts.oracle.setPrice(collateral0,wanPrice);
        let btcPrice = 9500*1e8;
        await contracts.oracle.setUnderlyingPrice(1,btcPrice);
        await contracts.manager.addCollateral(collateral0,deposit,{value : deposit});
        let amount = 100000000000;
        let optionInfos = [];
        for (var i=0;i<1;i++){
            info1 = {
                strikePrice : (9000+i*100)*1e8,
                expiration : 24*3600,
                opType : 0,
                optionId: i*2+1,
                amount : amount,
            }
            await addBuyOptions(wanPrice,btcPrice,contracts.price,contracts.manager,info1.strikePrice,
                info1.expiration,info1.opType,amount);
            optionInfos.push(info1);
            info1 = {
                strikePrice : (9000+i*100)*1e8,
                expiration : 24*3600,
                opType : 1,
                optionId: i*2+2,
                amount : amount,
            }
            await addBuyOptions(wanPrice,btcPrice,contracts.price,contracts.manager,info1.strikePrice,
                info1.expiration,info1.opType,amount);
            optionInfos.push(info1);
        }
        await setPhaseCollateral(contracts.options);
        
        for (var i=0;i<optionInfos.length;i++){
            
            info1 = optionInfos[i];
            let sellAmount = info1.amount/2;
            // console.log("sellOption :",info1.optionId,sellAmount)
            // await contracts.manager.sellOption(info1.optionId,sellAmount);
            info1.amount -= sellAmount;
        }
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
        let result = await contracts.options.getTotalOccupiedCollateral();
        assert.equal(totalCollateral.toString(10),result.toString(10),"getTotalOccupiedCollateral error");
        btcPrice = 11000*1e8;
        await contracts.oracle.setUnderlyingPrice(1,btcPrice);
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
        await setPhaseCollateral(contracts.options);
        result = await contracts.options.getTotalOccupiedCollateral();
        assert.equal(totalCollateral.toString(10),result.toString(10),"getTotalOccupiedCollateral error");
        btcPrice = 8000*1e8;
        await contracts.oracle.setUnderlyingPrice(1,btcPrice);
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
        await setPhaseCollateral(contracts.options);
        result = await contracts.options.getTotalOccupiedCollateral();
        assert.equal(totalCollateral.toString(10),result.toString(10),"getTotalOccupiedCollateral error");
    })
})
async function setPhaseCollateral(optionsInstance){
    await optionsInstance.setOccupiedCollateral();
}
async function addBuyOptions(wanPrice,btcPrice,priceInstance,OptionsManger,strikePrice,expiration,optType,amount){
    console.log(strikePrice,expiration,optType,amount);
    let opPrice = await priceInstance.getOptionsPrice(btcPrice,strikePrice,expiration,1,optType);
    let payfor = opPrice*amount;
    payfor = Math.ceil(payfor*1.003/wanPrice);
    console.log("-----------buy option",payfor,amount);
    await OptionsManger.buyOption(collateral0,0,strikePrice,1,expiration,amount,optType,{value:payfor});
}