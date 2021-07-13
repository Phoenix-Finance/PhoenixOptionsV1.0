let createFactory = require("../optionsFactory/optionsFactory.js");
//const minePoolProxy = artifacts.require("MinePoolProxy");
//const minePool = artifacts.require("FNXMinePool");
//const Erc20Proxy = artifacts.require("Erc20Proxy");
const PHXCoin = artifacts.require("PHXCoin");
const PPTCoin = artifacts.require("PPTCoin");
const acceleratedMinePool = artifacts.require("acceleratedMinePool");
let collateral0 = "0x0000000000000000000000000000000000000000";
const BN = require("bn.js");
contract('PPTCoin', function (accounts){
    it('PPTCoin recipient white list tests', async function (){
        let owners = [accounts[1],accounts[2],accounts[3],accounts[4],accounts[5]] 
        let factory = await createFactory.createTestFactory(accounts[0],owners)
        await factory.optionsFactory.testCreatePPTCoin();
        let pptAddress = await factory.optionsFactory.latestAddress();
        let pptCoin = await PPTCoin.at(pptAddress);
        let phx = await PHXCoin.new();
        let poolAddr = await pptCoin.minePool();
        let minePool = await acceleratedMinePool.at(poolAddr);
        await createFactory.multiSignatureAndSend(factory.multiSignature,minePool,"setMineCoinInfo",accounts[0],owners,
            collateral0,1000000,2);
        await createFactory.multiSignatureAndSend(factory.multiSignature,minePool,"setMineCoinInfo",accounts[0],owners,
            phx.address,2000000,2);
        await factory.optionsFactory.testSetProxyManager(pptCoin.address,accounts[0]);
        await pptCoin.mint(accounts[0],20000000000);
        await pptCoin.mint(accounts[1],20000000000);
        await pptCoin.mint(accounts[2],20000000000);
        await createFactory.multiSignatureAndSend(factory.multiSignature,factory.optionsFactory,"setPPTTimeLimit",accounts[0],owners,3600);
        let time1 = await pptCoin.getTimeLimitation(accounts[0]);
        let time2 = await pptCoin.getTimeLimitation(accounts[1]);
        let time3 = await pptCoin.getTimeLimitation(accounts[2]);
        console.log(time1.toString(),time2.toString(),time3.toString())
        assert(time1.toString()!=0 && time2.toString()!= 0 && time3.toString()!= 0,"getTimeLimitation error");
        for (var i=0;i<10;i++){
            await createFactory.multiSignatureAndSend(factory.multiSignature,factory.optionsFactory,"setPPTTimeLimit",accounts[0],owners,3600);
        }
        await pptCoin.transfer(accounts[3],5000000000,{from:accounts[0]});
        await pptCoin.transfer(accounts[3],5000000000,{from:accounts[1]});
        await pptCoin.transfer(accounts[3],5000000000,{from:accounts[2]});
        let time11 = await pptCoin.getTimeLimitation(accounts[0]);
        let time12 = await pptCoin.getTimeLimitation(accounts[1]);
        let time13 = await pptCoin.getTimeLimitation(accounts[2]);
        assert.equal(time1.toString(),time11.toString(),"timeLimitWhiteList error");
        assert.equal(time2.toString(),time12.toString(),"timeLimitWhiteList error");
        assert.equal(time3.toString(),time13.toString(),"timeLimitWhiteList error");
        for (var i=0;i<10;i++){
            await createFactory.multiSignatureAndSend(factory.multiSignature,factory.optionsFactory,"setPPTTimeLimit",accounts[0],owners,3600);
        }
        await pptCoin.transfer(accounts[0],5000000000,{from:accounts[3]});
        await pptCoin.transfer(accounts[1],5000000000,{from:accounts[3]});
        await pptCoin.transfer(accounts[2],5000000000,{from:accounts[3]});
        let time21 = await pptCoin.getTimeLimitation(accounts[0]);
        let time22 = await pptCoin.getTimeLimitation(accounts[1]);
        let time23 = await pptCoin.getTimeLimitation(accounts[2]);
        assert(time1.toNumber()<time21.toNumber(),"timeLimitWhiteList error");
        assert(time2.toNumber()<time22.toNumber(),"timeLimitWhiteList error");
        assert(time3.toNumber()<time23.toNumber(),"timeLimitWhiteList error");
    });
});