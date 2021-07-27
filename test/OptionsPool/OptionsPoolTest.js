let createFactory = require("../optionsFactory/optionsFactory.js");
//const minePoolProxy = artifacts.require("MinePoolProxy");
//const minePool = artifacts.require("FNXMinePool");
//const Erc20Proxy = artifacts.require("Erc20Proxy");
const PHXCoin = artifacts.require("PHXCoin");
const OptionsPool = artifacts.require("OptionsPool");
const acceleratedMinePool = artifacts.require("acceleratedMinePool");
const PHXVestingPool = artifacts.require("PHXVestingPool");
let collateral0 = "0x0000000000000000000000000000000000000000";
const BN = require("bn.js");
contract('OptionsPool', function (accounts){
    it('OptionsPool getting and setting test functions', async function (){
        let owners = [accounts[1],accounts[2],accounts[3],accounts[4],accounts[5]] 
        let factory = await createFactory.createTestFactory(accounts[0],owners)
        await factory.optionsFactory.testCreateOptionsPool([1,2]);
        let pool = await factory.optionsFactory.latestAddress();
        let options = await OptionsPool.at(pool);
        let underlying = await options.getUnderlyingAssets();
        console.log("underlying assets : ",underlying)
        await createFactory.multiSignatureAndSend(factory.multiSignature,options,"setUnderlyingAsset",accounts[0],owners,[1,2,3,4,5]); 
        underlying = await options.getUnderlyingAssets();
        console.log("underlying assets : ",underlying)
        await createFactory.multiSignatureAndSend(factory.multiSignature,options,"setUnderlyingAsset",accounts[0],owners,[1,2]); 
        underlying = await options.getUnderlyingAssets();
        console.log("underlying assets : ",underlying)
        let result = await options.limitation();
        assert.equal(result.toString(10),"3600","getBurnTimeLimit Error");
        result = await options.getUserOptionsID(accounts[0]);
        assert.equal(result.length,0,"getUserOptionsID Error");
        result = await options.getOptionInfoLength();
        assert.equal(result,0,"getOptionInfoLength Error");
        result = await options.getExpirationList();
        console.log(result);
        result = await options.getOccupiedCalInfo();
        assert.equal(result[0],0,"getOccupiedCalInfo Error");
        assert.equal(result[1].length,2,"getOccupiedCalInfo Error");
        assert.equal(result[2].length,2,"getOccupiedCalInfo Error");
        result = await options.getTotalOccupiedCollateral();
        assert.equal(result,0,"getOccupiedCalInfo Error");
        let whiteList = [collateral0];
        result = await options.getNetWrothCalInfo(whiteList);
        console.log(result);
        result = await options.optionsLatestNetWorth(collateral0);
        console.log(result);
        result = await options.getOptionCalRangeAll(whiteList);
        console.log(result);
        await createFactory.multiSignatureAndSend(factory.multiSignature,options,"addExpiration",accounts[0],owners,1500); 
        await createFactory.multiSignatureAndSend(factory.multiSignature,options,"removeExpirationList",accounts[0],owners,1500); 
        await createFactory.multiSignatureAndSend(factory.multiSignature,options,"setOperator",accounts[0],owners,1,accounts[0]);
        await options.setCollateralPhase([10000,10000],[10000,10000],0,[10000,10000],[10000,10000],{from : accounts[0]});
        await options.setSharedState(0,[10000],whiteList);
    });
    return;
    it('OptionsPool create Options test functions', async function (){
        let owners = [accounts[1],accounts[2],accounts[3],accounts[4],accounts[5]] 
        let factory = await createFactory.createTestFactory(accounts[0],owners)
        await factory.optionsFactory.testCreateOptionsPool([1,2]);
        let pool = await factory.optionsFactory.latestAddress();
        let options = await OptionsPool.at(pool);
        await factory.optionsFactory.testSetProxyManager(options.address,accounts[0]);
        await createFactory.multiSignatureAndSend(factory.multiSignature,options,"addExpiration",accounts[0],owners,86400);
        let bn = new BN("10000000000000001",16);
        let bn1 = new BN(86400);
        bn = bn.add(bn1.shln(128));
        await options.createOptions(accounts[0],collateral0,bn,92500000000,925000000000,10000000000,50e8);
        let result = await options.getOptionsById(1);
        console.log(result);
        result = await options.getOptionsExtraById(1);
        console.log(result);
        result = await options.getUserOptionsID(accounts[0]);
        console.log(result);
        result = await options.getOptionInfoLength();
        console.log(result);
        await createFactory.multiSignatureAndSend(factory.multiSignature,options,"setOperator",accounts[0],owners,1,accounts[0]);
        let whiteList = [collateral0];
        await options.setCollateralPhase([10000,10000],[10000,10000],0,[10000,10000],[10000,10000],{from : accounts[0]});
        await options.setSharedState(0,[10000],whiteList);
    });
});