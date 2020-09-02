const Erc20Proxy = artifacts.require("Erc20Proxy");
const FNXCoin = artifacts.require("FNXCoin");
const BN = require("bn.js");
contract('Erc20Proxy', function (accounts){
    it('Erc20Proxy violation test functions', async function (){

        let fnx = await FNXCoin.new();
        console.log(fnx.address)
        let erc20 = await Erc20Proxy.new(fnx.address);
        await testViolation("transferFrom allowance is insufficient",async function(){
            await erc20.transferFrom(accounts[0],accounts[3],10000000000,{from:accounts[2]});   
        });
        await testViolation("transferFrom allowance is insufficient",async function(){
            await erc20.approve(accounts[2],10000000000);
            await erc20.transferFrom(accounts[0],accounts[3],100000000000,{from:accounts[2]});   
        });
        await testViolation("transfer balance is insufficient",async function(){
            await erc20.transfer(accounts[3],100000000000,{from:accounts[2]});   
        });
        await testViolation("transfer balance is insufficient",async function(){
            await erc20.approve(accounts[5],10000000000,{from:accounts[4]});
            await erc20.transferFrom(accounts[4],accounts[3],100000000000,{from:accounts[5]});  
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