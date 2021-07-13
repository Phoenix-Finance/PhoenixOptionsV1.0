let createFactory = require("../optionsFactory/optionsFactory.js");
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
contract('OptionsManagerV2', function (accounts) {
    let contracts;
    let factory;
    let ethAmount = new BN("10000000000000000000");
    let usdcAmount = 10000000000;

    let payamount = new BN("100000000000000000000");
    let optamount = new BN("2000000000000000000");

    let FNXAmount =  new BN("100000000000000000000");
    let owners = [accounts[1],accounts[2],accounts[3],accounts[4],accounts[5]];
    before(async () => {
        factory = await createFactory.createFactory(accounts[0],owners)
        let phx = await PHXCoin.new();
        let usdc = await USDCoin.new();
        contracts = await createFactory.createOptionsManager(factory,accounts[0],owners,
            [collateral0,usdc.address,phx.address],[1500,1200,5000],[1,2]);
        contracts.USDC = usdc;
        contracts.phx =phx;
        await factory.oracle.setOperator(3,accounts[1]);
        let price = new BN("10000000000000000000");
        await factory.oracle.setPrice(usdc.address,price,{from:accounts[1]});
        await factory.oracle.setPrice(phx.address,1e7,{from:accounts[1]});
        await factory.oracle.setPrice(collateral0,2e11,{from:accounts[1]});
    });

    it('USDC input ', async function () {
        await contracts.USDC.approve(contracts.manager.address, usdcAmount);
        let preBalanceUser0 =await  contracts.USDC.balanceOf(accounts[0]);
        let preBalanceContract =await  contracts.USDC.balanceOf(contracts.collateral.address);
        await contracts.USDC.approve(contracts.manager.address, usdcAmount);
        let tx = await contracts.manager.addCollateral(contracts.USDC.address, usdcAmount);
        assert.equal(tx.receipt.status,true);
        let afterBalanceUser0 =await  contracts.USDC.balanceOf(accounts[0]);
        let afterBalanceContract =await  contracts.USDC.balanceOf(contracts.collateral.address);
        let diffUser = preBalanceUser0.sub(afterBalanceUser0);
        let diffContract = afterBalanceContract.sub(preBalanceContract);
        assert.equal(diffUser.toNumber(),usdcAmount,"user usdc balance error");
        assert.equal(diffUser.toNumber(),diffContract.toNumber(),"manager usdc balance error");
    })

    it('FNX input', async function () {
        await contracts.phx.approve(contracts.manager.address, FNXAmount);
        let preBalanceUser0 =await  contracts.phx.balanceOf(accounts[0]);
        let preBalanceContract =await  contracts.phx.balanceOf(contracts.collateral.address);
        let tx = await contracts.manager.addCollateral(contracts.phx.address, FNXAmount);
        assert.equal(tx.receipt.status,true);
        let afterBalanceUser0 =await  contracts.phx.balanceOf(accounts[0]);
        let afterBalanceContract =await  contracts.phx.balanceOf(contracts.collateral.address);
        let diffUser = preBalanceUser0.sub(afterBalanceUser0);
        let diffContract = afterBalanceContract.sub(preBalanceContract);
        assert.equal(diffUser.toString(10),FNXAmount.toString(10),"user FNX balance error");
        assert.equal(diffUser.toString(10),diffContract.toString(10),"manager FNX balance error");

    })

    it('ETH input', async function () {

        let preBalanceUser0 =await  web3.eth.getBalance(accounts[0]);
        preBalanceUser0 = web3.utils.fromWei(preBalanceUser0, "ether");
        let preBalanceContract =await  web3.eth.getBalance(contracts.collateral.address);
        preBalanceContract = web3.utils.fromWei(preBalanceContract, "ether");
        console.log(preBalanceUser0.toString(10));


        let tx = await contracts.manager.addCollateral(collateral0,ethAmount,{from:accounts[0],value:ethAmount});
        assert.equal(tx.receipt.status,true);

        let afterBalanceUser0 =await web3.eth.getBalance(accounts[0]);
        afterBalanceUser0 = web3.utils.fromWei(afterBalanceUser0, "ether");
        let afterBalanceContract =await  web3.eth.getBalance(contracts.collateral.address);
        afterBalanceContract = web3.utils.fromWei(afterBalanceContract, "ether");

        diffUser = preBalanceUser0 - afterBalanceUser0;
        console.log("user lose " + diffUser.toString(10));
        let diffContract = afterBalanceContract - preBalanceContract;
        console.log("contract get " + diffContract.toString(10));

        assert.equal(diffContract.toString(10), web3.utils.fromWei(ethAmount, "ether"),"user ETH balance error");

    })


    it('redeem all', async function () {
        await createFactory.multiSignatureAndSend(factory.multiSignature,contracts.ppt,"setTimeLimitation",accounts[0],owners,0);
        let usdcpreBalanceUser0 =await  contracts.USDC.balanceOf(accounts[0]);
        let usdcpreBalanceContract =await  contracts.USDC.balanceOf(contracts.collateral.address);

        let fnxpreBalanceUser0 =await  contracts.phx.balanceOf(accounts[0]);
        let fnxpreBalanceContract =await  contracts.phx.balanceOf(contracts.collateral.address);

        let ethpreBalanceUser0 =await  web3.eth.getBalance(accounts[0]);
        ethpreBalanceUser0 = web3.utils.fromWei(ethpreBalanceUser0, "ether");
        let ethpreBalanceContract =await  web3.eth.getBalance(contracts.collateral.address);
        ethpreBalanceContract = web3.utils.fromWei(ethpreBalanceContract, "ether");
        console.log(ethpreBalanceUser0.toString(10));

        let result = await contracts.ppt.balanceOf(accounts[0]);
        tx = await contracts.manager.redeemCollateral(result,contracts.phx.address);
        assert.equal(tx.receipt.status,true);


        let usdcafterBalanceUser0 =await  contracts.USDC.balanceOf(accounts[0]);
        let usdcafterBalanceContract =await  contracts.USDC.balanceOf(contracts.collateral.address);
        let usdcdiffUser = usdcafterBalanceUser0.sub(usdcpreBalanceUser0);
        let usdcdiffContract = usdcpreBalanceContract.sub(usdcafterBalanceContract);
        assert.equal(usdcdiffUser.toNumber(),usdcAmount,"user redeem usdc balance error");
        assert.equal(usdcdiffUser.toNumber(),usdcdiffContract.toNumber(),"manager redeem usdc balance error");


        let fnxafterBalanceUser0 =await  contracts.phx.balanceOf(accounts[0]);
        let fnxafterBalanceContract =await  contracts.phx.balanceOf(contracts.collateral.address);
        let fnxdiffUser = fnxafterBalanceUser0.sub(fnxpreBalanceUser0);
        let fnxdiffContract = fnxpreBalanceContract.sub(fnxafterBalanceContract);
        assert.equal(fnxdiffUser.toString(10),FNXAmount.toString(10),"user redeem FNX balance error");
        assert.equal(fnxdiffUser.toString(10),fnxdiffContract.toString(10),"manager redeem FNX balance error");


        let ethafterBalanceUser0 =await web3.eth.getBalance(accounts[0]);
        ethafterBalanceUser0 = web3.utils.fromWei(ethafterBalanceUser0, "ether");
        let ethafterBalanceContract =await  web3.eth.getBalance(contracts.collateral.address);
        ethafterBalanceContract = web3.utils.fromWei(ethafterBalanceContract, "ether");

        let ethdiffUser = ethafterBalanceUser0 - ethpreBalanceUser0;
        let ethdiffContract = ethpreBalanceContract - ethafterBalanceContract;
        console.log("user get"+ethdiffUser.toString(10));
        console.log("contract lose" + ethdiffContract.toString(10));
        assert(ethdiffUser+0.2>web3.utils.fromWei(ethAmount, "ether"),true,"user eth balance error");
        assert.equal(ethdiffContract.toString(10), web3.utils.fromWei(ethAmount, "ether"),"contract ETH balance error");
    })

})