let createFactory = require("../optionsFactory/optionsFactory.js");
//const minePoolProxy = artifacts.require("MinePoolProxy");
//const minePool = artifacts.require("FNXMinePool");
//const Erc20Proxy = artifacts.require("Erc20Proxy");
const PHXCoin = artifacts.require("PHXCoin");
const PPTCoin = artifacts.require("PPTCoin");
const acceleratedMinePool = artifacts.require("acceleratedMinePool");
const PHXVestingPool = artifacts.require("PHXVestingPool");
let collateral0 = "0x0000000000000000000000000000000000000000";
const BN = require("bn.js");
contract('PPTCoin', function (accounts){
    it('vestingPool 100 usd functions', async function (){
        await testAcceleratingMinePool(1);
    });
    it('vestingPool 500 usd functions', async function (){
        await testAcceleratingMinePool(5);
    });
    it('vestingPool 1000 usd functions', async function (){
        await testAcceleratingMinePool(10);
    });
    it('vestingPool 10000 usd functions', async function (){
        await testAcceleratingMinePool(100);
    });
    async function testAcceleratingMinePool(stakeNum){
        let owners = [accounts[1],accounts[2],accounts[3],accounts[4],accounts[5]] 
        let factory = await createFactory.createTestFactory(accounts[0],owners)
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
        let vesting =  await factory.optionsFactory.vestingPool();
        let vestingPool = await PHXVestingPool.at(vesting);
        await createFactory.multiSignatureAndSend(factory.multiSignature,vestingPool,"setVestingRate",accounts[0],owners,
            phx.address,1000);
        await createFactory.multiSignatureAndSend(factory.multiSignature,vestingPool,"setVestingRate",accounts[0],owners,
            cphx.address,900);
        await factory.optionsFactory.testSetProxyManager(pptCoin.address,accounts[0]);
        let amount = new BN("10000000000000000000000");
        await pptCoin.mint(accounts[0],amount);
        let baseNum = new BN("100000000000000000000").muln(stakeNum);
        await phx.approve(vestingPool.address,baseNum);
        await vestingPool.stake(phx.address,baseNum,36,minePool.address);
        await pptCoin.mint(accounts[0],amount);
        await phx.approve(vestingPool.address,baseNum);
        await vestingPool.stake(phx.address,baseNum,36,minePool.address);
        await cphx.approve(vestingPool.address,baseNum);
        await vestingPool.stake(cphx.address,baseNum,36,minePool.address);
        let info = await minePool.getUserAccelerateInfo(accounts[0]);
        console.log("getUserAccelerateInfo : ",info[1].toString())
        let result0 = await minePool.getMinerBalance(accounts[0],phx.address);
        let result1 = await minePool.getMinerBalance(accounts[0],collateral0);
        console.log("mine balance(phx,eth): ",result0.toString(),result1.toString())
        result0 = await minePool.getUserCurrentAPY(accounts[0],phx.address);
        result1 = await minePool.getUserCurrentAPY(accounts[0],collateral0);
        console.log("mine APY(phx,eth): ",result0.toString(),result1.toString())
        let curIndex = await minePool.getCurrentPeriodID();
        console.log(curIndex.toString());
        result1 = await minePool.getPeriodWeight(accounts[0],curIndex.toNumber(),36+curIndex.toNumber()-1);
        console.log("mine boosting rate: ",result1.toString())
        await phx.transfer(minePool.address,amount);
        await minePool.send(amount)
        await minePool.redeemMinerCoin(phx.address);
        await minePool.redeemMinerCoin(collateral0);
    }
    return;
 
})