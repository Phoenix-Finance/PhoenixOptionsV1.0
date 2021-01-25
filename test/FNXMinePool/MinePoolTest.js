const minePoolProxy = artifacts.require("MinePoolProxy");
const minePool = artifacts.require("FNXMinePool");
const Erc20Proxy = artifacts.require("Erc20Proxy");
const FNXCoin = artifacts.require("FNXCoin");
let collateral0 = "0x0000000000000000000000000000000000000000";
const FPTProxy = artifacts.require("FPTProxy");
const FPTCoin = artifacts.require("FPTCoin");
const BN = require("bn.js");
contract('FNXMinePool', function (accounts){

    it('FNXMinePool buying mine functions', async function (){
        let fnx = await FNXCoin.new();
        let erc20 = await Erc20Proxy.new(fnx.address);
        let pool = await minePool.new();
        let poolProxy = await minePoolProxy.new(pool.address);
        let fptimpl = await FPTCoin.new(poolProxy.address,"FPT-A");
        let fpt = await FPTProxy.new(fptimpl.address,poolProxy.address,"FPT-A");
        await poolProxy.setManager(fpt.address);
        let amount = new BN("10000000000000000000000");
        await erc20.transfer(poolProxy.address,amount);
        await poolProxy.send(amount);
        let result = await erc20.balanceOf(poolProxy.address);
        assert.equal(result.toString(10),"10000000000000000000000","erc20 balance error");
        result = await web3.eth.getBalance(poolProxy.address);
        assert.equal(result.toString(10),"10000000000000000000000","ether balance error");
        await poolProxy.setMineCoinInfo(collateral0,10000000000,3000);
        await poolProxy.setMineCoinInfo(erc20.address,11000000000,3100);
        let mineAdd = new BN(10000);
        mineAdd = mineAdd.shln(128).add(new BN(1000000000));
        await poolProxy.setBuyingMineInfo(collateral0,mineAdd)
        await fpt.setManager(accounts[0]);
        await fpt.addMinerBalance(accounts[1],200000000000000);
        result = await poolProxy.getMinerBalance(accounts[1],collateral0);
        assert.equal(result.toNumber(),210000,"getMinerBalance error");
    });
    it('FNXMinePool set functions', async function (){
        let fnx = await FNXCoin.new();
        let erc20 = await Erc20Proxy.new(fnx.address);
        let pool = await minePool.new();
        let poolProxy = await minePoolProxy.new(pool.address);
        let fptimpl = await FPTCoin.new(poolProxy.address,"FPT-A");
        let fpt = await FPTProxy.new(fptimpl.address,poolProxy.address,"FPT-A");
        await poolProxy.setManager(fpt.address);
        let amount = new BN("10000000000000000000000");
        await erc20.transfer(poolProxy.address,amount);
        await poolProxy.send(amount);
        let result = await erc20.balanceOf(poolProxy.address);
        assert.equal(result.toString(10),"10000000000000000000000","erc20 balance error");
        result = await web3.eth.getBalance(poolProxy.address);
        assert.equal(result.toString(10),"10000000000000000000000","ether balance error");
        await poolProxy.setMineCoinInfo(collateral0,10000000000,3000);
        await poolProxy.setMineCoinInfo(erc20.address,11000000000,3100);
        result = await poolProxy.getMineInfo(collateral0);
        assert.equal(result[0].toString(10),"10000000000","setMineCoinInfo error");
        assert.equal(result[1].toString(10),"3000","setMineCoinInfo error");
        result = await poolProxy.getMineInfo(erc20.address);
        assert.equal(result[0].toString(10),"11000000000","setMineCoinInfo error");
        assert.equal(result[1].toString(10),"3100","setMineCoinInfo error");

        result1 = await poolProxy.getTotalMined(collateral0);
        assert.equal(result1.toString(10),"0","getTotalMined error");
        result1 = await poolProxy.getTotalMined(erc20.address);
        assert.equal(result1.toString(10),"0","getTotalMined error");
        result1 = await poolProxy.getMinerBalance(accounts[1],collateral0);
        assert.equal(result1.toString(10),"0","getMinerBalance error");
        result1 = await poolProxy.getMinerBalance(accounts[1],erc20.address);
        assert.equal(result1.toString(10),"0","getMinerBalance error");

        await poolProxy.setBuyingMineInfo(collateral0,10000000000);
        await poolProxy.setBuyingMineInfo(erc20.address,11000000000);

        result1 = await poolProxy.getBuyingMineInfo(collateral0);
        assert.equal(result1.toString(10),"10000000000","getBuyingMineInfo error");
        result1 = await poolProxy.getBuyingMineInfo(erc20.address);
        assert.equal(result1.toString(10),"11000000000","getBuyingMineInfo error");       
        result1 = await poolProxy.getBuyingMineInfoAll();
        assert(result1[0].length == 2 && result1[1].length == 2,"getBuyingMineInfoAll error");
        assert(result1[0][0] == collateral0 && result1[0][1] == erc20.address,"getBuyingMineInfoAll error"); 
        assert(result1[1][0].toString(10) == "10000000000" && result1[1][1].toString(10) == "11000000000","getBuyingMineInfoAll error"); 

        await poolProxy.setMineAmount(collateral0,11000000000);
        await poolProxy.setMineAmount(erc20.address,12000000000);
        await poolProxy.setMineInterval(collateral0,3001);
        await poolProxy.setMineInterval(erc20.address,3101);
        result = await poolProxy.getMineInfo(collateral0);
        assert.equal(result[0].toString(10),"11000000000","setMineCoinInfo error");
        assert.equal(result[1].toString(10),"3001","setMineCoinInfo error");
        result = await poolProxy.getMineInfo(erc20.address);
        assert.equal(result[0].toString(10),"12000000000","setMineCoinInfo error");
        assert.equal(result[1].toString(10),"3101","setMineCoinInfo error");


    });
    it('FNXMinePool calculate functions', async function (){
        let fnx = await FNXCoin.new();
        let erc20 = await Erc20Proxy.new(fnx.address);
        let pool = await minePool.new();
        let poolProxy = await minePoolProxy.new(pool.address);
        let fptimpl = await FPTCoin.new(poolProxy.address,"FPT-A");
        let fpt = await FPTProxy.new(fptimpl.address,poolProxy.address,"FPT-A");
        await poolProxy.setManager(fpt.address);
        await fpt.setManager(accounts[0]);
        let amount = new BN("10000000000000000000000");
        await erc20.transfer(poolProxy.address,amount);
        await poolProxy.send(amount);
        await poolProxy.setMineCoinInfo(collateral0,1000000,2);
        await poolProxy.setMineCoinInfo(erc20.address,2000000,2);
        fpt.mint(accounts[0],10000000000);
        fpt.mint(accounts[1],10000000000);
        fpt.mint(accounts[2],10000000000);
        var begin = new Date().getTime();
        for (var i=0;i<100;i++){
            await fpt.setManager(accounts[0]);
        }
        var end = new Date().getTime();
        var mineTime = (end - begin)/1000;
        var mine0 = Math.floor(1000000*mineTime/6);
        var mine1 = Math.floor(2000000*mineTime/6);
        console.log(mine0,mine1);
        let result1 = await poolProxy.getMinerBalance(accounts[0],collateral0);
        assert(Math.abs(mine0-result1.toNumber())/mine0<0.5,"getMinerBalance error");
        result1 = await poolProxy.getMinerBalance(accounts[0],erc20.address);
        assert(Math.abs(mine1-result1.toNumber())/mine1<0.5,"getMinerBalance error");
        result1 = await poolProxy.getMinerBalance(accounts[1],collateral0);
        assert(Math.abs(mine0-result1.toNumber())/mine0<0.5,"getMinerBalance error");
        result1 = await poolProxy.getMinerBalance(accounts[1],erc20.address);
        assert(Math.abs(mine1-result1.toNumber())/mine1<0.5,"getMinerBalance error");
        result1 = await poolProxy.getMinerBalance(accounts[2],collateral0);
        assert(Math.abs(mine0-result1.toNumber())/mine0<0.5,"getMinerBalance error");
        result1 = await poolProxy.getMinerBalance(accounts[2],erc20.address);
        assert(Math.abs(mine1-result1.toNumber())/mine1<0.5,"getMinerBalance error");
        result1 = await poolProxy.getTotalMined(collateral0);
        assert(Math.abs(mine0*3-result1.toNumber())/(mine0*3)<0.5,"getMinerBalance error");
        result1 = await poolProxy.getTotalMined(erc20.address);
        assert(Math.abs(mine1*3-result1.toNumber())/(mine1*3)<0.5,"getMinerBalance error");

        for (var i=0;i<3;i++){
            let result = await web3.eth.getBalance(poolProxy.address);
            await poolProxy.redeemMinerCoin(collateral0,500000,{from : accounts[i]});
            result1 = await web3.eth.getBalance(poolProxy.address);
            result = (new BN(result)).sub(new BN(result1));
            assert.equal(result,500000,"redeemMinerCoin error");
    
            result = await erc20.balanceOf(poolProxy.address);
            await poolProxy.redeemMinerCoin(erc20.address,1000000,{from : accounts[i]});
            result1 = await erc20.balanceOf(poolProxy.address);
            result = (new BN(result)).sub(new BN(result1));
            assert.equal(result,1000000,"redeemMinerCoin error");
        }

        let result = await web3.eth.getBalance(poolProxy.address);
        await poolProxy.redeemOut(collateral0,5000000000);
        result1 = await web3.eth.getBalance(poolProxy.address);
        result = (new BN(result)).sub(new BN(result1));
        assert.equal(result,5000000000,"redeemMinerCoin error");

        result = await erc20.balanceOf(poolProxy.address);
        await poolProxy.redeemOut(erc20.address,10000000000);
        result1 = await erc20.balanceOf(poolProxy.address);
        result = (new BN(result)).sub(new BN(result1));
        assert.equal(result,10000000000,"redeemMinerCoin error");
    });
});