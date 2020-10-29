
const BN = require("bn.js");
let month = 30*60*60*24;
let collateral0 = "0x0000000000000000000000000000000000000000";
let {migration ,createAndAddErc20,AddCollateral0} = require("./testFunction.js");
contract('OptionsManagerV2', function (accounts){
    it('OptionsManagerV2 buy options', async function (){
        let contracts = await migration(accounts);
        await AddCollateral0(contracts);
        await createAndAddErc20(contracts);
        let collAmount = new BN("1000000000000000000000000",10);
        await contracts.FNX.approve(contracts.manager.address,collAmount);
        await contracts.manager.addCollateral(contracts.FNX.address,collAmount);
        let days = 24*60*60;
        let expiration = [days,2*days,3*days, 7*days, 10*days, 15*days,20*days, 30*days];
        for (var i=0;i<20;i++){
            await contracts.FNX.approve(contracts.manager.address,2000000000000000);
            let strikePrice = 50*i + 900000000000;
            await contracts.manager.buyOption(contracts.FNX.address,1000000000000000,strikePrice,1,expiration[i%expiration.length],
                100000000000,1);
        }
        // for (var i=0;i<20;i++){
        //     await contracts.manager.sellOption(i+1,100000000000);
        // }
    });
});