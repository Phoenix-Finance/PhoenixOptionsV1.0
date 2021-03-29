const minePoolProxy = artifacts.require("MinePoolProxy");
const minePool = artifacts.require("FNXMinePool");
const Erc20Proxy = artifacts.require("Erc20Proxy");
const FNXCoin = artifacts.require("FNXCoin");
let collateral0 = "0x0000000000000000000000000000000000000000";
const FPTProxy = artifacts.require("FPTProxy");
const FPTCoin = artifacts.require("FPTCoinUpgrade");
const BN = require("bn.js");
contract('Erc20Proxy', function (accounts){
    it('FPTProxy Erc20 violation test functions', async function (){
        let fnx = await FNXCoin.new();
        let erc20 = await Erc20Proxy.new(fnx.address);
        let pool = await minePool.new();
        let poolProxy = await minePoolProxy.new(pool.address);
        let fptimpl = await FPTCoin.new(poolProxy.address,"FPT-A");
        let fpt = await FPTProxy.new(fptimpl.address,poolProxy.address,"FPT-A");

        await poolProxy.setManager(fpt.address);
        await poolProxy.setMineCoinInfo(collateral0,1000000,2);
        await poolProxy.setMineCoinInfo(erc20.address,2000000,2);
        await testViolation("transferFrom allowance is insufficient",async function(){
            await fpt.transferFrom(accounts[0],accounts[3],10000000000,{from:accounts[2]});   
        });
        await testViolation("transferFrom allowance is insufficient",async function(){
            await fpt.approve(accounts[2],10000000000);
            await fpt.transferFrom(accounts[0],accounts[3],100000000000,{from:accounts[2]});   
        });
        await testViolation("transfer balance is insufficient",async function(){
            await fpt.transfer(accounts[3],100000000000,{from:accounts[2]});   
        });
        await testViolation("transfer balance is insufficient",async function(){
            await fpt.approve(accounts[5],10000000000,{from:accounts[4]});
            await fpt.transferFrom(accounts[4],accounts[3],100000000000,{from:accounts[5]});  
        });
    });
    it('FPTProxy burntime violation test functions', async function (){
        let fnx = await FNXCoin.new();
        let erc20 = await Erc20Proxy.new(fnx.address);
        let pool = await minePool.new();
        let poolProxy = await minePoolProxy.new(pool.address);
        let fptimpl = await FPTCoin.new(poolProxy.address,"FPT-A");
        let fpt = await FPTProxy.new(fptimpl.address,poolProxy.address,"FPT-A");

        await poolProxy.setManager(fpt.address);
        await poolProxy.setMineCoinInfo(collateral0,1000000,2);
        await poolProxy.setMineCoinInfo(erc20.address,2000000,2);
        await testViolation("mint manager is error",async function(){
            await fpt.mint(accounts[0],10000000000);  
        });
        await fpt.setManager(accounts[0]);
        await fpt.mint(accounts[0],10000000000);
        await fpt.mint(accounts[1],10000000000);
        await fpt.mint(accounts[2],10000000000);
        await fpt.setTimeLimitation(4);
        await testViolation("burn time is unexpired",async function(){
            await fpt.burn(accounts[0],5000000000);   
        });
        for (var i=0;i<100;i++){
            await fpt.setManager(accounts[0]);
        }
        await fpt.burn(accounts[0],5000000000);
        await testViolation("burn balance is insufficient",async function(){
            await fpt.burn(accounts[0],10000000000);   
        });
        await testViolation("burn time is unexpired",async function(){
            fpt.transfer(accounts[0],5000000000,{from:accounts[1]});
            await fpt.burn(accounts[0],5000000000);  
        });
        await testViolation("burn time is unexpired",async function(){
            fpt.approve(accounts[1],5000000000,{from:accounts[2]});
            fpt.transferFrom(accounts[2],accounts[0],5000000000,{from:accounts[1]});
            await fpt.burn(accounts[0],5000000000);  
        });
        await fpt.burn(accounts[2],5000000000);
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