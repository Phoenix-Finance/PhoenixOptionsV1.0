const BN = require("bn.js");
let month = 30;
let collateral0 = "0x0000000000000000000000000000000000000000";
const OptionsPrice = artifacts.require("OptionsPriceTest");
let {migration ,createAndAddErc20,AddCollateral0} = require("./testFunction.js");
let curtime;
contract('OptionsManagerV2', function (accounts){
    it('OptionsManagerV2 cal networth', async function (){
        let contracts = await migration(accounts);
        contracts.price = await OptionsPrice.new(contracts.iv.address);
        contracts.options.setOptionsPriceAddress(contracts.price.address);
        contracts.manager.setOptionsPriceAddress(contracts.price.address);
        await AddCollateral0(contracts);
        await createAndAddErc20(contracts);
        //await contracts.price.setExpirationZoom(1000);
        contracts.options.addExpiration(month);
        let amount = 1e14;
        await logNetWroth(1,contracts);
        await contracts.manager.addCollateral(collateral0,amount,{value : amount});
        await logNetWroth(2,contracts);
        await contracts.manager.addCollateral(collateral0,amount,{value : amount});
        await logNetWroth(3,contracts);
        await contracts.FNX.approve(contracts.manager.address,10000000000000);
        await contracts.manager.addCollateral(contracts.FNX.address,10000000000000);
        let whiteList = await contracts.manager.getWhiteList();
        tx = await contracts.collateral.calSharedPayment(whiteList);
        curtime = Date.now();
        tx = await contracts.manager.buyOption(collateral0,1000000000000000,9000e8,1,month,10000000000,0,{value : 1000000000000000});
        await logNetWroth(4,contracts);
        tx = await contracts.manager.buyOption(collateral0,1000000000000000,9000e8,1,month,10000000000,0,{value : 1000000000000000});
        await contracts.FNX.approve(contracts.manager.address,1000000000000000);
        await contracts.manager.buyOption(contracts.FNX.address,1000000000000000,9000e8,1,month,10000000000,1);
//        console.log(tx);
        tx = await contracts.manager.buyOption(collateral0,200000000000000,8000e8,1,month,10000000000,0,{value : 200000000000000});
        tx = await contracts.manager.buyOption(collateral0,200000000000000,8000e8,1,month,20000000000,0,{from:accounts[1],value : 200000000000000});
//        console.log(tx);
        await logNetWroth(5,contracts);
        await calculateNetWroth(contracts,contracts.FNX);
        await logNetWroth(6,contracts);
        for (var i=0;i<50;i++){
            await contracts.options.addExpiration(month);
        }
        await calculateNetWroth(contracts,contracts.FNX);
        await logNetWroth(7,contracts);
        // tx = await contracts.manager.sellOption(1,10000000000);
        // await logNetWroth(8,contracts);
        // tx = await contracts.manager.sellOption(2,10000000000);
        // await logNetWroth(9,contracts);
        // tx = await contracts.manager.sellOption(3,10000000000);
        // await logNetWroth(10,contracts);
        console.log("-----------------------------------------");
        await calculateNetWroth(contracts,contracts.FNX);
        await logNetWroth(11,contracts);
        for (var i=0;i<100;i++){
            await contracts.options.addExpiration(month);
        }
        await calculateNetWroth(contracts,contracts.FNX);
        await logNetWroth(12,contracts);
    });
    it('OptionsManagerV2 exercise networth', async function (){
        let contracts = await migration(accounts);
        contracts.price = await OptionsPrice.new(contracts.iv.address);
        contracts.options.setOptionsPriceAddress(contracts.price.address);
        contracts.manager.setOptionsPriceAddress(contracts.price.address);
        await AddCollateral0(contracts);
        await createAndAddErc20(contracts);
        //await contracts.price.setExpirationZoom(1000);
        contracts.options.addExpiration(month);
        contracts.options.addExpiration(month);
        let Index = await contracts.options.getOptionInfoLength();
        Index = Index.toNumber();
        let amount = 1e14;
        await contracts.manager.addCollateral(collateral0,amount,{value : amount});
        await logNetWroth(21,contracts);
        await contracts.manager.addCollateral(collateral0,amount,{value : amount});
        await logNetWroth(22,contracts);
        await contracts.FNX.approve(contracts.manager.address,10000000000000);
        await contracts.manager.addCollateral(contracts.FNX.address,10000000000000);

       
        tx = await contracts.manager.buyOption(collateral0,1000000000000000,9000e8,1,month,10000000000,0,{value : 1000000000000000});
//        console.log(tx);
        tx = await contracts.manager.buyOption(collateral0,1000000000000000,9000e8,1,month,10000000000,0,{value : 1000000000000000});

//        console.log(tx);
        tx = await contracts.manager.buyOption(collateral0,200000000000000,8000e8,1,month,10000000000,0,{value : 200000000000000});
        tx = await contracts.manager.buyOption(collateral0,200000000000000,8000e8,1,month,20000000000,0,{from:accounts[1],value : 200000000000000});
        await contracts.FNX.approve(contracts.manager.address,1000000000000000);
        await contracts.manager.buyOption(contracts.FNX.address,1000000000000000,9000e8,1,month,10000000000,1);
        //        console.log(tx);
        await logNetWroth(23,contracts);
        await calculateNetWroth(contracts,contracts.FNX);
        await logNetWroth(24,contracts);
        for (var i=0;i<50;i++){
            await contracts.options.addExpiration(month);
        }
        await calculateNetWroth(contracts,contracts.FNX);
        await logNetWroth(25,contracts);
        tx = await contracts.manager.exerciseOption(Index+1,10000000000);
        await logNetWroth(26,contracts);
        tx = await contracts.manager.exerciseOption(Index+2,10000000000);
        await logNetWroth(27,contracts);
        tx = await contracts.manager.exerciseOption(Index+3,10000000000);
        await logNetWroth(28,contracts);
        await calculateNetWroth(contracts,contracts.FNX);
        await logNetWroth(29,contracts);
        for (var i=0;i<100;i++){
            await contracts.options.addExpiration(month);
        }
        await calculateNetWroth(contracts,contracts.FNX);
        await logNetWroth(30,contracts);
    });
});
async function logBalance(fnx,addr){
        let colBalance = await web3.eth.getBalance(addr);
        console.log("eth : ",addr,colBalance);
        let fnxBalance = await fnx.balanceOf(addr);
        console.log("fnx : ",addr,fnxBalance.toString(10));
}
async function logNetWroth(id,contracts){
    console.log(id,Date.now()-curtime)
    let result = await contracts.manager.getTotalCollateral();
    console.log(id,"TotalCollateral : ",result.toString(10));
    result = await contracts.options.getNetWrothLatestWorth(collateral0);
    console.log(id,"LatestWorth : ",result.toString(10));
    result = await contracts.options.getTotalOccupiedCollateral();
    console.log(id,"TotalOccupied : ",result.toString(10));
    result = await contracts.manager.getOccupiedCollateral();
    console.log(id,"TotalOccupied*5 : ",result.toString(10));
    result = await contracts.manager.getLeftCollateral();
    console.log(id,"LeftCollateral : ",result.toString(10));
    result = await contracts.manager.getTokenNetworth();
    console.log(id,"Networth : ",result.toString(10));
}
async function calculateNetWroth(contracts,fnx){
    let whiteList = [collateral0,fnx.address];
    optionsLen = await contracts.options.getOptionCalRangeAll(whiteList);
    console.log(optionsLen[0].toString(10),optionsLen[1].toString(10),optionsLen[2].toString(10),optionsLen[4].toString(10));

    let result =  await contracts.options.calculatePhaseOccupiedCollateral(optionsLen[5],optionsLen[0],optionsLen[5]);
    console.log(result[0].toString(10),result[1].toString(10));
    let tx = await contracts.options.setOccupiedCollateral();
    result =  await contracts.options.calRangeSharedPayment(optionsLen[5],optionsLen[3],optionsLen[5],whiteList);
    console.log(result[0][0].toString(10),result[0][1].toString(10));

//                return;
    tx = await contracts.collateral.calSharedPayment(whiteList);
//    console.log(tx);
}