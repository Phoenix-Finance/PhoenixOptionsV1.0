let createFactory = require("../optionsFactory/optionsFactory.js");
//const minePoolProxy = artifacts.require("MinePoolProxy");
//const minePool = artifacts.require("FNXMinePool");
//const Erc20Proxy = artifacts.require("Erc20Proxy");
const PHXCoin = artifacts.require("PHXCoin");
const PPTCoin = artifacts.require("PPTCoin");
const acceleratedMinePool = artifacts.require("acceleratedMinePool");
let collateral0 = "0x0000000000000000000000000000000000000000";
const BN = require("bn.js");

contract('WETH', function (accounts){
    before(async () => {
        
    })
    it('PPTCoin Erc20 violation test functions', async function (){
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
        await testViolation("transferFrom allowance is insufficient",async function(){
            await pptCoin.transferFrom(accounts[0],accounts[3],10000000000,{from:accounts[2]});   
        });
        await testViolation("transferFrom allowance is insufficient",async function(){
            await pptCoin.approve(accounts[2],10000000000);
            await pptCoin.transferFrom(accounts[0],accounts[3],100000000000,{from:accounts[2]});   
        });
        await testViolation("transfer balance is insufficient",async function(){
            await pptCoin.transfer(accounts[3],100000000000,{from:accounts[2]});   
        });
        await testViolation("transfer balance is insufficient",async function(){
            await pptCoin.approve(accounts[5],10000000000,{from:accounts[4]});
            await pptCoin.transferFrom(accounts[4],accounts[3],100000000000,{from:accounts[5]});  
        });
        await createFactory.multiSignatureAndSend(factory.multiSignature,pptCoin,"modifyLimitation",accounts[0],owners,10000000000,
        100000000000); 
        await factory.optionsFactory.testSetProxyManager(pptCoin.address,accounts[0]);
        await testViolation("mint beyond total Limit",async function(){
            await pptCoin.mint(accounts[0],100000000000);
        });
        await createFactory.multiSignatureAndSend(factory.multiSignature,pptCoin,"modifyLimitation",accounts[0],owners,100000000000,
        10000000000); 
        await factory.optionsFactory.testSetProxyManager(pptCoin.address,accounts[0]);
        await testViolation("mint beyond user Limit",async function(){
            await pptCoin.mint(accounts[0],100000000000);
        });
    });
    return;
    it('PPTCoin burn time violation test functions', async function (){
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
        await testViolation("mint manager is error",async function(){
            await pptCoin.mint(accounts[0],10000000000);  
        });
        await factory.optionsFactory.testSetProxyManager(pptCoin.address,accounts[0]);
        await pptCoin.mint(accounts[0],10000000000);
        await pptCoin.mint(accounts[1],10000000000);
        await pptCoin.mint(accounts[2],10000000000);
        await createFactory.multiSignatureAndSend(factory.multiSignature,factory.optionsFactory,"setPPTTimeLimit",accounts[0],owners,5);
        await testViolation("burn time is unexpired",async function(){
            await pptCoin.burn(accounts[0],5000000000);   
        });
        for (var i=0;i<100;i++){
            await factory.optionsFactory.testSetProxyManager(pptCoin.address,accounts[0]);
        }
        await pptCoin.burn(accounts[0],5000000000);
        await testViolation("burn balance is insufficient",async function(){
            await pptCoin.burn(accounts[0],10000000000);   
        });
        await testViolation("burn time is unexpired",async function(){
            pptCoin.transfer(accounts[0],5000000000,{from:accounts[1]});
            await pptCoin.burn(accounts[0],5000000000);  
        });
        await testViolation("burn time is unexpired",async function(){
            pptCoin.approve(accounts[1],5000000000,{from:accounts[2]});
            pptCoin.transferFrom(accounts[2],accounts[0],5000000000,{from:accounts[1]});
            await pptCoin.burn(accounts[0],5000000000);  
        });
        await pptCoin.burn(accounts[2],5000000000);
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