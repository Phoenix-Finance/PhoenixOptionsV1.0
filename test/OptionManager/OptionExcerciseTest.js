
const BN = require("bn.js");
const assert = require('assert');
let month = 10;
let ETH = "0x0000000000000000000000000000000000000000";
let {migration ,createAndAddErc20,createAndAddUSDC,AddCollateral0} = require("../testFunction.js");
let PRICEONE= 1e8;
let PRICETWO = 2e8;
let PRICETHREE = 3e8;
let PRICEFOUR = 4e8;
contract('OptionsManagerV2', function (accounts) {
    let contracts;
    let ethAmount = new BN("10000000000000000000");
    let usdcAmount = 10000000000;

    let payamount = new BN("100000000000000000000");
    let optamount = new BN("2000000000000000000");

    let FNXAmount =  new BN("100000000000000000000");;

    before(async () => {
        contracts = await migration(accounts);
        await AddCollateral0(contracts);
        await createAndAddErc20(contracts);
        await createAndAddUSDC(contracts);
    });

    it('FNX buy and exercise', async function () {
        let collAmount = new BN("1000000000000000000000000",10);
        await contracts.FNX.approve(contracts.manager.address,collAmount);
        await contracts.manager.addCollateral(contracts.FNX.address,collAmount);
        let days = 24*60*60;
        let expiration = [days,2*days,3*days, 7*days, 10*days, 15*days,20*days, 30*days];
        contracts.oracle.setFakeUnderlyingPrice(PRICETWO);
        let i =0 ;
        //for (var i=0;i<20;i++){
        await contracts.FNX.approve(contracts.manager.address,2000000000000000);
        let strikePrice = PRICETWO;
        let tx = await contracts.manager.buyOption(contracts.FNX.address,1000000000000000,strikePrice,1,expiration[i%expiration.length],100000000000,1);
        assert.equal(tx.receipt.status,true);
        //}


        //for (var i=0;i<20;i++){
         contracts.oracle.setFakeUnderlyingPrice(PRICEONE);
         tx = await contracts.manager.exerciseOption(1,100000000000);
         assert.equal(tx.receipt.status,true);
        //}
    })
})