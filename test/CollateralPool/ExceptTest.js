const BN = require("bn.js");
const assert = require('assert');
let month = 10;
let ETH = "0x0000000000000000000000000000000000000000";
let {migration ,createAndAddErc20,createAndAddUSDC,AddCollateral0} = require("../testFunction.js");
contract('OptionsManagerV2', function (accounts) {
    let contracts;
    let ethAmount = new BN("10000000000000000000");
    let usdcAmount = 10000000000;

    let payamount = new BN("100000000000000000000");
    let optamount = new BN("2000000000000000000");

    let FNXAmount =  new BN("100000000000000000000");;
    before(async () => {
        contracts = await migration(accounts);
        await AddCollateral0(contracts);
        await createAndAddErc20(contracts);
        await createAndAddUSDC(contracts);
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
        assert.equal(diffUser.toNumber(),usdcAmount,"user usdc balance error");
        assert.equal(diffUser.toNumber(),diffContract.toNumber(),"manager usdc balance error");

        let isExcept = false;
        preBalanceUser0 =await  contracts.USDC.balanceOf(accounts[0]);
        preBalanceContract =await  contracts.USDC.balanceOf(contracts.collateral.address);
        let result = await contracts.FPT.balanceOf(accounts[0]);

        try {
            tx = await contracts.manager.redeemCollateral(result + 1, contracts.FNX.address);
            isExcept = false;
        }catch(e){
           // console.log(e);
            assert.equal(e.reason.toString(),'SCoin balance is insufficient!');
            isExcept = true;
        }

        assert.equal(isExcept,true);

    })

    it('FNX input and redeem', async function () {
        await contracts.FNX.approve(contracts.manager.address, FNXAmount);
        let preBalanceUser0 =await  contracts.FNX.balanceOf(accounts[0]);
        let preBalanceContract =await  contracts.FNX.balanceOf(contracts.collateral.address);
        let tx = await contracts.manager.addCollateral(contracts.FNX.address, FNXAmount);
        assert.equal(tx.receipt.status,true);
        let afterBalanceUser0 =await  contracts.FNX.balanceOf(accounts[0]);
        let afterBalanceContract =await  contracts.FNX.balanceOf(contracts.collateral.address);
        let diffUser = preBalanceUser0.sub(afterBalanceUser0);
        let diffContract = afterBalanceContract.sub(preBalanceContract);
        assert.equal(diffUser.toString(10),FNXAmount.toString(10),"user FNX balance error");
        assert.equal(diffUser.toString(10),diffContract.toString(10),"manager FNX balance error");

        let isExcept = false;
        preBalanceUser0 =await  contracts.FNX.balanceOf(accounts[0]);
        preBalanceContract =await  contracts.FNX.balanceOf(contracts.collateral.address);
        let result = await contracts.FPT.balanceOf(accounts[0]);

        try {
            tx = await contracts.manager.redeemCollateral(result + 1, contracts.FNX.address);
            isExcept = false;
        }catch(e){
            // console.log(e);
            assert.equal(e.reason.toString(),'SCoin balance is insufficient!');
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


        let tx = await contracts.manager.addCollateral(ETH,ethAmount,{from:accounts[0],value:ethAmount});
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
        let result = await contracts.FPT.balanceOf(accounts[0]);

        try {
            tx = await contracts.manager.redeemCollateral(result + 1, contracts.FNX.address);
            isExcept = false;
        }catch(e){
           // console.log(e);
            assert.equal(e.reason.toString(),'SCoin balance is insufficient!');
            isExcept = true;
        }

        assert.equal(isExcept,true);
    })

})