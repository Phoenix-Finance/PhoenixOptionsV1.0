
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
        await contracts.FNX.approve(contracts.manager.address,collAmount);
        await contracts.manager.addCollateral(contracts.FNX.address,collAmount);
    });

    it('1000 FNX buy and exercise down option for ETH', async function () {

        contracts.oracle.setFakeUnderlyingPrice(PRICETWO);
        let i =0 ;
        await contracts.FNX.approve(contracts.manager.address,payamount);
        let strikePrice = PRICETWO;

        let preBalanceUser0 =await  contracts.FNX.balanceOf(accounts[0]);
        let preBalanceContract =await  contracts.FNX.balanceOf(contracts.collateral.address);

        let tx = await contracts.manager.buyOption(contracts.FNX.address,payamount,strikePrice,ETH_ID,expiration[0],optamount,OPTION_DOWN);
        assert.equal(tx.receipt.status,true);
        optionid++;

        let afterBalanceUser0 =await  contracts.FNX.balanceOf(accounts[0]);
        let afterBalanceContract =await  contracts.FNX.balanceOf(contracts.collateral.address);
        let diffUser = preBalanceUser0.sub(afterBalanceUser0);
        let diffContract = afterBalanceContract.sub(preBalanceContract);
        assert.equal(diffUser.toNumber()>0,true,"user usdc balance error");
        assert.equal(diffContract.toNumber()>0,true,"manager usdc balance error");


        preBalanceUser0 =await  contracts.FNX.balanceOf(accounts[0]);
        preBalanceContract =await  contracts.FNX.balanceOf(contracts.collateral.address);

        contracts.oracle.setFakeUnderlyingPrice(PRICEONE);
        contracts.price.setOptionsPrice(PRICEONE + SHIFTVALUE);
        tx = await contracts.manager.exerciseOption(optionid,optamount);
        assert.equal(tx.receipt.status,true);

        afterBalanceUser0 =await  contracts.FNX.balanceOf(accounts[0]);
        afterBalanceContract =await  contracts.FNX.balanceOf(contracts.collateral.address);
        diffUser = afterBalanceUser0.sub(preBalanceUser0);
        diffContract = preBalanceContract.sub(afterBalanceContract);
        assert.equal(diffUser.toNumber()>0,true,"user redeem usdc balance error");
        assert.equal(diffContract.toNumber()>0,true,"manager redeem usdc balance error");

    })

    it('1010 USDC buy and exercise down option for ETH', async function () {

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

    it('1020 FNX buy and exercise up option for ETH', async function () {

        contracts.oracle.setFakeUnderlyingPrice(PRICETWO);
        let i =0 ;
        await contracts.FNX.approve(contracts.manager.address,payamount);
        let strikePrice = PRICETWO;
        let tx = await contracts.manager.buyOption(contracts.FNX.address,payamount,strikePrice,ETH_ID,expiration[0],optamount,OPTION_UP);
        assert.equal(tx.receipt.status,true);
        optionid++;

        contracts.oracle.setFakeUnderlyingPrice(PRICETWO + SHIFTVALUE);
        contracts.price.setOptionsPrice(PRICETHREE);
        tx = await contracts.manager.exerciseOption(optionid,optamount);
        assert.equal(tx.receipt.status,true);

    })

    it('1030 USDC buy and exercise for ETH', async function () {
        contracts.oracle.setFakeUnderlyingPrice(PRICETWO);
        await contracts.USDC.approve(contracts.manager.address,payamount);
        let strikePrice = PRICETWO;
        let tx = await contracts.manager.buyOption(contracts.USDC.address,payamount,strikePrice,ETH_ID,expiration[0],optamount,OPTION_UP);
        assert.equal(tx.receipt.status,true);
        optionid++;

        contracts.oracle.setFakeUnderlyingPrice(PRICETWO + SHIFTVALUE);
        contracts.price.setOptionsPrice(PRICETHREE);
        tx = await contracts.manager.exerciseOption(optionid,optamount);
        assert.equal(tx.receipt.status,true);
    })

    it('1040 FNX buy and exercise down option for BTC', async function () {

        contracts.oracle.setFakeUnderlyingPrice(PRICETWO);
        let i =0 ;
        await contracts.FNX.approve(contracts.manager.address,payamount);
        let strikePrice = PRICETWO;
        let tx = await contracts.manager.buyOption(contracts.FNX.address,payamount,strikePrice,BTC_ID,expiration[0],optamount,OPTION_DOWN);
        assert.equal(tx.receipt.status,true);
        optionid++;

        contracts.oracle.setFakeUnderlyingPrice(PRICEONE);
        contracts.price.setOptionsPrice(PRICEONE + SHIFTVALUE);
        tx = await contracts.manager.exerciseOption(optionid,optamount);
        assert.equal(tx.receipt.status,true);

    })

    it('1050 USDC buy and exercise down option for BTC', async function () {

        contracts.oracle.setFakeUnderlyingPrice(PRICETWO);
        await contracts.USDC.approve(contracts.manager.address,payamount);
        let strikePrice = PRICETWO;
        let tx = await contracts.manager.buyOption(contracts.USDC.address,payamount,strikePrice,BTC_ID,expiration[0],optamount,OPTION_DOWN);
        assert.equal(tx.receipt.status,true);
        optionid++;

        contracts.oracle.setFakeUnderlyingPrice(PRICEONE);
        contracts.price.setOptionsPrice(PRICEONE + SHIFTVALUE);
        tx = await contracts.manager.exerciseOption(optionid,optamount);
        assert.equal(tx.receipt.status,true);

    })

    it('1060 FNX buy and exercise up option for BTC', async function () {

        contracts.oracle.setFakeUnderlyingPrice(PRICETWO);
        let i =0 ;
        await contracts.FNX.approve(contracts.manager.address,payamount);
        let strikePrice = PRICETWO;
        let tx = await contracts.manager.buyOption(contracts.FNX.address,payamount,strikePrice,BTC_ID,expiration[0],optamount,OPTION_UP);
        assert.equal(tx.receipt.status,true);
        optionid++;

        contracts.oracle.setFakeUnderlyingPrice(PRICETWO + SHIFTVALUE);
        contracts.price.setOptionsPrice(PRICETHREE);
        tx = await contracts.manager.exerciseOption(optionid,optamount);
        assert.equal(tx.receipt.status,true);

    })

    it('1070 USDC buy and exercise for BTC', async function () {
        contracts.oracle.setFakeUnderlyingPrice(PRICETWO);
        await contracts.USDC.approve(contracts.manager.address,payamount);
        let strikePrice = PRICETWO;
        let tx = await contracts.manager.buyOption(contracts.USDC.address,payamount,strikePrice,BTC_ID,expiration[0],optamount,OPTION_UP);
        assert.equal(tx.receipt.status,true);
        optionid++;

        contracts.oracle.setFakeUnderlyingPrice(PRICETWO + SHIFTVALUE);
        contracts.price.setOptionsPrice(PRICETHREE);
        tx = await contracts.manager.exerciseOption(optionid,optamount);
        assert.equal(tx.receipt.status,true);
    })

})