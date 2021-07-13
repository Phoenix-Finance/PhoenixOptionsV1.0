
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
    it('USDC options buy', async function () {
        let collAmount = new BN("1000000000000000000000000",10);
        await factory.oracle.setPrice(contracts.USDC.address,new BN("100000000000000000000"),{from:accounts[1]});
        await factory.oracle.setUnderlyingPrice(1,13268e8,{from:accounts[1]});
        await contracts.USDC.approve(contracts.manager.address,0x174876e800);
        await contracts.manager.addCollateral(contracts.USDC.address,0x174876e800);
        await contracts.USDC.approve(contracts.manager.address,10000000000);
        await contracts.manager.buyOption(contracts.USDC.address,10000000000,13200e8,1,86400,1000,0);
     })
    it('FNX buy and exercise', async function () {
        await factory.oracle.setUnderlyingPrice(1,900000000100,{from:accounts[1]});
        let collAmount = new BN("1000000000000000000000000",10);
        await contracts.phx.approve(contracts.manager.address,collAmount);
        await contracts.manager.addCollateral(contracts.phx.address,collAmount);
        let days = 24*60*60;
        let expiration = [days,2*days,3*days, 7*days, 10*days, 15*days,20*days, 30*days];
        let index = await contracts.options.getOptionInfoLength();
        index = index.toNumber()+1;        
        for (var i=0;i<20;i++){
            await contracts.phx.approve(contracts.manager.address,2000000000000000);
            let strikePrice = 50*i + 900000000000;
            let tx = await contracts.manager.buyOption(contracts.phx.address,1000000000000000,strikePrice,1,expiration[i%expiration.length],100000000000,1);
            assert.equal(tx.receipt.status,true);
        }
        let underlyingPrice = await factory.oracle.getUnderlyingPrice(1);
        for (var i=0;i<20;i++){
            let strikePrice = 50*i + 900000000000;
            if (strikePrice>underlyingPrice){
                console.log("option excercise");
                let tx = await contracts.manager.exerciseOption(i+index,100000000000);
                assert.equal(tx.receipt.status,true);
            }
        }
    })
    it('USDC input and redeem', async function () {
        let collAmount = new BN("1000000000000000000000000",10);
        await contracts.USDC.approve(contracts.manager.address,collAmount);
        await contracts.manager.addCollateral(contracts.USDC.address,collAmount);
        let days = 24*60*60;
        let expiration = [days,2*days,3*days, 7*days, 10*days, 15*days,20*days, 30*days];
        let index = await contracts.options.getOptionInfoLength();
        index = index.toNumber()+1;
        for (var i=0;i<20;i++){
            let tx = await contracts.USDC.approve(contracts.manager.address,2000000000000000);
            assert.equal(tx.receipt.status,true);
            let strikePrice = 50*i + 900000000000;
            await contracts.manager.buyOption(contracts.USDC.address,1000000000000000,strikePrice,1,expiration[i%expiration.length],100000000000,1);
        }
        let underlyingPrice = await factory.oracle.getUnderlyingPrice(1);
        for (var i=0;i<20;i++){
            let strikePrice = 50*i + 900000000000;
            if (strikePrice>underlyingPrice){
                console.log("option excercise");
                let tx = await contracts.manager.exerciseOption(i+index,100000000000);
                assert.equal(tx.receipt.status,true);
            }
        }
     })

    it('ETH input and redeem', async function () {
        let collAmount = new BN("1000000000000000000000000",10);
        let tx = await contracts.manager.addCollateral(collateral0,collAmount,{from:accounts[0],value:collAmount});
        let days = 24*60*60;
        let expiration = [days,2*days,3*days, 7*days, 10*days, 15*days,20*days, 30*days];
        let index = await contracts.options.getOptionInfoLength();
        index = index.toNumber()+1;
        for (var i=0;i<20;i++){
            let strikePrice = 50*i + 900000000000;
            tx = await contracts.manager.buyOption(collateral0,1000000000000000,strikePrice,1,expiration[i%expiration.length],100000000000,1,
                {value:1000000000000000});
            assert.equal(tx.receipt.status,true);
        }
        let underlyingPrice = await factory.oracle.getUnderlyingPrice(1);
        for (var i=0;i<20;i++){
            let strikePrice = 50*i + 900000000000;
            if (strikePrice>underlyingPrice){
                console.log("option excercise");
                let tx = await contracts.manager.exerciseOption(i+index,100000000000);
                assert.equal(tx.receipt.status,true);
            }
        }
    })
})