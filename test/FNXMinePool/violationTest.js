const minePoolProxy = artifacts.require("MinePoolProxy");
const minePool = artifacts.require("FNXMinePool");
const Erc20Proxy = artifacts.require("Erc20Proxy");
const FNXCoin = artifacts.require("FNXCoin");
let collateral0 = "0x0000000000000000000000000000000000000000";
const FPTProxy = artifacts.require("FPTProxy");
const FPTCoin = artifacts.require("FPTCoin");
const BN = require("bn.js");
contract('FNXMinePool', function (accounts){
    it('FNXMinePool violation test functions', async function (){
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
        await poolProxy.setMineCoinInfo(collateral0,1000000,2);
        await poolProxy.setMineCoinInfo(erc20.address,2000000,2);
        await testViolation("redeemOut is not owner",async function(){
            await poolProxy.redeemOut(collateral0,10000000000,{from:accounts[1]}); 
        });
        await testViolation("redeemOut is not owner",async function(){
            await poolProxy.redeemOut(erc20.address,10000000000,{from:accounts[1]}); 
        });
        await testViolation("setMineCoinInfo is not owner",async function(){
            await poolProxy.setMineCoinInfo(collateral0,10000000000,3,{from:accounts[1]}); 
        });
        await testViolation("setMineCoinInfo is not owner",async function(){
            await poolProxy.setMineCoinInfo(erc20.address,10000000000,3,{from:accounts[1]}); 
        });
        await testViolation("setBuyingMineInfo is not owner",async function(){
            await poolProxy.setBuyingMineInfo(collateral0,10000000000,{from:accounts[1]}); 
        });
        await testViolation("setBuyingMineInfo is not owner",async function(){
            await poolProxy.setBuyingMineInfo(erc20.address,10000000000,{from:accounts[1]}); 
        });
        await testViolation("redeemMinerCoin is insufficient",async function(){
            await poolProxy.redeemMinerCoin(collateral0,10000000000,{from:accounts[1]}); 
        });
        await testViolation("redeemMinerCoin is insufficient",async function(){
            await poolProxy.redeemMinerCoin(erc20.address,10000000000,{from:accounts[1]}); 
        });
    });
});
async function testViolation(message,testFunc){
    bErr = false;
    try {
        await testFunc();        
    } catch (error) {
        console.log(error);
        bErr = true;
    }
    assert(bErr,message);
}