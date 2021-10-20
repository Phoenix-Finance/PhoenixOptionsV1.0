const PHXCoin = artifacts.require("PHXCoin");
const phxMinePoolTest = artifacts.require("phxMinePoolTest");
const phxProxy = artifacts.require("phxProxy");
const multiSignature = artifacts.require("multiSignature");
const BN = require("bn.js");
let createFactory = require("../optionsFactory/optionsFactory.js");
let amount =  new BN("100000000000000000000");
contract('phxMinePoolTest', function (accounts){
    it('phxMinePoolTest PHX mine tests', async function (){
        let owners = [accounts[1],accounts[2],accounts[3],accounts[4],accounts[5]] 
        let multiSign = await multiSignature.new(owners,3);
        let phx = await PHXCoin.new();
        let minePool = await phxMinePoolTest.new(multiSign.address);
        let proxy = await phxProxy.new(minePool.address,multiSign.address);
        minePool = await phxMinePoolTest.at(proxy.address);
        await minePool.setStakeCoin(phx.address);
        await logPhxMineInfo(minePool);
        await minePool.setTime(10);
        await logPhxMineInfo(minePool);
        await createFactory.multiSignatureAndSend(multiSign,minePool,"setMineCoinInfo",accounts[0],owners,phx.address,1e15,1);
        await logPhxMineInfo(minePool);
        await minePool.setTime(20);
        await logPhxMineInfo(minePool);
        await phx.approve(minePool.address,amount);
        await minePool.stake(amount);
        await logPhxMineInfo(minePool);
        await minePool.setTime(30);
        await logPhxMineInfo(minePool);
        for (var i=1;i<4;i++){
            await phx.transfer(accounts[i],amount)
            await phx.approve(minePool.address,amount,{from:accounts[i]});
            await minePool.stake(amount,{from:accounts[i]});
            await logPhxMineInfo(minePool);
            await minePool.setTime(30+i*10);
            await logPhxMineInfo(minePool);
        }
        await minePool.unstakeAll();
        await logPhxMineInfo(minePool);
        await minePool.setTime(100);
        await logPhxMineInfo(minePool);
    });
    async function logPhxMineInfo(minePool){
        let phx = await minePool.stakeCoin();
        let timeStamp = await minePool.timeAccumulation();
        let distribute = await minePool.totalDistribute();
        let netWorth = await minePool.getNetWorth(phx);
        let phxErc = await PHXCoin.at(phx);
        let balance = await phxErc.balanceOf(minePool.address);
        let balance0 = await minePool.getStakeBalance(accounts[0]);
        let balance1 = await minePool.getStakeBalance(accounts[1]);
        let balance2 = await minePool.getStakeBalance(accounts[2]);
        let balance3 = await minePool.getStakeBalance(accounts[3]);
        console.log(timeStamp.toString(),distribute.toString(),netWorth.toString(),balance.toString(),balance0.toString(),balance1.toString(),balance2.toString(),balance3.toString())
    }
});