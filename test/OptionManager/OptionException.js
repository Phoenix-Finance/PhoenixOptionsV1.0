let createFactory = require("../optionsFactory/optionsFactory.js");
//const minePoolProxy = artifacts.require("MinePoolProxy");
//const minePool = artifacts.require("FNXMinePool");
//const Erc20Proxy = artifacts.require("Erc20Proxy");
const PHXCoin = artifacts.require("PHXCoin");
const USDCoin = artifacts.require("USDCoin");
const OptionsPool = artifacts.require("OptionsPool");
const CollateralPool = artifacts.require("CollateralPool");
const PHXVestingPool = artifacts.require("PHXVestingPool");
let collateral0 = "0x0000000000000000000000000000000000000000";
const BN = require("bn.js");
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
    let factory;
    let ethAmount = new BN("10000000000000000000");
    let usdcAmount = 10000000000;

    let payamount = new BN("100000000000000000000");
    let optamount = new BN("2000000000000000000");

    let FNXAmount =  new BN("100000000000000000000");
    let owners = [accounts[1],accounts[2],accounts[3],accounts[4],accounts[5]];
    before(async () => {
        factory = await createFactory.createFactory(accounts[0],owners)
        let phx = await PHXCoin.new();
        let usdc = await USDCoin.new();
        contracts = await createFactory.createOptionsManager(factory,accounts[0],owners,
            [collateral0,usdc.address,phx.address],[1500,1200,5000],[1,2]);
        contracts.USDC = usdc;
        contracts.phx =phx;
        await factory.oracle.setOperator(3,accounts[1]);
        let price = new BN("10000000000000000000");
        await factory.oracle.setPrice(usdc.address,price,{from:accounts[1]});
        await factory.oracle.setPrice(phx.address,1e7,{from:accounts[1]});
        await factory.oracle.setPrice(collateral0,2e11,{from:accounts[1]});
        await createFactory.multiSignatureAndSend(factory.multiSignature,contracts.options,"setTimeLimitation",
            accounts[0],owners,0);
    });
    it('2000 phx buy and exercise up option for ETH with over option amount', async function () {

        factory.oracle.setFakeUnderlyingPrice(PRICETWO);
        let i =0 ;
        await contracts.phx.approve(contracts.manager.address,payamount);
        let strikePrice = PRICETWO;
        let tx = await contracts.manager.buyOption(contracts.phx.address,payamount,strikePrice,ETH_ID,expiration[0],optamount,OPTION_UP);
        assert.equal(tx.receipt.status,true);
        optionid++;

        factory.oracle.setFakeUnderlyingPrice(PRICETWO + SHIFTVALUE);
        contracts.price.setOptionsPrice(PRICETHREE);
        let isExcept = false;
        try {
            tx = await contracts.manager.exerciseOption(optionid, optamount.addn(1));
            assert.equal(tx.receipt.status, false);
        } catch (e) {
            console.log(e.toString());
            isExcept = true;
        }

        assert(isExcept,true,"should happend exception");

    })

    it('2010 USDC buy and exercise down option for ETH', async function () {

        factory.oracle.setFakeUnderlyingPrice(PRICETWO);
        await contracts.USDC.approve(contracts.manager.address,payamount);
        let strikePrice = PRICETWO;
        let tx = await contracts.manager.buyOption(contracts.USDC.address,payamount,strikePrice,1,expiration[0],optamount,OPTION_DOWN);
        assert.equal(tx.receipt.status,true);
        optionid++;

        factory.oracle.setFakeUnderlyingPrice(PRICEONE);
        contracts.price.setOptionsPrice(PRICEONE + SHIFTVALUE);

        let isExcept = false;
        try {
            tx = await contracts.manager.exerciseOption(optionid, optamount.addn(1));
            assert.equal(tx.receipt.status, true);
        }
        catch (e){
                console.log(e.toString());
                isExcept = true;
        }
        assert(isExcept,true,"should happend exception");
    })

    it('2020 phx buy and exercise up option for ETH', async function () {

        factory.oracle.setFakeUnderlyingPrice(PRICETWO);
        let i =0 ;
        await contracts.phx.approve(contracts.manager.address,payamount);
        let strikePrice = PRICETWO;
        let tx = await contracts.manager.buyOption(contracts.phx.address,payamount,strikePrice,ETH_ID,expiration[0],optamount,OPTION_UP);
        assert.equal(tx.receipt.status,true);
        optionid++;

        factory.oracle.setFakeUnderlyingPrice(PRICETWO + SHIFTVALUE);
        contracts.price.setOptionsPrice(PRICETHREE);

        let isExcept = false;
        try {
            tx = await contracts.manager.exerciseOption(optionid, optamount.addn(1));
            assert.equal(tx.receipt.status, true);
        }
        catch (e){
            console.log(e.toString());
            isExcept = true;
        }
        assert(isExcept,true,"should happend exception");

    })

    it('2030 USDC buy and exercise for ETH', async function () {
        factory.oracle.setFakeUnderlyingPrice(PRICETWO);
        await contracts.USDC.approve(contracts.manager.address,payamount);
        let strikePrice = PRICETWO;
        let tx = await contracts.manager.buyOption(contracts.USDC.address,payamount,strikePrice,ETH_ID,expiration[0],optamount,OPTION_UP);
        assert.equal(tx.receipt.status,true);
        optionid++;

        factory.oracle.setFakeUnderlyingPrice(PRICETWO + SHIFTVALUE);
        contracts.price.setOptionsPrice(PRICETHREE);

        let isExcept = false;
        try {
            tx = await contracts.manager.exerciseOption(optionid, optamount.addn(1));
            assert.equal(tx.receipt.status, true);
        }
        catch (e){
            console.log(e.toString());
            isExcept = true;
        }
        assert(isExcept,true,"should happend exception");
    })

    it('2040 phx buy and exercise down option for BTC', async function () {

        factory.oracle.setFakeUnderlyingPrice(PRICETWO);
        let i =0 ;
        await contracts.phx.approve(contracts.manager.address,payamount);
        let strikePrice = PRICETWO;
        let tx = await contracts.manager.buyOption(contracts.phx.address,payamount,strikePrice,BTC_ID,expiration[0],optamount,OPTION_DOWN);
        assert.equal(tx.receipt.status,true);
        optionid++;

        factory.oracle.setFakeUnderlyingPrice(PRICEONE);
        contracts.price.setOptionsPrice(PRICEONE + SHIFTVALUE);
        let isExcept = false;
        try {
            tx = await contracts.manager.exerciseOption(optionid, optamount.addn(1));
            assert.equal(tx.receipt.status, true);
        }
        catch (e){
            console.log(e.toString());
            isExcept = true;
        }
        assert(isExcept,true,"should happend exception");

    })

    it('2050 USDC buy and exercise down option for BTC', async function () {

        factory.oracle.setFakeUnderlyingPrice(PRICETWO);
        await contracts.USDC.approve(contracts.manager.address,payamount);
        let strikePrice = PRICETWO;
        let tx = await contracts.manager.buyOption(contracts.USDC.address,payamount,strikePrice,BTC_ID,expiration[0],optamount,OPTION_DOWN);
        assert.equal(tx.receipt.status,true);
        optionid++;

        factory.oracle.setFakeUnderlyingPrice(PRICEONE);
        contracts.price.setOptionsPrice(PRICEONE + SHIFTVALUE);
        let isExcept = false;
        try {
            tx = await contracts.manager.exerciseOption(optionid, optamount.addn(1));
            assert.equal(tx.receipt.status, true);
        }
        catch (e){
            console.log(e.toString());
            isExcept = true;
        }
        assert(isExcept,true,"should happend exception");

    })

    it('2060 phx buy and exercise up option for BTC', async function () {
        factory.oracle.setFakeUnderlyingPrice(PRICETWO);
        await contracts.phx.approve(contracts.manager.address,payamount);
        let strikePrice = PRICETWO;
        let tx = await contracts.manager.buyOption(contracts.phx.address,payamount,strikePrice,BTC_ID,expiration[0],optamount,OPTION_UP);
        assert.equal(tx.receipt.status,true);
        optionid++;

        factory.oracle.setFakeUnderlyingPrice(PRICETWO + SHIFTVALUE);
        contracts.price.setOptionsPrice(PRICETHREE);
        let isExcept = false;
        try {
            tx = await contracts.manager.exerciseOption(optionid, optamount.addn(1));
            assert.equal(tx.receipt.status, true);
        }
        catch (e){
            console.log(e.toString());
            isExcept = true;
        }
        assert(isExcept,true,"should happend exception");

    })

    it('2070 USDC buy and exercise for BTC', async function () {
        factory.oracle.setFakeUnderlyingPrice(PRICETWO);
        await contracts.USDC.approve(contracts.manager.address,payamount);
        let strikePrice = PRICETWO;
        let tx = await contracts.manager.buyOption(contracts.USDC.address,payamount,strikePrice,BTC_ID,expiration[0],optamount,OPTION_UP);
        assert.equal(tx.receipt.status,true);
        optionid++;

        factory.oracle.setFakeUnderlyingPrice(PRICETWO + SHIFTVALUE);
        contracts.price.setOptionsPrice(PRICETHREE);

        let isExcept = false;
        try {
            tx = await contracts.manager.exerciseOption(optionid, optamount.addn(1));
            assert.equal(tx.receipt.status, true);
        }
        catch (e){
            console.log(e.toString());
            isExcept = true;
        }
        assert(isExcept,true,"should happend exception");
    })

})