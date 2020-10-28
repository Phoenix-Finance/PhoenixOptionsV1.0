
const BN = require("bn.js");
const assert = require('assert');
let month = 10;
let ETH = "0x0000000000000000000000000000000000000000";
let {migration ,createAndAddErc20,createAndAddUSDC,AddCollateral0} = require("../testFunction.js");
let PRICEONE= 1e8;
let PRICETWO = 2e8;
let PRICETHREE = 3e8;
let PRICEFOUR = 4e8;
let SHIFTVALUE = 5e7;

let OPTION_UP = 0;
let OPTION_DOWN = 1;

let ETH_ID = 2;
let BTC_ID = 1;

contract('OptionsManagerV2', function (accounts) {
    let contracts;
    let collAmount = new BN("1000000000000000000000000",10);
    let payamount = new BN("1000000000000000");
    let optamount = new BN("100000000000");
    let days = 24*60*60;
    let expiration = [days,2*days,3*days, 7*days, 10*days, 15*days,20*days, 30*days];

    let optionid = 0;
    before(async () => {
        contracts = await migration(accounts);
        await AddCollateral0(contracts);
        await createAndAddErc20(contracts);
        await createAndAddUSDC(contracts);
    });

    it('FNX buy and exercise', async function () {

        await contracts.FNX.approve(contracts.manager.address,collAmount);
        await contracts.manager.addCollateral(contracts.FNX.address,collAmount);
        contracts.oracle.setFakeUnderlyingPrice(PRICETWO);
        let i =0 ;
        await contracts.FNX.approve(contracts.manager.address,payamount);
        let strikePrice = PRICETWO;
        let tx = await contracts.manager.buyOption(contracts.FNX.address,payamount,strikePrice,ETH_ID,expiration[0],optamount,OPTION_DOWN);
        assert.equal(tx.receipt.status,true);
        optionid++;

        contracts.oracle.setFakeUnderlyingPrice(PRICEONE);
        contracts.price.setOptionsPrice(PRICEONE + SHIFTVALUE);
        tx = await contracts.manager.exerciseOption(optionid,optamount);
        assert.equal(tx.receipt.status,true);

    })

    it('USDC buy and exercise', async function () {
        await contracts.USDC.approve(contracts.manager.address,collAmount);
        await contracts.manager.addCollateral(contracts.USDC.address,collAmount);

        contracts.oracle.setFakeUnderlyingPrice(PRICETWO);
        await contracts.USDC.approve(contracts.manager.address,payamount);
        let strikePrice = PRICETWO;
        let tx = await contracts.manager.buyOption(contracts.USDC.address,payamount,strikePrice,1,expiration[0],optamount,OPTION_DOWN);
        assert.equal(tx.receipt.status,true);
        optionid++;

        contracts.oracle.setFakeUnderlyingPrice(PRICEONE);
        contracts.price.setOptionsPrice(PRICEONE + SHIFTVALUE);
        tx = await contracts.manager.exerciseOption(optionid,optamount);
        assert.equal(tx.receipt.status,true);

    })


})