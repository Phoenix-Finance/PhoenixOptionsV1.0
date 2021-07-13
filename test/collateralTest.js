
const BN = require("bn.js");
let month = 30*60*60*24;
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
contract('OptionsManagerV2', function (accounts){
    it('OptionsManagerV2 redeem collateral', async function (){
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
        await createFactory.multiSignatureAndSend(factory.multiSignature,contracts.ppt,"setTimeLimitation",
        accounts[0],owners,0);
        let price = new BN("10000000000000000000");
        await factory.oracle.setPrice(usdc.address,price,{from:accounts[1]});
        await factory.oracle.setPrice(phx.address,5e9,{from:accounts[1]});
        await factory.oracle.setPrice(collateral0,2e11,{from:accounts[1]});
        await factory.oracle.setUnderlyingPrice(1,10000e8,{from:accounts[1]});
        await factory.oracle.setUnderlyingPrice(2,2000e8,{from:accounts[1]});
        await contracts.phx.approve(contracts.manager.address,10000000000000);
        await contracts.manager.addCollateral(contracts.phx.address,10000000000000);
        await logBalance(contracts.phx,contracts.collateral.address);
        await logBalance(contracts.phx,accounts[0]);
        let balance = await contracts.ppt.balanceOf(accounts[0]);
        console.log("ppt balance : ",balance.toString())
        for (var i=0;i<10;i++){
                await createFactory.multiSignatureAndSend(factory.multiSignature,contracts.options,"setOperator",accounts[0],owners,1,accounts[0]);
        }
        await contracts.manager.redeemCollateral(500000000000000,collateral0);
        await logBalance(contracts.phx,contracts.collateral.address);
        await logBalance(contracts.phx,accounts[0]);
        await contracts.manager.addCollateral(collateral0,10000000000000,{value:10000000000000});
        await logBalance(contracts.phx,contracts.collateral.address);
        await logBalance(contracts.phx,accounts[0]);
        for (var i=0;i<10;i++){
                await createFactory.multiSignatureAndSend(factory.multiSignature,contracts.options,"setOperator",accounts[0],owners,1,accounts[0]);
        }
        await contracts.manager.redeemCollateral(500000000000000,contracts.phx.address);
        await logBalance(contracts.phx,contracts.collateral.address);
        await logBalance(contracts.phx,accounts[0]);
        await contracts.phx.approve(contracts.manager.address,10000000000000);
        await contracts.manager.addCollateral(contracts.phx.address,10000000000000);
        await logBalance(contracts.phx,contracts.collateral.address);
        await logBalance(contracts.phx,accounts[0]);
        for (var i=0;i<10;i++){
                await createFactory.multiSignatureAndSend(factory.multiSignature,contracts.options,"setOperator",accounts[0],owners,1,accounts[0]);
        }
        await contracts.manager.redeemCollateral(500000000000000,collateral0);
        await logBalance(contracts.phx,contracts.collateral.address);
        await logBalance(contracts.phx,accounts[0]);
        await contracts.manager.addCollateral(collateral0,10000000000000,{value:10000000000000});
        await logBalance(contracts.phx,contracts.collateral.address);
        await logBalance(contracts.phx,accounts[0]);
        for (var i=0;i<10;i++){
                await createFactory.multiSignatureAndSend(factory.multiSignature,contracts.options,"setOperator",accounts[0],owners,1,accounts[0]);
        }
        await contracts.manager.redeemCollateral(500000000000000,contracts.phx.address);
        await logBalance(contracts.phx,contracts.collateral.address);
        await logBalance(contracts.phx,accounts[0]);
        
    });
    it('OptionsManagerV2 add collateral and mine', async function (){
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
        await createFactory.multiSignatureAndSend(factory.multiSignature,contracts.ppt,"setTimeLimitation",
        accounts[0],owners,0);
        await createFactory.multiSignatureAndSend(factory.multiSignature,contracts.mine,"setMineCoinInfo",accounts[0],owners,
                collateral0,1000000,2);
        await createFactory.multiSignatureAndSend(factory.multiSignature,contracts.mine,"setMineCoinInfo",accounts[0],owners,
                phx.address,2000000,2);
        let price = new BN("10000000000000000000");
        await factory.oracle.setPrice(usdc.address,price,{from:accounts[1]});
        await factory.oracle.setPrice(phx.address,1e7,{from:accounts[1]});
        await factory.oracle.setPrice(collateral0,2e11,{from:accounts[1]});
        await factory.oracle.setUnderlyingPrice(1,10000e8,{from:accounts[1]});
        await factory.oracle.setUnderlyingPrice(2,2000e8,{from:accounts[1]});

        await web3.eth.sendTransaction({from:accounts[0],to:contracts.mine.address,value:9e18});
        await contracts.phx.transfer(contracts.mine.address,new BN("100000000000000000000",10));
        await contracts.manager.addCollateral(collateral0,10000000000000,{value : 10000000000000});
        let minebalance = await contracts.mine.getMinerBalance(accounts[0],collateral0);
        console.log(33333333333333,minebalance.toString(10));
        minebalance = await contracts.mine.getMinerBalance(accounts[0],contracts.phx.address);
        console.log(33333333333333,minebalance.toString(10));
        for (var i=0;i<20;i++){
            await createFactory.multiSignatureAndSend(factory.multiSignature,contracts.options,"setOperator",accounts[0],owners,1,accounts[0]);
        }
        await logBalance(contracts.phx,contracts.collateral.address);
        await contracts.manager.addCollateral(collateral0,1000000000000000,{from : accounts[1],value : 1000000000000000});
        minebalance = await contracts.mine.getMinerBalance(accounts[0],collateral0);
        console.log(33333333333333,minebalance.toString(10));
        minebalance = await contracts.mine.getMinerBalance(accounts[0],contracts.phx.address);
        console.log(33333333333333,minebalance.toString(10));
        await contracts.ppt.transfer(accounts[2],200000000000000);
        minebalance = await contracts.mine.getMinerBalance(accounts[2],contracts.phx.address);
        console.log(555555,minebalance.toString(10));
        for (var i=0;i<20;i++){
                await createFactory.multiSignatureAndSend(factory.multiSignature,contracts.options,"setOperator",accounts[0],owners,1,accounts[0]);
            }
        await logBalance(contracts.phx,contracts.collateral.address);
        await contracts.phx.approve(contracts.manager.address,1000000000000000);
        await contracts.manager.addCollateral(contracts.phx.address,1000000000000000);
        await logBalance(contracts.phx,contracts.collateral.address);
        let result = await contracts.options.getTotalOccupiedCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getTotalCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getOccupiedCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getLeftCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getTokenNetworth();
        console.log("1-----------------------------------",result.toString(10));

        minebalance = await contracts.mine.getMinerBalance(accounts[0],collateral0);
        console.log(33333333333333,minebalance.toString(10));
        minebalance = await contracts.mine.getMinerBalance(accounts[0],contracts.phx.address);
        console.log(33333333333333,minebalance.toString(10));
        minebalance = await contracts.mine.getMinerBalance(accounts[1],collateral0);
        console.log(44444444444444,minebalance.toString(10));
        minebalance = await contracts.mine.getMinerBalance(accounts[1],contracts.phx.address);
        console.log(44444444444444,minebalance.toString(10));
        minebalance = await contracts.mine.getMinerBalance(accounts[2],contracts.phx.address);
        console.log(555555,minebalance.toString(10));
//        contracts.phx.approve(contracts.manager.address,1000000000000000);
//        tx = await contracts.manager.buyOption(contracts.phx.address,1000000000000000,20000000000,1,month,10000000000,0);
//        console.log(tx)
       
        tx = await contracts.manager.buyOption(collateral0,1000000000000000,9000e8,1,month,10000000000,0,{value : 1000000000000000});
//        console.log(tx);
        tx = await contracts.manager.buyOption(collateral0,1000000000000000,9500e8,1,month,10000000000,0,{value : 1000000000000000});
//        console.log(tx);
        tx = await contracts.manager.buyOption(collateral0,200000000000000,8000e8,1,month,10000000000,0,{value : 200000000000000});
//        console.log(tx);
        result = await contracts.options.getTotalOccupiedCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getTotalCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getOccupiedCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getLeftCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getTokenNetworth();
        console.log("2-----------------------------------",result.toString(10));
        result = await contracts.options.getOptionsById(1);
        console.log(result[0].toString(10),result[1],result[2].toString(10),result[3].toString(10),result[4].toString(10),result[5].toString(10),result[6].toString(10));
        result = await contracts.options.getOptionsById(2);
        console.log(result[0].toString(10),result[1],result[2].toString(10),result[3].toString(10),result[4].toString(10),result[5].toString(10),result[6].toString(10));
        result = await contracts.options.getOptionsById(3);
        console.log(result[0].toString(10),result[1],result[2].toString(10),result[3].toString(10),result[4].toString(10),result[5].toString(10),result[6].toString(10));
        for (var i=0;i<20;i++){
            await createFactory.multiSignatureAndSend(factory.multiSignature,contracts.options,"setOperator",accounts[0],owners,1,accounts[0]);
        }
    
//        tx = await contracts.manager.sellOption(1,10000000000);
//        console.log(tx);
//        tx = await contracts.manager.exerciseOption(3,10000000000);
        result = await contracts.options.getOptionsById(1);
        console.log(result[0].toString(10),result[1],result[2].toString(10),result[3].toString(10),result[4].toString(10),result[5].toString(10),result[6].toString(10));
        result = await contracts.options.getOptionsById(2);
        console.log(result[0].toString(10),result[1],result[2].toString(10),result[3].toString(10),result[4].toString(10),result[5].toString(10),result[6].toString(10));
        result = await contracts.options.getOptionsById(3);
        console.log(result[0].toString(10),result[1],result[2].toString(10),result[3].toString(10),result[4].toString(10),result[5].toString(10),result[6].toString(10));
//        console.log(tx);
        result = await contracts.options.getTotalOccupiedCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getTotalCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getOccupiedCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getLeftCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getTokenNetworth();
        console.log("3-----------------------------------",result.toString(10));
        await calculateNetWroth(contracts.options,contracts.collateral,contracts.phx);
        result = await contracts.options.getTotalOccupiedCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getTotalCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getOccupiedCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getLeftCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getTokenNetworth();
        console.log("4-----------------------------------",result.toString(10));
        for (var i=0;i<20;i++){
                await createFactory.multiSignatureAndSend(factory.multiSignature,contracts.options,"setOperator",accounts[0],owners,1,accounts[0]);
        }
    
        await logBalance(contracts.phx,contracts.collateral.address);
        await contracts.manager.redeemCollateral(498500000000000,collateral0);
        await calculateNetWroth(contracts.options,contracts.collateral,contracts.phx);
        await logBalance(contracts.phx,contracts.collateral.address);
        result = await contracts.options.getTotalOccupiedCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getTotalCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getOccupiedCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getLeftCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getTokenNetworth();
        console.log("5-----------------------------------",result.toString(10));
        await contracts.manager.redeemCollateral(498500000000000,contracts.phx.address);
        await logBalance(contracts.phx,contracts.collateral.address);
        await contracts.manager.redeemCollateral(498500000000000,contracts.phx.address,{from:accounts[1]});
        await logBalance(contracts.phx,contracts.collateral.address);
//        await contracts.manager.redeemCollateral(0,contracts.phx.address,{from:accounts[2]});
 //       await logBalance(contracts.phx,contracts.collateral.address);
        result = await contracts.options.getTotalOccupiedCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getTotalCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getOccupiedCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getLeftCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getAvailableCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getTokenNetworth();

        console.log("5-----------------------------------",result.toString(10));
        minebalance = await contracts.mine.getMinerBalance(accounts[0],collateral0);
        console.log(minebalance.toString());
        await contracts.mine.redeemMinerCoin(collateral0);
        minebalance = await contracts.mine.getMinerBalance(accounts[0],collateral0);
        console.log(33333333333333,minebalance.toString(10));
        minebalance = await contracts.mine.getMinerBalance(accounts[0],contracts.phx.address);
        await contracts.mine.redeemMinerCoin(contracts.phx.address);
        minebalance = await contracts.mine.getMinerBalance(accounts[0],contracts.phx.address);
        console.log(33333333333333,minebalance.toString(10));
        minebalance = await contracts.mine.getMinerBalance(accounts[1],collateral0);
        await contracts.mine.redeemMinerCoin(collateral0,{from:accounts[1]});
        minebalance = await contracts.mine.getMinerBalance(accounts[1],collateral0);        
        console.log(44444444444444,minebalance.toString(10));
        minebalance = await contracts.mine.getMinerBalance(accounts[1],contracts.phx.address);
        await contracts.mine.redeemMinerCoin(contracts.phx.address,{from:accounts[1]});
        minebalance = await contracts.mine.getMinerBalance(accounts[1],contracts.phx.address);    
        console.log(44444444444444,minebalance.toString(10));
    });
});
async function logBalance(phx,addr){
        let colBalance = await web3.eth.getBalance(addr);
        console.log("eth : ",addr,colBalance);
        let phxBalance = await phx.balanceOf(addr);
        console.log("phx : ",addr,phxBalance.toString(10));
}
async function calculateNetWroth(options,collateral,fnx){
        let whiteList = [collateral0,fnx.address];
        optionsLen = await options.getOptionCalRangeAll(whiteList);
        console.log(optionsLen[0].toString(10),optionsLen[1].toString(10),optionsLen[2].toString(10),optionsLen[4].toString(10));
        //(occupiedFirst,callOccupiedlatest,putOccupiedlatest,netFirst,netLatest,allOptions.length,block.number
        console.log(optionsLen[0].toString(10),optionsLen[5].toString(10));
        let result =  await options.calculatePhaseOccupiedCollateral(optionsLen[5],optionsLen[0],optionsLen[5]);
        console.log(result[0].toString(10),result[1].toString(10),result[2].toString(10));
        let tx = await options.setOccupiedCollateral();
        result =  await options.calRangeSharedPayment(optionsLen[5],optionsLen[3],optionsLen[5],whiteList);
        console.log(result[0][0].toString(10),result[0][1].toString(10));
    
    //                return;
        tx = await collateral.calSharedPayment(whiteList);
    //    console.log(tx);
    }