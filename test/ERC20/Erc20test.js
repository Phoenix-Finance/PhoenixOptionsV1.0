const Erc20Proxy = artifacts.require("Erc20Proxy");
const FNXCoin = artifacts.require("FNXCoin");
const BN = require("bn.js");
contract('Erc20Proxy', function (accounts){
    it('Erc20Proxy test functions', async function (){
        let fnx = await FNXCoin.new();
        console.log(fnx.address)
        let erc20 = await Erc20Proxy.new(fnx.address);
        let name = await erc20.name();
        assert.equal(name,"FNXCoin","name Error");
        let symbol = await erc20.symbol();
        assert.equal(symbol,"FNX","symbol Error");
        let decimals = await erc20.decimals();
        assert.equal(decimals,18,"decimals Error");
        let totalSupply = await erc20.totalSupply();
        let total = "10000000000000000000000000000000";
        assert.equal(totalSupply.toString(10),total,"totalSupply Error");
        await erc20.approve(accounts[2],10000000000);
        let result = await erc20.allowance(accounts[0],accounts[2]);
        assert.equal(result,10000000000,"approve Error");
        await erc20.transferFrom(accounts[0],accounts[3],10000000000,{from:accounts[2]});
        result = await erc20.allowance(accounts[0],accounts[2]);
        console.log(result.toString(10))
        result = await erc20.balanceOf(accounts[0]);
        assert.equal(result.toString(10),"999999999999999999990000000000","accounts[0] Error");
        result = await erc20.balanceOf(accounts[3]);
        assert.equal(result.toString(10),"10000000000","accounts[3] Error");
        result = await erc20.balanceOf(accounts[2]);
        assert.equal(result.toString(10),"0","accounts[2] Error");
        await erc20.transfer(accounts[4],10000000000);
        result = await erc20.balanceOf(accounts[0]);
        assert.equal(result.toString(10),"999999999999999999980000000000","accounts[0] Error");
        result = await erc20.balanceOf(accounts[3]);
        assert.equal(result.toString(10),"10000000000","accounts[3] Error");
        result = await erc20.balanceOf(accounts[2]);
        assert.equal(result.toString(10),"0","accounts[2] Error");
        result = await erc20.balanceOf(accounts[4]);
        assert.equal(result.toString(10),"10000000000","accounts[2] Error");
    });
});