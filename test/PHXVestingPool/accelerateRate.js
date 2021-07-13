let createFactory = require("../optionsFactory/optionsFactory.js");
//const minePoolProxy = artifacts.require("MinePoolProxy");
//const minePool = artifacts.require("FNXMinePool");
//const Erc20Proxy = artifacts.require("Erc20Proxy");
const PHXCoin = artifacts.require("PHXCoin");
const PHXVestingPool = artifacts.require("PHXVestingPool");
const acceleratedMinePool = artifacts.require("acceleratedMinePool");
let collateral0 = "0x0000000000000000000000000000000000000000";
const BN = require("bn.js");
contract('PHXVestingPool', function (accounts){
    it('PHXVestingPool accelerate Rate calculate', async function (){
        let owners = [accounts[1],accounts[2],accounts[3],accounts[4],accounts[5]] 
        let factory = await createFactory.createTestFactory(accounts[0],owners)
        let vesting =  await factory.optionsFactory.vestingPool();
        let vestingPool = await PHXVestingPool.at(vesting);
        let baseNum = new BN("100000000000000000000");
        await outputRates(25,vestingPool);
        await outputRates(50,vestingPool);
        await outputRates(100,vestingPool);
        await outputRates(250,vestingPool);
        await outputRates(500,vestingPool);
        await outputRates(1000,vestingPool);
        await outputRates(2000,vestingPool);
        await outputRates(5000,vestingPool);
        await outputRates(10000,vestingPool);
        await outputRates(20000,vestingPool);
    })
    return
    it('PHXVestingPool accelerate Rate calculate', async function (){
        let owners = [accounts[1],accounts[2],accounts[3],accounts[4],accounts[5]] 
        let factory = await createFactory.createTestFactory(accounts[0],owners)
        let vesting =  await factory.optionsFactory.vestingPool();
        let vestingPool = await PHXVestingPool.at(vesting);
        for (var i=1;i<11;i++){
            await outputRates(i,vestingPool);
        }

    })
})
async function outputRates(i,vestingPool){
    let baseNum = new BN("100000000000000000000");
    let results = await vestingPool.calculateAccelerateRates(baseNum.muln(i),36,1);
    let text = i + "00 ,";
    for (var j=0;j<36;j++){
        text += results[j].toString(10) + ",";
    }
    console.log(text)
}