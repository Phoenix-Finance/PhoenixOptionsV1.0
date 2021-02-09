const minePoolProxy = artifacts.require("MinePoolProxy");
const minePool = artifacts.require("FNXMinePool");
const Erc20Proxy = artifacts.require("Erc20Proxy");
const FNXCoin = artifacts.require("FNXCoin");
let collateral0 = "0x0000000000000000000000000000000000000000";
const FPTProxy = artifacts.require("FPTProxy");
const FPTCoin = artifacts.require("FPTCoinUpgrade");
const BN = require("bn.js");
contract('FPTProxy', function (accounts){
    it('FPTProxy Erc20 test functions', async function (){
        let fnx = await FNXCoin.new();
        let erc20 = await Erc20Proxy.new(fnx.address);
        let pool = await minePool.new();
        let poolProxy = await minePoolProxy.new(pool.address);
        let fptimpl = await FPTCoin.new(poolProxy.address,"FPT-A");
        let fpt = await FPTProxy.new(fptimpl.address,poolProxy.address,"FPT-A");
        await poolProxy.setManager(fpt.address);
        await poolProxy.setMineCoinInfo(collateral0,1000000,2);
        await poolProxy.setMineCoinInfo(erc20.address,2000000,2);
        let name = await fpt.name();
        assert.equal(name,"FPT-A","name Error");
        let symbol = await fpt.symbol();
        assert.equal(symbol,"FPT-A","symbol Error");
        let decimals = await fpt.decimals();
        assert.equal(decimals,18,"decimals Error");
        let totalSupply = await fpt.totalSupply();
        let total = "0";
        assert.equal(totalSupply.toString(10),total,"totalSupply Error");
        await fpt.setManager(accounts[1]);
        let result = await fpt.getManager();
        assert.equal(result,accounts[1],"setManager Error");
        let amount = new BN("10000000000000000000000");
        await fpt.mint(accounts[0],amount,{from:accounts[1]});
        totalSupply = await fpt.totalSupply();
        assert.equal(totalSupply.toString(10),"10000000000000000000000","totalSupply Error");
        await fpt.approve(accounts[2],10000000000);
        result = await fpt.allowance(accounts[0],accounts[2]);
        assert.equal(result,10000000000,"approve Error");
        await fpt.transferFrom(accounts[0],accounts[3],10000000000,{from:accounts[2]});
        result = await fpt.allowance(accounts[0],accounts[2]);
        assert.equal(result,0,"allowance Error");
        result = await fpt.balanceOf(accounts[0]);
        assert.equal(result.toString(10),"9999999999990000000000","accounts[0] Error");
        result = await fpt.balanceOf(accounts[3]);
        assert.equal(result.toString(10),"10000000000","accounts[3] Error");
        result = await fpt.balanceOf(accounts[2]);
        assert.equal(result.toString(10),"0","accounts[2] Error");
        await fpt.transfer(accounts[4],10000000000);
        result = await fpt.balanceOf(accounts[0]);
        assert.equal(result.toString(10),"9999999999980000000000","accounts[0] Error");
        result = await fpt.balanceOf(accounts[3]);
        assert.equal(result.toString(10),"10000000000","accounts[3] Error");
        result = await fpt.balanceOf(accounts[2]);
        assert.equal(result.toString(10),"0","accounts[2] Error");
        result = await fpt.balanceOf(accounts[4]);
        assert.equal(result.toString(10),"10000000000","accounts[2] Error");
    });
    it('FPTProxy set functions', async function (){
        let fnx = await FNXCoin.new();
        let erc20 = await Erc20Proxy.new(fnx.address);
        let pool = await minePool.new();
        let poolProxy = await minePoolProxy.new(pool.address);
        let fptimpl = await FPTCoin.new(poolProxy.address,"FPT-A");
        let fpt = await FPTProxy.new(fptimpl.address,poolProxy.address,"FPT-A");

        await poolProxy.setManager(fpt.address);
        await poolProxy.setMineCoinInfo(collateral0,1000000,2);
        await poolProxy.setMineCoinInfo(erc20.address,2000000,2);
        let result = await fpt.getUserBurnTimeLimite(accounts[0]);
        assert.equal(result.toString(10),"3600","getUserBurnTimeLimite error");

        fpt.setTimeLimitation(7200);
        result = await fpt.getUserBurnTimeLimite(accounts[0]);
        assert.equal(result.toString(10),"7200","getUserBurnTimeLimite error");

        result = await fpt.getTotalLockedWorth();
        assert.equal(result.toString(10),"0","getTotalLockedWorth error");

        result = await fpt.lockedBalanceOf(accounts[1]);
        assert.equal(result.toString(10),"0","getTotalLockedWorth error");

        result = await fpt.lockedWorthOf(accounts[2]);
        assert.equal(result.toString(10),"0","getTotalLockedWorth error");

        result = await fpt.getLockedBalance(accounts[2]);
        assert(result[0].toString(10)=="0" && result[1].toString(10)=="0","getLockedBalance error");
    });
    it('FPTProxy calculate functions', async function (){
        let fnx = await FNXCoin.new();
        let erc20 = await Erc20Proxy.new(fnx.address);
        let pool = await minePool.new();
        let poolProxy = await minePoolProxy.new(pool.address);
        let fptimpl = await FPTCoin.new(poolProxy.address,"FPT-A");
        let fpt = await FPTProxy.new(fptimpl.address,poolProxy.address,"FPT-A");
        await poolProxy.setManager(fpt.address);
        await fpt.setManager(accounts[0]);
        await poolProxy.setMineCoinInfo(collateral0,1000000,2);
        await poolProxy.setMineCoinInfo(erc20.address,2000000,2);
        await fpt.mint(accounts[0],10000000000);
        await fpt.mint(accounts[1],10000000000);
        await fpt.mint(accounts[2],10000000000);
        await fpt.setTimeLimitation(0);
        var begin = new Date().getTime();
        for (var i=0;i<100;i++){
            await fpt.setManager(accounts[0]);
        }

        await fpt.burn(accounts[0],5000000000);
        let result = await fpt.balanceOf(accounts[0]);
        assert.equal(result.toString(10),"5000000000","getTotalLockedWorth error");

        let totalSupply = await fpt.totalSupply();
        assert.equal(totalSupply.toString(10),"25000000000","totalSupply Error");

        for (var i=0;i<3;i++){
            await fpt.addlockBalance(accounts[i],(i+1)*100000000,(i+1)*1000000000000);
            result = await fpt.getLockedBalance(accounts[i]);
            assert(result[0].toNumber()==(i+1)*100000000 && result[1].toNumber()==(i+1)*1000000000000,
                "getLockedBalance balance error");
        }
        totalSupply = await fpt.totalSupply();
        assert.equal(totalSupply.toString(10),"24400000000","totalSupply Error");
        result = await fpt.getTotalLockedWorth();
        assert.equal(result.toString(10),"6000000000000","getTotalLockedWorth Error");
        await fpt.redeemLockedCollateral(accounts[0],50000000,500000000000);
        await fpt.redeemLockedCollateral(accounts[1],50000000,1000000000000);
        await fpt.redeemLockedCollateral(accounts[2],400000000,4000000000000);
        result = await fpt.getLockedBalance(accounts[0]);
        assert(result[0].toNumber()==50000000 && result[1].toNumber()==500000000000,
            "getLockedBalance balance error");
        result = await fpt.getLockedBalance(accounts[1]);
        assert(result[0].toNumber()==150000000 && result[1].toNumber()==1500000000000,
            "getLockedBalance balance error");
        result = await fpt.getLockedBalance(accounts[2]);
        assert(result[0].toNumber()==0 && result[1].toNumber()==0,
            "getLockedBalance balance error");
        totalSupply = await fpt.totalSupply();
        assert.equal(totalSupply.toString(10),"24400000000","totalSupply Error");
        result = await fpt.getTotalLockedWorth();
        assert.equal(result.toString(10),"2000000000000","getTotalLockedWorth Error");
    });
});