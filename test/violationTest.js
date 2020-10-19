let month = 30*60*60*24;
const BN = require("bn.js");
let collateral0 = "0x0000000000000000000000000000000000000000";
let {migration ,createAndAddErc20,AddCollateral0} = require("./testFunction.js");
contract('OptionsManagerV2', function (accounts){

    it('OptionsManagerV2 buy options violation test', async function (){
        let contracts = await migration(accounts);
        await AddCollateral0(contracts);
        await createAndAddErc20(contracts);
        await contracts.FPT.setTimeLimitation(100);
        let deposit = new BN(1000*1e6);
        let decemal = new BN(1e12);
        deposit = deposit.mul(decemal);
        await contracts.manager.addCollateral(collateral0,deposit,{value : deposit});
        await contracts.manager.modifyPermission(collateral0,0xffffffff);
        await testViolation("buy option invalid option type test failed",async function(){
            await contracts.manager.buyOption(collateral0,1000000000000000,9000e8,1,month,10000000000,2,{value : 1000000000000000});    
        })
        await testViolation("buy option invalid input amount test failed",async function(){
            await contracts.manager.buyOption(collateral0,10,9000e8,1,month,10000000000,0,{value : 10}); 
        })
        await testViolation("buy option invalid strike price test failed",async function(){
            await contracts.manager.buyOption(collateral0,1000000000000000,90e8,1,month,10000000000,0,{value : 1000000000000000});     
        })
        await testViolation("buy option invalid settlement address test failed",async function(){
            await contracts.manager.buyOption(accounts[0],1000000000000000,9000e8,1,month,10000000000,0,{value : 1000000000000000});     
        })
        await testViolation("buy option invalid underlying test failed",async function(){
            await contracts.manager.buyOption(collateral0,1000000000000000,9000e8,5,month,10000000000,0,{value : 1000000000000000});     
        })
        await testViolation("buy option invalid expiration test failed",async function(){
            await contracts.manager.buyOption(collateral0,1000000000000000,9000e8,1,6*60*60*24,10000000000,0,{value : 1000000000000000});     
        })
        await testViolation("buy option not allowed test failed",async function(){
            await contracts.manager.modifyPermission(collateral0,0xffffffff - 0x0001);
            await contracts.manager.buyOption(collateral0,1000000000000000,9000e8,1,month,10000000000,0,{from:accounts[1],value : 1000000000000000});     
        })
        await contracts.manager.modifyPermission(collateral0,0xffffffff - 0x0002);
        await contracts.manager.buyOption(collateral0,1000000000000000,9000e8,1,month,10000000000,0,{from:accounts[2],value : 1000000000000000});     

    });
    it('OptionsManagerV2 add collateral violation test', async function (){
        let contracts = await migration(accounts);
        await AddCollateral0(contracts);
        await createAndAddErc20(contracts);
        await contracts.FPT.setTimeLimitation(100);
        let deposit = new BN(1000*1e6);
        let decemal = new BN(1e12);
        deposit = deposit.mul(decemal);
        await contracts.manager.addCollateral(collateral0,deposit,{value : deposit});
        await testViolation("buy option collateral address test failed",async function(){
            await contracts.manager.addCollateral(accounts[0],1000000000000000,{value : 1000000000000000});    
        })
        await testViolation("buy option input amount test failed",async function(){
            await contracts.manager.addCollateral(collateral0,1000000000000000,{value : 10});    
        })
        await testViolation("buy option not approve contracts.FNX test failed",async function(){
            await contracts.manager.addCollateral(contracts.FNX.address,1000000000000000);    
        })
        await testViolation("buy option not allowed test failed",async function(){
            await contracts.manager.modifyPermission(collateral0,0xffffffff - 0x0001);
            await contracts.manager.addCollateral(collateral0,1000000000000000,{from:accounts[1],value : 1000000000000000});     
        })
        await contracts.manager.modifyPermission(collateral0,0xffffffff - 0x0002);
        await contracts.manager.addCollateral(collateral0,1000000000000000,{from:accounts[2],value : 1000000000000000});     

    });
    it('OptionsManagerV2 redeem collateral violation test', async function (){
        let contracts = await migration(accounts);
        await AddCollateral0(contracts);
        await createAndAddErc20(contracts);
        await contracts.FPT.setTimeLimitation(100);
        await contracts.manager.modifyPermission(collateral0,0xffffffff);
        await testViolation("redeem collateral insufficient test failed",async function(){
            await contracts.manager.redeemCollateral(1000000000000000,collateral0,{from : accounts[1]});    
        })
        await testViolation("redeem collateral input amount test failed",async function(){
            await contracts.manager.redeemCollateral(100,collateral0);    
        })
        await testViolation("redeem collateral invalid collateral address test failed",async function(){
            await contracts.manager.redeemCollateral(1000000000000000,accounts[1]);    
        })
        await testViolation("redeem collateral not allowed test failed",async function(){
            await contracts.manager.addCollateral(collateral0,1000000000000000,{from:accounts[1],value : 1000000000000000}); 
            await contracts.manager.modifyPermission(collateral0,0xffffffff - 0x0002);  
            await contracts.manager.redeemCollateral(1000000000000,collateral0,{from:accounts[1]});  
        })
        await testViolation("redeem collateral not allowed test failed",async function(){
            await contracts.manager.redeemCollateral(1000000000000,contracts.FNX.address,{from:accounts[1]});  
        })
        await testViolation("redeem collateral lock time test failed",async function(){
            await contracts.manager.modifyPermission(collateral0,0xffffffff);
            await contracts.manager.addCollateral(collateral0,1000000000000000,{from:accounts[2],value : 1000000000000000}); 
            await contracts.manager.modifyPermission(collateral0,0xffffffff - 0x0001);  
            await contracts.manager.redeemCollateral(1000000000000,collateral0,{from:accounts[2]});  
        })
        await testViolation("redeem collateral lock time test failed",async function(){
            await contracts.manager.modifyPermission(collateral0,0xffffffff);
            await contracts.manager.addCollateral(collateral0,1000000000000000,{from:accounts[2],value : 1000000000000000}); 
            await contracts.FPT.transfer(accounts[3],1000000000000,{from:accounts[2]}) 
            await contracts.manager.redeemCollateral(1000000000000,collateral0,{from:accounts[3]});  
        })
    });
    it('OptionsManagerV2 sell options violation test', async function (){
        let contracts = await migration(accounts);
        await AddCollateral0(contracts);
        await createAndAddErc20(contracts);
        await contracts.FPT.setTimeLimitation(100);
        let deposit = new BN(1000*1e6);
        let decemal = new BN(1e12);
        deposit = deposit.mul(decemal);
        await contracts.manager.addCollateral(collateral0,deposit,{value : deposit});
        await contracts.manager.modifyPermission(collateral0,0xffffffff);
        await contracts.manager.buyOption(collateral0,1000000000000000,10000e8,1,month,10000000000,1,{value : 1000000000000000}); 
        let optionID = await contracts.options.getOptionInfoLength(); 
        await testViolation("sell options violated owner  test failed",async function(){
            await contracts.manager.sellOption(optionID,10000000000,{from : accounts[1]});    
        })
        await testViolation("sell options input amount test failed",async function(){
            await contracts.manager.sellOption(optionID,10);    
        })
        await testViolation("sell options insufficient test failed",async function(){
            await contracts.manager.sellOption(optionID,1000000000000);    
        })
        await testViolation("sell options error optionID test failed",async function(){
            await contracts.manager.sellOption(optionID.toNumber()+1,1000000000000);    
        })
        await testViolation("exercise options violated owner  test failed",async function(){
            await contracts.manager.exerciseOption(optionID,10000000000,{from : accounts[1]});    
        })
        await testViolation("exercise options input amount test failed",async function(){
            await contracts.manager.exerciseOption(optionID,10);    
        })
        await testViolation("exercise options insufficient test failed",async function(){
            await contracts.manager.exerciseOption(optionID,1000000000000);    
        })
        await testViolation("exercise options error optionID test failed",async function(){
            await contracts.manager.exerciseOption(optionID.toNumber()+1,1000000000000);    
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