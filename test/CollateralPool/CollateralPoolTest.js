let createFactory = require("../optionsFactory/optionsFactory.js");
//const minePoolProxy = artifacts.require("MinePoolProxy");
//const minePool = artifacts.require("FNXMinePool");
//const Erc20Proxy = artifacts.require("Erc20Proxy");
const PHXCoin = artifacts.require("PHXCoin");
const OptionsPool = artifacts.require("OptionsPool");
const CollateralPool = artifacts.require("CollateralPool");
const PHXVestingPool = artifacts.require("PHXVestingPool");
let collateral0 = "0x0000000000000000000000000000000000000000";
const BN = require("bn.js");
contract('CollateralPool', function (accounts){
    it('CollateralPool set functions', async function (){
        let owners = [accounts[1],accounts[2],accounts[3],accounts[4],accounts[5]] 
        let factory = await createFactory.createTestFactory(accounts[0],owners)
        await factory.optionsFactory.testCreateCollateralPool([1,2]);
        let pool = await factory.optionsFactory.latestAddress();
        pool = await CollateralPool.at(pool);
        for (var i=0;i<5;i++){
            await createFactory.multiSignatureAndSend(factory.multiSignature,pool,"setTransactionFee",accounts[0],owners,i,i+1);
            let result = await pool.getFeeRate(i);
            assert.equal(result,i+1,"getFeeRate Error");
            result = await pool.calculateFee(i,10000);
            assert.equal(result,(i+1)*10,"calculateFee Error");
        }
        let result = await pool.getFeeBalance(collateral0);
        assert.equal(result,0,"getFeeBalance Error");

        result = await pool.getUserPayingUsd(accounts[0]);
        assert.equal(result,0,"getUserPayingUsd Error");
        result = await pool.getUserInputCollateral(accounts[0],collateral0);
        assert.equal(result,0,"getUserInputCollateral Error");
        result = await pool.getNetWorthBalance(collateral0);
        assert.equal(result,0,"getNetWorthBalance Error");
        result = await pool.getCollateralBalance(collateral0);
        assert.equal(result,0,"getCollateralBalance Error");
        console.log(result);
    });
});