const BN = require("bn.js");
let month = 30*60*60*24;
let {migration ,createAndAddErc20,AddCollateral0} = require("./testFunction.js");
contract('OptionsManagerV2', function (accounts){
    it('OptionsManagerV2 redeem collateral', async function (){
        let contracts = await migration(accounts);
        await createAndAddErc20(contracts);

//        await contracts.manager.setCollateralRate(fnx.addres,5000);
        await contracts.FNX.approve(contracts.manager.address,10000000000000);
        await contracts.manager.addCollateral(contracts.FNX.address,10000000000000);
        await logBalance(contracts.FNX,contracts.collateral.address);
        await logBalance(contracts.FNX,accounts[0]);
        for (var i=0;i<10;i++){
                await contracts.manager.addWhiteList(contracts.FNX.address);
        }
        await contracts.manager.redeemCollateral(500000000000000,contracts.FNX.address);
        await logBalance(contracts.FNX,contracts.collateral.address);
        await logBalance(contracts.FNX,accounts[0]);
        await contracts.FNX.approve(contracts.manager.address,10000000000000);
        await contracts.manager.addCollateral(contracts.FNX.address,10000000000000);
        await logBalance(contracts.FNX,contracts.collateral.address);
        await logBalance(contracts.FNX,accounts[0]);
        for (var i=0;i<10;i++){
                await contracts.manager.addWhiteList(contracts.FNX.address);
        }
        await contracts.manager.redeemCollateral(500000000000000,contracts.FNX.address);
        await logBalance(contracts.FNX,contracts.collateral.address);
        await logBalance(contracts.FNX,accounts[0]);
        await contracts.FNX.approve(contracts.manager.address,10000000000000);
        await contracts.manager.addCollateral(contracts.FNX.address,10000000000000);
        await logBalance(contracts.FNX,contracts.collateral.address);
        await logBalance(contracts.FNX,accounts[0]);
        for (var i=0;i<10;i++){
                await contracts.manager.addWhiteList(contracts.FNX.address);
        }
        await contracts.manager.redeemCollateral(500000000000000,contracts.FNX.address);
        await logBalance(contracts.FNX,contracts.collateral.address);
        await logBalance(contracts.FNX,accounts[0]);
        await contracts.FNX.approve(contracts.manager.address,10000000000000);
        await contracts.manager.addCollateral(contracts.FNX.address,10000000000000);
        await logBalance(contracts.FNX,contracts.collateral.address);
        await logBalance(contracts.FNX,accounts[0]);
        for (var i=0;i<10;i++){
                await contracts.manager.addWhiteList(contracts.FNX.address);
        }
        await contracts.manager.redeemCollateral(500000000000000,contracts.FNX.address);
        await logBalance(contracts.FNX,contracts.collateral.address);
        await logBalance(contracts.FNX,accounts[0]);
        
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