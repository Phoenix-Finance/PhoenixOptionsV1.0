const minePoolProxy = artifacts.require("MinePoolProxy");
const minePool = artifacts.require("FNXMinePool");
const Erc20Proxy = artifacts.require("Erc20Proxy");
const FNXCoin = artifacts.require("FNXCoin");
let collateral0 = "0x0000000000000000000000000000000000000000";
const FPTProxy = artifacts.require("FPTProxy");
const FPTCoin = artifacts.require("FPTCoinUpgrade");
const BN = require("bn.js");
contract('FPTProxy', function (accounts){
    it('FPTProxy recipient white list tests', async function (){
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
        await fpt.addMinerBalance(accounts[1],1);
        await fpt.mint(accounts[0],10000000000);
        await fpt.mint(accounts[1],10000000000);
        await fpt.mint(accounts[2],10000000000);
        await fpt.setTimeLimitation(3600);
        let time1 = await fpt.getUserBurnTimeLimite(accounts[0]);
        let time2 = await fpt.getUserBurnTimeLimite(accounts[1]);
        let time3 = await fpt.getUserBurnTimeLimite(accounts[2]);
        console.log(time1.toString(),time2.toString(),time3.toString())
        assert(time1.toString()!=0 && time2.toString()!= 0 && time3.toString()!= 0,"getUserBurnTimeLimite error");
        var begin = new Date().getTime();
        for (var i=0;i<100;i++){
            await fpt.setManager(accounts[0]);
        }
        fpt.transfer(accounts[0],5000000000,{from:accounts[1]});
        fpt.transfer(accounts[1],5000000000,{from:accounts[1]});
        fpt.transfer(accounts[2],5000000000,{from:accounts[1]});
        let time11 = await fpt.getUserBurnTimeLimite(accounts[0]);
        let time12 = await fpt.getUserBurnTimeLimite(accounts[1]);
        let time13 = await fpt.getUserBurnTimeLimite(accounts[2]);
        assert.equal(time1.toString(),time11.toString(),"timeLimitWhiteList error");
        assert.equal(time2.toString(),time12.toString(),"timeLimitWhiteList error");
        assert.equal(time3.toString(),time13.toString(),"timeLimitWhiteList error");
        for (var i=0;i<100;i++){
            await fpt.setManager(accounts[0]);
        }
        fpt.transfer(accounts[0],5000000000);
        fpt.transfer(accounts[1],5000000000);
        fpt.transfer(accounts[2],5000000000);
        let time21 = await fpt.getUserBurnTimeLimite(accounts[0]);
        let time22 = await fpt.getUserBurnTimeLimite(accounts[1]);
        let time23 = await fpt.getUserBurnTimeLimite(accounts[2]);
        assert(time1.toNumber()<time21.toNumber(),"timeLimitWhiteList error");
        assert(time2.toNumber()<time22.toNumber(),"timeLimitWhiteList error");
        assert(time3.toNumber()<time23.toNumber(),"timeLimitWhiteList error");
    });
});