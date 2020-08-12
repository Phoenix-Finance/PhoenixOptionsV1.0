const OptionsManagerV2 = artifacts.require("OptionsManagerV2");
const OptionsPool = artifacts.require("OptionsPoolTest");
const FPTCoin = artifacts.require("FPTCoin");
const OptionsPrice = artifacts.require("OptionsPrice");
let CollateralPool = artifacts.require("CollateralPool");
let FNXCoin = artifacts.require("FNXCoin");
const BN = require("bn.js");
let month = 30*60*60*24;
let collateral0 = "0x0000000000000000000000000000000000000000";
let testFunc = require("./testFunction.js")
let FNXMinePool = artifacts.require("FNXMinePool");
contract('OptionsManagerV2', function (accounts){

    it('OptionsManagerV2 buy options violation test', async function (){
        let OptionsManger = await OptionsManagerV2.deployed();
        let CoinInstance = await FPTCoin.deployed();
        await CoinInstance.setBurnTimeLimited(100);
        let deposit = new BN(1000*1e6);
        let decemal = new BN(1e12);
        deposit = deposit.mul(decemal);
        await OptionsManger.addCollateral(collateral0,deposit,{value : deposit});
        await OptionsManger.modifyPermission(collateral0,0xffffffff);
        await testViolation("buy option invalid option type test failed",async function(){
            await OptionsManger.buyOption(collateral0,1000000000000000,9000e8,1,month,10000000000,2,{value : 1000000000000000});    
        })
        await testViolation("buy option invalid input amount test failed",async function(){
            await OptionsManger.buyOption(collateral0,10,9000e8,1,month,10000000000,0,{value : 10}); 
        })
        await testViolation("buy option invalid strike price test failed",async function(){
            await OptionsManger.buyOption(collateral0,1000000000000000,90e8,1,month,10000000000,0,{value : 1000000000000000});     
        })
        await testViolation("buy option invalid settlement address test failed",async function(){
            await OptionsManger.buyOption(accounts[0],1000000000000000,9000e8,1,month,10000000000,0,{value : 1000000000000000});     
        })
        await testViolation("buy option invalid underlying test failed",async function(){
            await OptionsManger.buyOption(collateral0,1000000000000000,9000e8,5,month,10000000000,0,{value : 1000000000000000});     
        })
        await testViolation("buy option invalid expiration test failed",async function(){
            await OptionsManger.buyOption(collateral0,1000000000000000,9000e8,1,6*60*60*24,10000000000,0,{value : 1000000000000000});     
        })
        await testViolation("buy option not allowed test failed",async function(){
            await OptionsManger.modifyPermission(collateral0,0xffffffff - 0x0001);
            await OptionsManger.buyOption(collateral0,1000000000000000,9000e8,1,month,10000000000,0,{from:accounts[1],value : 1000000000000000});     
        })
        await OptionsManger.modifyPermission(collateral0,0xffffffff - 0x0002);
        await OptionsManger.buyOption(collateral0,1000000000000000,9000e8,1,month,10000000000,0,{from:accounts[2],value : 1000000000000000});     

    });
    it('OptionsManagerV2 add collateral violation test', async function (){
        let OptionsManger = await OptionsManagerV2.deployed();
        let deposit = new BN(1000*1e6);
        let decemal = new BN(1e12);
        deposit = deposit.mul(decemal);
        let fnx = await FNXCoin.deployed();
        await OptionsManger.addCollateral(collateral0,deposit,{value : deposit});
        await testViolation("buy option collateral address test failed",async function(){
            await OptionsManger.addCollateral(accounts[0],1000000000000000,{value : 1000000000000000});    
        })
        await testViolation("buy option input amount test failed",async function(){
            await OptionsManger.addCollateral(collateral0,1000000000000000,{value : 10});    
        })
        await testViolation("buy option not approve fnx test failed",async function(){
            await OptionsManger.addCollateral(fnx.address,1000000000000000);    
        })
        await testViolation("buy option not allowed test failed",async function(){
            await OptionsManger.modifyPermission(collateral0,0xffffffff - 0x0001);
            await OptionsManger.addCollateral(collateral0,1000000000000000,{from:accounts[1],value : 1000000000000000});     
        })
        await OptionsManger.modifyPermission(collateral0,0xffffffff - 0x0002);
        await OptionsManger.addCollateral(collateral0,1000000000000000,{from:accounts[2],value : 1000000000000000});     

    });
    it('OptionsManagerV2 redeem collateral violation test', async function (){
        let OptionsManger = await OptionsManagerV2.deployed();
        let fnx = await FNXCoin.deployed();
        await OptionsManger.modifyPermission(collateral0,0xffffffff);
        await testViolation("redeem collateral insufficient test failed",async function(){
            await OptionsManger.redeemCollateral(1000000000000000,collateral0,{from : accounts[1]});    
        })
        await testViolation("redeem collateral input amount test failed",async function(){
            await OptionsManger.redeemCollateral(100,collateral0);    
        })
        await testViolation("redeem collateral invalid collateral address test failed",async function(){
            await OptionsManger.redeemCollateral(1000000000000000,accounts[1]);    
        })
        await testViolation("redeem collateral not allowed test failed",async function(){
            await OptionsManger.addCollateral(collateral0,1000000000000000,{from:accounts[1],value : 1000000000000000}); 
            await OptionsManger.modifyPermission(collateral0,0xffffffff - 0x0002);  
            await OptionsManger.redeemCollateral(1000000000000,collateral0,{from:accounts[1]});  
        })
        await testViolation("redeem collateral not allowed test failed",async function(){
            await OptionsManger.redeemCollateral(1000000000000,fnx.address,{from:accounts[1]});  
        })
        await testViolation("redeem collateral lock time test failed",async function(){
            await OptionsManger.modifyPermission(collateral0,0xffffffff);
            await OptionsManger.addCollateral(collateral0,1000000000000000,{from:accounts[2],value : 1000000000000000}); 
            await OptionsManger.modifyPermission(collateral0,0xffffffff - 0x0001);  
            await OptionsManger.redeemCollateral(1000000000000,collateral0,{from:accounts[2]});  
        })
        await testViolation("redeem collateral lock time test failed",async function(){
            await OptionsManger.modifyPermission(collateral0,0xffffffff);
            await OptionsManger.addCollateral(collateral0,1000000000000000,{from:accounts[2],value : 1000000000000000}); 
            await CoinInstance.transfer(accounts[3],1000000000000,{from:accounts[2]}) 
            await OptionsManger.redeemCollateral(1000000000000,collateral0,{from:accounts[3]});  
        })
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