
let FNXCoin = artifacts.require("FNXCoin");
const BN = require("bn.js");
let month = 30*60*60*24;
let collateral0 = "0x0000000000000000000000000000000000000000";
let {migration ,createAndAddErc20,AddCollateral0} = require("./testFunction.js");
contract('OptionsManagerV2', function (accounts){
    it('OptionsManagerV2 add multiple collateral', async function (){
        let contracts = await migration(accounts);
        
        await createAndAddErc20(contracts);
        let fnx1 = await FNXCoin.new();
        let fnx2 = await FNXCoin.new();
        let fnx3 = await FNXCoin.new();
        await contracts.manager.setCollateralRate(fnx1.address,3000);
        await contracts.manager.setCollateralRate(fnx2.address,3000);
        await contracts.manager.setCollateralRate(fnx3.address,3000);
        fnx3 = await FNXCoin.new();
        await contracts.manager.setCollateralRate(fnx3.address,3000);
        let result = await contracts.manager.getWhiteList();
        console.log(result);
        for (var i=0;i<10;i++){
            for (var j=0;j<5;j++){
                let fnx = await FNXCoin.at(result[j]);
                await fnx.approve(contracts.manager.address,1000000000000000);
                await contracts.manager.addCollateral(result[j],1000000000000000);
            }
            await AddCollateral0(contracts);
            contracts.manager.buyOption(collateral0,1000000000000000,9150*1e8,1,month,10000000000,0,{value : 1000000000000000});
            contracts.manager.buyOption(collateral0,1000000000000000,8250*1e8,1,month,10000000000,0,{value : 1000000000000000});
            contracts.manager.buyOption(collateral0,1000000000000000,9257*1e8,1,month,10000000000,0,{value : 1000000000000000});
            contracts.manager.buyOption(collateral0,1000000000000000,9251*1e8,1,month,10000000000,0,{value : 1000000000000000});
            contracts.manager.buyOption(collateral0,1000000000000000,11250*1e8,1,month,10000000000,0,{value : 1000000000000000});
            contracts.manager.buyOption(collateral0,1000000000000000,9253*1e8,1,month,10000000000,0,{value : 1000000000000000});
            contracts.manager.buyOption(collateral0,1000000000000000,9260*1e8,1,month,10000000000,0,{value : 1000000000000000});

            contracts.manager.buyOption(collateral0,1000000000000000,11050*1e8,1,month,10000000000,1,{value : 1000000000000000});
            contracts.manager.buyOption(collateral0,1000000000000000,9056*1e8,1,month,10000000000,1,{value : 1000000000000000});
    //        console.log(tx);
            await contracts.manager.buyOption(collateral0,200000000000000,9258*1e8,1,month,10000000000,1,{value : 200000000000000});
    //        console.log(tx);
            await calculateNetWroth(contracts);
            for (var j=0;j<5;j++){
                await contracts.manager.redeemCollateral(4985000000000,result[j]);
                //await contracts.manager.sellOption(j+1,10000000000);
            }
            return;
        }
    });
});
async function calculateNetWroth(contracts){
    let whiteList = await contracts.manager.getWhiteList();
    optionsLen = await contracts.options.getOptionCalRangeAll(whiteList);
    console.log(optionsLen[0].toString(10),optionsLen[1].toString(10),optionsLen[2].toString(10),optionsLen[4].toString(10));

    let result =  await contracts.options.calculatePhaseOccupiedCollateral(optionsLen[4],optionsLen[0],optionsLen[4]);
    console.log(result[0].toString(10),result[1].toString(10));
    let tx = await contracts.options.setOccupiedCollateral();
//    result =  await options.calRangeSharedPayment(optionsLen[4],optionsLen[2],optionsLen[4],whiteList);
//    console.log(result[0][0].toString(10),result[0][1].toString(10));

//                return;q
    tx = await contracts.collateral.calSharedPayment(whiteList);
    console.log(tx);
}