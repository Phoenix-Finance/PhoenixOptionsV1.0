const CollateralPool = artifacts.require("CollateralPool");
const CollateralProxy = artifacts.require("CollateralProxy");
let collateral0 = "0x0000000000000000000000000000000000000000";
const BN = require("bn.js");
contract('CollateralPool', function (accounts){

    it('CollateralPool set functions', async function (){
        let collateral = await CollateralPool.new();
        let pool = await CollateralProxy.new(collateral.address);
        for (var i=0;i<5;i++){
            let result = await pool.getFeeRate(i);
            if (i == 1){
                assert.equal(result[0],50,"getFeeRate Error");
            }else{
                assert.equal(result[0],0,"getFeeRate Error");
            }
            assert.equal(result[1],1000,"getFeeRate Error");
        }
        for (var i=0;i<5;i++){
            await pool.setTransactionFee(i,i+1,(i+1)*1000);
            let result = await pool.getFeeRate(i);
            assert.equal(result[0],i+1,"getFeeRate Error");
            assert.equal(result[1],(i+1)*1000,"getFeeRate Error");
            result = await pool.calculateFee(i,10000);
            assert.equal(result,10,"calculateFee Error");
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
        await pool.addWhiteList(collateral0);
        result = await pool.getAllFeeBalances();
        console.log(result);
    });

});