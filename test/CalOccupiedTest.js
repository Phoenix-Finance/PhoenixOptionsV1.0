let createFactory = require("./optionsFactory/optionsFactory.js");
//const minePoolProxy = artifacts.require("MinePoolProxy");
//const minePool = artifacts.require("FNXMinePool");
//const Erc20Proxy = artifacts.require("Erc20Proxy");
const PHXCoin = artifacts.require("PHXCoin");
const USDCoin = artifacts.require("USDCoin");
const OptionsPool = artifacts.require("OptionsPool");
const CollateralPool = artifacts.require("CollateralPool");
const PHXVestingPool = artifacts.require("PHXVestingPool");
let collateral0 = "0x0000000000000000000000000000000000000000";
const BN = require("bn.js");
let month = 30*60*60*24;
contract('OptionsManagerV2', function (accounts){
    it('OptionsManagerV2 add collateral', async function (){
        let owners = [accounts[1],accounts[2],accounts[3],accounts[4],accounts[5]];
        let factory = await createFactory.createFactory(accounts[0],owners)
        let phx = await PHXCoin.new();
        let usdc = await USDCoin.new();
        let contracts = await createFactory.createOptionsManager(factory,accounts[0],owners,
            [collateral0,usdc.address,phx.address],[1500,1200,5000],[1,2]);
        contracts.USDC = usdc;
        contracts.phx =phx;
        await factory.oracle.setOperator(3,accounts[1]);
        await createFactory.multiSignatureAndSend(factory.multiSignature,contracts.options,"setOperator",accounts[0],owners,1,accounts[0]);
        await createFactory.multiSignatureAndSend(factory.multiSignature,contracts.collateral,"setOperator",accounts[0],owners,1,accounts[0]);
        let price = new BN("10000000000000000000");
        await factory.oracle.setPrice(usdc.address,price,{from:accounts[1]});
        await factory.oracle.setPrice(phx.address,1e7,{from:accounts[1]});
        await factory.oracle.setPrice(collateral0,2e11,{from:accounts[1]});
        await factory.oracle.setUnderlyingPrice(1,10000e8,{from:accounts[1]});
        await factory.oracle.setUnderlyingPrice(2,2000e8,{from:accounts[1]});
        await createFactory.multiSignatureAndSend(factory.multiSignature,contracts.options,"setTimeLimitation",
            accounts[0],owners,0);      
        let mineInfo = await contracts.mine.getMineInfo(collateral0);
        console.log (mineInfo);
        mineInfo = await contracts.mine.getMineInfo(contracts.phx.address);
        console.log (mineInfo);
        for (var i=0;i<3;i++){
            for (var j=0;j<2;j++){
                contracts.manager.addCollateral(collateral0,1000000000000000,{value : 1000000000000000});
                contracts.manager.addCollateral(collateral0,1000000000000000,{value : 1000000000000000});
                contracts.manager.addCollateral(collateral0,1000000000000000,{value : 1000000000000000});
                contracts.manager.addCollateral(collateral0,1000000000000000,{value : 1000000000000000});
                contracts.manager.buyOption(collateral0,1000000000000000,9150*1e8,1,month,10000000000,0,{value : 1000000000000000});
                contracts.manager.buyOption(collateral0,1000000000000000,8250*1e8,1,month,10000000000,0,{value : 1000000000000000});
                contracts.manager.buyOption(collateral0,1000000000000000,9257*1e8,1,month,10000000000,0,{value : 1000000000000000});
                contracts.manager.buyOption(collateral0,1000000000000000,9251*1e8,1,month,10000000000,0,{value : 1000000000000000});
                contracts.manager.buyOption(collateral0,1000000000000000,11250*1e8,1,month,10000000000,0,{value : 1000000000000000});
                contracts.manager.buyOption(collateral0,1000000000000000,9253*1e8,1,month,10000000000,0,{value : 1000000000000000});
                contracts.manager.buyOption(collateral0,1000000000000000,9260*1e8,1,month,10000000000,0,{value : 1000000000000000});

                contracts.manager.buyOption(collateral0,1000000000000000,11050*1e8,1,month,10000000000,1,{value : 1000000000000000});
                contracts.manager.buyOption(collateral0,1000000000000000,9056*1e8,1,month,10000000000,1,{value : 1000000000000000});
        //        console.log(tx);
                await contracts.manager.buyOption(collateral0,200000000000000,9258*1e8,1,month,10000000000,1,{value : 200000000000000});
        //        console.log(tx);
            }
            await calculateNetWroth(contracts);
        }
     });
    it('OptionsManagerV2 buy options Price test', async function (){
        let owners = [accounts[1],accounts[2],accounts[3],accounts[4],accounts[5]];
        let factory = await createFactory.createFactory(accounts[0],owners)
        let phx = await PHXCoin.new();
        let usdc = await USDCoin.new();
        let contracts = await createFactory.createOptionsManager(factory,accounts[0],owners,
            [collateral0,usdc.address,phx.address],[1500,1200,5000],[1,2]);
        contracts.USDC = usdc;
        contracts.phx =phx;
        await factory.oracle.setOperator(3,accounts[1]);
        await createFactory.multiSignatureAndSend(factory.multiSignature,contracts.options,"setOperator",accounts[0],owners,1,accounts[0]);
        await createFactory.multiSignatureAndSend(factory.multiSignature,contracts.collateral,"setOperator",accounts[0],owners,1,accounts[0]);
        let price = new BN("10000000000000000000");
        await factory.oracle.setPrice(usdc.address,price,{from:accounts[1]});
        await factory.oracle.setPrice(phx.address,1e7,{from:accounts[1]});
        await factory.oracle.setPrice(collateral0,2e11,{from:accounts[1]});
        await factory.oracle.setUnderlyingPrice(1,10000e8,{from:accounts[1]});
        await factory.oracle.setUnderlyingPrice(2,2000e8,{from:accounts[1]});    
        let mineInfo = await contracts.mine.getMineInfo(collateral0);
        console.log (mineInfo);
        mineInfo = await contracts.mine.getMineInfo(phx.address);
        console.log (mineInfo);

        contracts.manager.addCollateral(collateral0,1000000000000000,{value : 1000000000000000});
        contracts.manager.addCollateral(collateral0,1000000000000000,{value : 1000000000000000});
        contracts.manager.addCollateral(collateral0,1000000000000000,{value : 1000000000000000});
        contracts.manager.addCollateral(collateral0,1000000000000000,{value : 1000000000000000});
        contracts.manager.buyOption(collateral0,1000000000000000,9150*1e8,1,month,10000000000,0,{value : 1000000000000000});
        contracts.manager.buyOption(collateral0,1000000000000000,9150*1e8,1,month,10000000000,0,{value : 1000000000000000});
        contracts.manager.buyOption(collateral0,1000000000000000,9150*1e8,1,month,10000000000,0,{value : 1000000000000000});
        contracts.manager.buyOption(collateral0,1000000000000000,9150*1e8,1,month,10000000000,0,{value : 1000000000000000});
        contracts.manager.buyOption(collateral0,1000000000000000,9150*1e8,1,month,10000000000,0,{value : 1000000000000000});
        contracts.manager.buyOption(collateral0,1000000000000000,9150*1e8,1,month,10000000000,0,{value : 1000000000000000});
        contracts.manager.buyOption(collateral0,1000000000000000,9150*1e8,1,month,10000000000,0,{value : 1000000000000000});

        contracts.manager.buyOption(collateral0,1000000000000000,9150*1e8,1,month,10000000000,1,{value : 1000000000000000});
        contracts.manager.buyOption(collateral0,1000000000000000,9150*1e8,1,month,10000000000,1,{value : 1000000000000000});
//        console.log(tx);
        await contracts.manager.buyOption(collateral0,200000000000000,9150*1e8,1,month,10000000000,1,{value : 200000000000000});
//        console.log(tx);

    await calculateNetWroth(contracts);

     });
});
async function calculateNetWroth(contracts){
    let whiteList = [collateral0,contracts.USDC.address,contracts.phx.address];
    optionsLen = await contracts.options.getOptionCalRangeAll(whiteList);
    console.log(optionsLen[0].toString(10),optionsLen[1].toString(10));
    console.log(optionsLen[0].toString(10),optionsLen[1].toString(10),optionsLen[2].toString(10),optionsLen[4].toString(10));
    let result =  await contracts.options.calculatePhaseOccupiedCollateral(optionsLen[5],optionsLen[0],optionsLen[5]);
    console.log(result[0].toString(10),result[1].toString(10));
    let tx = await contracts.options.setOccupiedCollateral();
    result =  await contracts.options.calRangeSharedPayment(optionsLen[5],optionsLen[3],optionsLen[5],whiteList);
    console.log(result[0][0].toString(10),result[0][1].toString(10));
    tx = await contracts.collateral.calSharedPayment(whiteList);
    console.log(tx);
}