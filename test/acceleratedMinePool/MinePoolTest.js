let createFactory = require("../optionsFactory/optionsFactory.js");
//const minePoolProxy = artifacts.require("MinePoolProxy");
//const minePool = artifacts.require("FNXMinePool");
//const Erc20Proxy = artifacts.require("Erc20Proxy");
const PHXCoin = artifacts.require("PHXCoin");
const PPTCoin = artifacts.require("PPTCoin");
const acceleratedMinePool = artifacts.require("acceleratedMinePool");
let collateral0 = "0x0000000000000000000000000000000000000000";
const BN = require("bn.js");
contract('FNXMinePool', function (accounts){
    it('FNXMinePool buying mine functions', async function (){
        let owners = [accounts[1],accounts[2],accounts[3],accounts[4],accounts[5]] 
        let factory = await createFactory.createTestFactory(accounts[0],owners)
        await factory.optionsFactory.testCreatePPTCoin();
        let pptAddress = await factory.optionsFactory.latestAddress();
        let pptCoin = await PPTCoin.at(pptAddress);
        let phx = await PHXCoin.new();
        let poolAddr = await pptCoin.minePool();
        let minePool = await acceleratedMinePool.at(poolAddr);

        let amount = new BN("10000000000000000000000");
        await phx.transfer(minePool.address,amount);
        await minePool.send(amount);
        let result = await phx.balanceOf(minePool.address);
        assert.equal(result.toString(10),"10000000000000000000000","erc20 balance error");
        result = await web3.eth.getBalance(minePool.address);
        assert.equal(result.toString(10),"10000000000000000000000","ether balance error");
        await createFactory.multiSignatureAndSend(factory.multiSignature,minePool,"setMineCoinInfo",accounts[0],owners,
            collateral0,10000000000,3000);
        await createFactory.multiSignatureAndSend(factory.multiSignature,minePool,"setMineCoinInfo",accounts[0],owners,
            phx.address,11000000000,3100);
        result = await minePool.getMineInfo(collateral0);
        assert.equal(result[0].toString(10),"10000000000","setMineCoinInfo error");
        assert.equal(result[1].toString(10),"3000","setMineCoinInfo error");
        result = await minePool.getMineInfo(phx.address);
        assert.equal(result[0].toString(10),"11000000000","setMineCoinInfo error");
        assert.equal(result[1].toString(10),"3100","setMineCoinInfo error");
    });
    it('FNXMinePool set functions', async function (){
        let owners = [accounts[1],accounts[2],accounts[3],accounts[4],accounts[5]] 
        let factory = await createFactory.createTestFactory(accounts[0],owners)
        await factory.optionsFactory.testCreatePPTCoin();
        let pptAddress = await factory.optionsFactory.latestAddress();
        let pptCoin = await PPTCoin.at(pptAddress);
        let phx = await PHXCoin.new();
        let poolAddr = await pptCoin.minePool();
        let minePool = await acceleratedMinePool.at(poolAddr);

        let amount = new BN("10000000000000000000000");
        await phx.transfer(minePool.address,amount);
        await minePool.send(amount);
        let result = await phx.balanceOf(minePool.address);
        assert.equal(result.toString(10),"10000000000000000000000","erc20 balance error");
        result = await web3.eth.getBalance(minePool.address);
        assert.equal(result.toString(10),"10000000000000000000000","ether balance error");
        await createFactory.multiSignatureAndSend(factory.multiSignature,minePool,"setMineCoinInfo",accounts[0],owners,
            collateral0,10000000000,3000);
        await createFactory.multiSignatureAndSend(factory.multiSignature,minePool,"setMineCoinInfo",accounts[0],owners,
            phx.address,11000000000,3100);
        result = await minePool.getMineInfo(collateral0);
        assert.equal(result[0].toString(10),"10000000000","setMineCoinInfo error");
        assert.equal(result[1].toString(10),"3000","setMineCoinInfo error");
        result = await minePool.getMineInfo(phx.address);
        assert.equal(result[0].toString(10),"11000000000","setMineCoinInfo error");
        assert.equal(result[1].toString(10),"3100","setMineCoinInfo error");

        result1 = await minePool.getTotalMined(collateral0);
        assert.equal(result1.toString(10),"0","getTotalMined error");
        result1 = await minePool.getTotalMined(phx.address);
        assert.equal(result1.toString(10),"0","getTotalMined error");
        result1 = await minePool.getMinerBalance(accounts[1],collateral0);
        assert.equal(result1.toString(10),"0","getMinerBalance error");
        result1 = await minePool.getMinerBalance(accounts[1],phx.address);
        assert.equal(result1.toString(10),"0","getMinerBalance error");

    });
    it('FNXMinePool calculate functions', async function (){
        let owners = [accounts[1],accounts[2],accounts[3],accounts[4],accounts[5]] 
        let factory = await createFactory.createTestFactory(accounts[0],owners)
        await factory.optionsFactory.testCreatePPTCoin();
        let pptAddress = await factory.optionsFactory.latestAddress();
        let pptCoin = await PPTCoin.at(pptAddress);
        let phx = await PHXCoin.new();
        let poolAddr = await pptCoin.minePool();
        let minePool = await acceleratedMinePool.at(poolAddr);

        await factory.optionsFactory.testSetProxyManager(pptCoin.address,accounts[0]);
        let amount = new BN("10000000000000000000000");
        await phx.transfer(minePool.address,amount);
        await minePool.send(amount);
        await createFactory.multiSignatureAndSend(factory.multiSignature,minePool,"setMineCoinInfo",accounts[0],owners,
            collateral0,1000000,2);
        await createFactory.multiSignatureAndSend(factory.multiSignature,minePool,"setMineCoinInfo",accounts[0],owners,
            phx.address,2000000,2);
        pptCoin.mint(accounts[0],10000000000);
        pptCoin.mint(accounts[1],10000000000);
        pptCoin.mint(accounts[2],10000000000);
        var begin = new Date().getTime();
        for (var i=0;i<100;i++){
            await factory.optionsFactory.testSetProxyManager(pptCoin.address,accounts[0]);
        }
        var end = new Date().getTime();
        var mineTime = (end - begin)/1000;
        var mine0 = Math.floor(1000000*mineTime/6);
        var mine1 = Math.floor(2000000*mineTime/6);
        console.log(mine0,mine1);
        let result1 = await minePool.getMinerBalance(accounts[0],collateral0);
        assert(Math.abs(mine0-result1.toNumber())/mine0<0.5,"getMinerBalance error");
        result1 = await minePool.getMinerBalance(accounts[0],phx.address);
        assert(Math.abs(mine1-result1.toNumber())/mine1<0.5,"getMinerBalance error");
        result1 = await minePool.getMinerBalance(accounts[1],collateral0);
        assert(Math.abs(mine0-result1.toNumber())/mine0<0.5,"getMinerBalance error");
        result1 = await minePool.getMinerBalance(accounts[1],phx.address);
        assert(Math.abs(mine1-result1.toNumber())/mine1<0.5,"getMinerBalance error");
        result1 = await minePool.getMinerBalance(accounts[2],collateral0);
        assert(Math.abs(mine0-result1.toNumber())/mine0<0.5,"getMinerBalance error");
        result1 = await minePool.getMinerBalance(accounts[2],phx.address);
        assert(Math.abs(mine1-result1.toNumber())/mine1<0.5,"getMinerBalance error");
        result1 = await minePool.getTotalMined(collateral0);
        assert(Math.abs(mine0*3-result1.toNumber())/(mine0*3)<0.5,"getMinerBalance error");
        result1 = await minePool.getTotalMined(phx.address);
        assert(Math.abs(mine1*3-result1.toNumber())/(mine1*3)<0.5,"getMinerBalance error");

        for (var i=0;i<3;i++){
            let result = await web3.eth.getBalance(minePool.address);
            await minePool.redeemMinerCoin(collateral0,500000,{from : accounts[i]});
            result1 = await web3.eth.getBalance(minePool.address);
            result = (new BN(result)).sub(new BN(result1));
            assert.equal(result,500000,"redeemMinerCoin error");
    
            result = await phx.balanceOf(minePool.address);
            await minePool.redeemMinerCoin(phx.address,1000000,{from : accounts[i]});
            result1 = await phx.balanceOf(minePool.address);
            result = (new BN(result)).sub(new BN(result1));
            assert.equal(result,1000000,"redeemMinerCoin error");
        }

        let result = await web3.eth.getBalance(minePool.address);
        await createFactory.multiSignatureAndSend(factory.multiSignature,minePool,"redeemOut",accounts[0],owners,
            collateral0,5000000000);
        result1 = await web3.eth.getBalance(minePool.address);
        result = (new BN(result)).sub(new BN(result1));
        assert.equal(result,5000000000,"redeemMinerCoin error");

        result = await phx.balanceOf(minePool.address);
        await createFactory.multiSignatureAndSend(factory.multiSignature,minePool,"redeemOut",accounts[0],owners,
            phx.address,10000000000);
        result1 = await phx.balanceOf(minePool.address);
        result = (new BN(result)).sub(new BN(result1));
        assert.equal(result,10000000000,"redeemMinerCoin error");
    });
});