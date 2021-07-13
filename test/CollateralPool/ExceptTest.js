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
    let ethAmount = new BN("10000000000000000000");
    let usdcAmount = 10000000000;

    let payamount = new BN("100000000000000000000");
    let optamount = new BN("2000000000000000000");

    let FNXAmount =  new BN("100000000000000000000");
    let owners = [accounts[1],accounts[2],accounts[3],accounts[4],accounts[5]]; 
    before(async () => {

        let factory = await createFactory.createFactory(accounts[0],owners)
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

    it('USDC input and redeem', async function () {
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
        console.log(afterBalanceContract.toNumber(),diffContract.toNumber())
        assert.equal(diffUser.toNumber(),usdcAmount,"user usdc balance error");
        assert.equal(diffUser.toNumber(),diffContract.toNumber(),"manager usdc balance error");

        let isExcept = false;
        preBalanceUser0 =await  contracts.USDC.balanceOf(accounts[0]);
        preBalanceContract =await  contracts.USDC.balanceOf(contracts.collateral.address);
        let result = await contracts.ppt.balanceOf(accounts[0]);

        try {
            tx = await contracts.manager.redeemCollateral(result + 1, contracts.USDC.address);
            isExcept = false;
        }catch(e){
           // console.log(e);
            assert.equal(e.reason.toString(),'PPT Coin balance is insufficient!');
            isExcept = true;
        }

        assert.equal(isExcept,true);

    })
    it('PHX input and redeem', async function () {
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

        let isExcept = false;
        preBalanceUser0 =await  contracts.phx.balanceOf(accounts[0]);
        preBalanceContract =await  contracts.phx.balanceOf(contracts.collateral.address);
        let result = await contracts.ppt.balanceOf(accounts[0]);

        try {
            tx = await contracts.manager.redeemCollateral(result + 1, contracts.phx.address);
            isExcept = false;
        }catch(e){
            // console.log(e);
            assert.equal(e.reason.toString(),'PPT Coin balance is insufficient!');
            isExcept = true;
        }
        assert.equal(isExcept,true);
    })
    it('ETH input and redeem', async function () {
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

        preBalanceUser0 =await  web3.eth.getBalance(accounts[0]);
        preBalanceUser0 = web3.utils.fromWei(preBalanceUser0, "ether");
        preBalanceContract =await  web3.eth.getBalance(contracts.collateral.address);
        preBalanceContract = web3.utils.fromWei(preBalanceContract, "ether");

        let isExcept = false;
        let result = await contracts.ppt.balanceOf(accounts[0]);

        try {
            tx = await contracts.manager.redeemCollateral(result + 1, collateral0);
            isExcept = false;
        }catch(e){
           // console.log(e);
            assert.equal(e.reason.toString(),'PPT Coin balance is insufficient!');
            isExcept = true;
        }

        assert.equal(isExcept,true);
    })

})