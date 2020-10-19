
const BN = require("bn.js");
let month = 30*60*60*24;
let collateral0 = "0x0000000000000000000000000000000000000000";
let {migration ,createAndAddUSDC,createAndAddErc20,AddCollateral0} = require("./testFunction.js");
contract('OptionsManagerV2', function (accounts){
    it('OptionsManagerV2 buy options gas fee', async function (){
        let contracts = await migration(accounts);
        await AddCollateral0(contracts);
        await createAndAddErc20(contracts);
        await createAndAddUSDC(contracts);
        await contracts.manager.approve(accounts[0],new BN("10000000000000000000000",10));
        await contracts.FNX.approve(contracts.manager.address,10000000000000);
        await contracts.manager.addCollateral(contracts.FNX.address,10000000000000);
        await contracts.USDC.approve(contracts.manager.address,10000000000000);
        await contracts.manager.addCollateral(contracts.USDC.address,10000000000000);
        await contracts.manager.addCollateral(collateral0,10000000000000,{value:10000000000000});
        let tx = await contracts.manager.buyOption(collateral0,10000000000000,9153*1e8,1,month,100000000,0,{value : 10000000000000});
        console.log(tx.receipt.gasUsed);
        tx = await contracts.manager.buyOption(collateral0,10000000000000,9153*1e8,1,month,100000000,0,{value : 10000000000000});
        console.log(tx.receipt.gasUsed);
        tx = await contracts.manager.buyOption(collateral0,10000000000000,9153*1e8,1,month,100000000,0,{value : 10000000000000});
        console.log(tx.receipt.gasUsed);
        tx = await contracts.manager.buyOption(collateral0,10000000000000,9153*1e8,1,month,100000000,0,{value : 10000000000000});
        console.log(tx.receipt.gasUsed);
        tx = await contracts.manager.buyOption(collateral0,10000000000000,9153*1e8,1,month,100000000,0,{value : 10000000000000});
        console.log(tx.receipt.gasUsed);
        tx = await contracts.manager.buyOption(collateral0,10000000000000,9153*1e8,1,month,100000000,0,{value : 10000000000000});
        console.log(tx.receipt.gasUsed);
        
    });

});
