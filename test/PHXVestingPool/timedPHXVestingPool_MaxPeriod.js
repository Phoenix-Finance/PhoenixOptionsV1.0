const PHXVestingPool = artifacts.require("PHXVestingPool_Timed");
let createFactory = require("../optionsFactory/optionsFactory.js");
//const minePoolProxy = artifacts.require("MinePoolProxy");
//const minePool = artifacts.require("FNXMinePool");
//const Erc20Proxy = artifacts.require("Erc20Proxy");
const PHXCoin = artifacts.require("PHXCoin");
const PPTCoin = artifacts.require("PPTCoin");
const acceleratedMinePool = artifacts.require("acceleratedMinePool");
const phxProxy = artifacts.require("phxProxy");
let collateral0 = "0x0000000000000000000000000000000000000000";
contract('PHXVestingPool_Timed', function (accounts){
    it('PHXVestingPool_Timed one person mined max period', async function (){
        let owners = [accounts[1],accounts[2],accounts[3],accounts[4],accounts[5]] 
        let factory = await createFactory.createTestFactory(accounts[0],owners)
        let vestingPool =  await PHXVestingPool.new(factory.multiSignature.address,{from:accounts[0]});
        let vestingPoolProxy = await phxProxy.new(vestingPool.address,factory.multiSignature.address,{from:accounts[0]});
        vestingPool = await PHXVestingPool.at(vestingPoolProxy.address);
        await createFactory.multiSignatureAndSend(factory.multiSignature,factory.optionsFactory,"setPHXVestingPool",accounts[0],owners,
        vestingPool.address);
        await vestingPool.initMineLockedInfo(0,86400*30,36,{from:accounts[0]});
        await factory.optionsFactory.testCreatePPTCoin();
        let pptAddress = await factory.optionsFactory.latestAddress();
        let pptCoin = await PPTCoin.at(pptAddress);
        let phx = await PHXCoin.new();
        let cphx = await PHXCoin.new();
        let poolAddr = await pptCoin.minePool();
        let minePool = await acceleratedMinePool.at(poolAddr);
        await createFactory.multiSignatureAndSend(factory.multiSignature,minePool,"setMineCoinInfo",accounts[0],owners,
            collateral0,1000000,2);
        await createFactory.multiSignatureAndSend(factory.multiSignature,minePool,"setMineCoinInfo",accounts[0],owners,
            phx.address,2000000,2);
        await createFactory.multiSignatureAndSend(factory.multiSignature,vestingPool,"setVestingRate",accounts[0],owners,
            phx.address,1000);
        await createFactory.multiSignatureAndSend(factory.multiSignature,vestingPool,"setVestingRate",accounts[0],owners,
            cphx.address,1000);
        let nowId = await vestingPool.getCurrentPeriodID();
        assert.equal(nowId.toNumber(),1,"getCurrentPeriodID Error");
        await phx.approve(vestingPool.address,1e14)
        await vestingPool.stake(phx.address,1e14,36,minePool.address);
        let userPeriodId = await vestingPool.getUserMaxPeriodId(accounts[0]);
        assert.equal(userPeriodId.toNumber(),nowId.toNumber()+35,"getUserMaxPeriodId Error");
        await vestingPool.setTime(2100);
        let preBalance = await phx.balanceOf(accounts[0])
        await vestingPool.unstake(phx.address,1e14,minePool.address);
        let endBalance = await phx.balanceOf(accounts[0])
        console.log(preBalance.toString(),endBalance.toString())
    });
    return;
    it('fixedMinePool_Timed two persons mined', async function (){
        let contracts = await migrateTimedMinePool(accounts);
        let nowId = await contracts.minePool.getCurrentPeriodID();
        assert.equal(nowId.toNumber(),1,"getCurrentPeriodID Error");
        await contracts.minePool.stakeFPTA(100000);
        await contracts.minePool.stakeFPTB(100000,12);
        await contracts.minePool.setMineCoinInfo(contracts.MINE.address,1234567,1);
        await contracts.minePool.stakeFPTA(100000,{from:accounts[1]});
        await contracts.minePool.stakeFPTB(100000,12,{from:accounts[1]});
        let userPeriodId = await contracts.minePool.getUserMaxPeriodId(accounts[0]);
        assert.equal(userPeriodId.toNumber(),nowId.toNumber()+11,"getUserMaxPeriodId Error");
        await contracts.minePool.setTime(2100);
        mineBalance = await contracts.minePool.getMinerBalance(accounts[0],contracts.MINE.address);
        console.log("getMinerBalance : ",mineBalance.toNumber())
        let tx = await contracts.minePool.redeemMinerCoin(contracts.MINE.address,mineBalance);
        console.log(tx);
        mineBalance = await contracts.minePool.getMinerBalance(accounts[0],contracts.MINE.address);
        assert.equal(mineBalance.toNumber(),0,"getMinerBalance error");
        await contracts.minePool.setTime(4200);
        mineBalance = await contracts.minePool.getMinerBalance(accounts[0],contracts.MINE.address);
        console.log("getMinerBalance : ",mineBalance.toNumber())
        tx = await contracts.minePool.redeemMinerCoin(contracts.MINE.address,mineBalance);
        mineBalance = await contracts.minePool.getMinerBalance(accounts[0],contracts.MINE.address);
        assert.equal(mineBalance.toNumber(),0,"getMinerBalance error");
    });
    
});