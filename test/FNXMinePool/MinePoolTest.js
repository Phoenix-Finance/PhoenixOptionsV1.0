const minePoolProxy = artifacts.require("MinePoolProxy");
const minePool = artifacts.require("FNXMinePool");
const Erc20Proxy = artifacts.require("Erc20Proxy");
const FNXCoin = artifacts.require("FNXCoin");
let collateral0 = "0x0000000000000000000000000000000000000000";
const FPTProxy = artifacts.require("FPTProxy");
const FPTCoin = artifacts.require("FPTCoin");
const BN = require("bn.js");
contract('FNXMinePool', function (accounts){

    it('FNXMinePool set functions', async function (){
        let fnx = await FNXCoin.new();
        let erc20 = await Erc20Proxy.new(fnx.address);
        let pool = await minePool.new();
        let poolProxy = await minePoolProxy.new(pool.address);
        let fptimpl = await FPTCoin.new();
        let fpt = await FPTProxy.new(fptimpl.address,poolProxy.address);
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
        let fptimpl = await FPTCoin.new();
        let fpt = await FPTProxy.new(fptimpl.address,poolProxy.address);
        await poolProxy.setManager(fpt.address);
        await fpt.setManager(accounts[1]);
    });
});