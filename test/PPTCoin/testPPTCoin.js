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
    it('PPTCoin test functions', async function (){
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
            
        let name = await pptCoin.name();
        assert.equal(name,"PPT_A","name Error");
        let symbol = await pptCoin.symbol();
        assert.equal(symbol,"PPT_A","symbol Error");
        let decimals = await pptCoin.decimals();
        assert.equal(decimals,18,"decimals Error");
        let totalSupply = await pptCoin.totalSupply();
        let total = "0";
        assert.equal(totalSupply.toString(10),total,"totalSupply Error");
        await factory.optionsFactory.testSetProxyManager(pptCoin.address,accounts[1]);
        let result = await pptCoin.getOperator(0);
        assert.equal(result,accounts[1],"setManager Error");
        let amount = new BN("10000000000000000000000");
        await pptCoin.mint(accounts[0],amount,{from:accounts[1]});
        totalSupply = await pptCoin.totalSupply();
        assert.equal(totalSupply.toString(10),"10000000000000000000000","totalSupply Error");
        await pptCoin.approve(accounts[2],10000000000,{from:accounts[0]});
        result = await pptCoin.allowance(accounts[0],accounts[2]);
        assert.equal(result,10000000000,"approve Error");
        await pptCoin.transferFrom(accounts[0],accounts[3],10000000000,{from:accounts[2]});
        result = await pptCoin.allowance(accounts[0],accounts[2]);
        assert.equal(result,0,"allowance Error");
        result = await pptCoin.balanceOf(accounts[0]);
        assert.equal(result.toString(10),"9999999999990000000000","accounts[0] Error");
        result = await pptCoin.balanceOf(accounts[3]);
        assert.equal(result.toString(10),"10000000000","accounts[3] Error");
        result = await pptCoin.balanceOf(accounts[2]);
        assert.equal(result.toString(10),"0","accounts[2] Error");
        await pptCoin.transfer(accounts[4],10000000000,{from:accounts[0]});
        result = await pptCoin.balanceOf(accounts[0]);
        assert.equal(result.toString(10),"9999999999980000000000","accounts[0] Error");
        result = await pptCoin.balanceOf(accounts[3]);
        assert.equal(result.toString(10),"10000000000","accounts[3] Error");
        result = await pptCoin.balanceOf(accounts[2]);
        assert.equal(result.toString(10),"0","accounts[2] Error");
        result = await pptCoin.balanceOf(accounts[4]);
        assert.equal(result.toString(10),"10000000000","accounts[2] Error");
    });
    it('PPTCoin set functions', async function (){
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

        let result = await pptCoin.getTimeLimitation(accounts[0]);
        assert.equal(result.toString(10),"3600","getTimeLimitation error");
        await createFactory.multiSignatureAndSend(factory.multiSignature,factory.optionsFactory,"setPPTTimeLimit",accounts[0],owners,7200);
        result = await pptCoin.getTimeLimitation(accounts[0]);
        assert.equal(result.toString(10),"7200","getTimeLimitation error");

        result = await pptCoin.getTotalLockedWorth();
        assert.equal(result.toString(10),"0","getTotalLockedWorth error");

        result = await pptCoin.lockedBalanceOf(accounts[1]);
        assert.equal(result.toString(10),"0","getTotalLockedWorth error");

        result = await pptCoin.lockedWorthOf(accounts[2]);
        assert.equal(result.toString(10),"0","getTotalLockedWorth error");

        result = await pptCoin.getLockedBalance(accounts[2]);
        assert(result[0].toString(10)=="0" && result[1].toString(10)=="0","getLockedBalance error");
    });
    it('PPTCoin calculate functions', async function (){
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
        await pptCoin.mint(accounts[0],10000000000,{from:accounts[0]});
        await pptCoin.mint(accounts[1],10000000000,{from:accounts[0]});
        await pptCoin.mint(accounts[2],10000000000,{from:accounts[0]});
        await createFactory.multiSignatureAndSend(factory.multiSignature,factory.optionsFactory,"setPPTTimeLimit",accounts[0],owners,0);
        for (var i=0;i<25;i++){
            await createFactory.multiSignatureAndSend(factory.multiSignature,factory.optionsFactory,"setPPTTimeLimit",accounts[0],owners,0);
        }
        await pptCoin.burn(accounts[0],5000000000,{from:accounts[0]});
        let result = await pptCoin.balanceOf(accounts[0]);
        assert.equal(result.toString(10),"5000000000","getTotalLockedWorth error");

        let totalSupply = await pptCoin.totalSupply();
        assert.equal(totalSupply.toString(10),"25000000000","totalSupply Error");

        for (var i=0;i<3;i++){
            await pptCoin.addlockBalance(accounts[i],(i+1)*100000000,(i+1)*1000000000000,{from:accounts[0]});
            result = await pptCoin.getLockedBalance(accounts[i]);
            assert(result[0].toNumber()==(i+1)*100000000 && result[1].toNumber()==(i+1)*1000000000000,
                "getLockedBalance balance error");
        }
        totalSupply = await pptCoin.totalSupply();
        assert.equal(totalSupply.toString(10),"24400000000","totalSupply Error");
        result = await pptCoin.getTotalLockedWorth();
        assert.equal(result.toString(10),"6000000000000","getTotalLockedWorth Error");
        await pptCoin.redeemLockedCollateral(accounts[0],50000000,500000000000,{from:accounts[0]});
        await pptCoin.redeemLockedCollateral(accounts[1],50000000,1000000000000,{from:accounts[0]});
        await pptCoin.redeemLockedCollateral(accounts[2],400000000,4000000000000,{from:accounts[0]});
        result = await pptCoin.getLockedBalance(accounts[0]);
        assert(result[0].toNumber()==50000000 && result[1].toNumber()==500000000000,
            "getLockedBalance balance error");
        result = await pptCoin.getLockedBalance(accounts[1]);
        assert(result[0].toNumber()==150000000 && result[1].toNumber()==1500000000000,
            "getLockedBalance balance error");
        result = await pptCoin.getLockedBalance(accounts[2]);
        assert(result[0].toNumber()==0 && result[1].toNumber()==0,
            "getLockedBalance balance error");
        totalSupply = await pptCoin.totalSupply();
        assert.equal(totalSupply.toString(10),"24400000000","totalSupply Error");
        result = await pptCoin.getTotalLockedWorth();
        assert.equal(result.toString(10),"2000000000000","getTotalLockedWorth Error");
    });
});