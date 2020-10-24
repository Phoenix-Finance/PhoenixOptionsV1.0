const BN = require("bn.js");
const assert = require('assert');
let month = 10;
let collateral0 = "0x0000000000000000000000000000000000000000";
let {migration ,createAndAddErc20,createAndAddUSDC,AddCollateral0} = require("./testFunction.js");
contract('OptionsManagerV2', function (accounts) {
    let contracts;
    let amount = new BN("10000000000000000000000");
    let usdcAmount = 10000000000;

    let payamount = new BN("100000000000000000000");
    let optamount = new BN("2000000000000000000");

    before(async () => {
        contracts = await migration(accounts);
        await AddCollateral0(contracts);
        await createAndAddErc20(contracts);
        await createAndAddUSDC(contracts);
        await contracts.price.setExpirationZoom(1000);
        contracts.options.addExpiration(month);
        await contracts.FPT.setTimeLimitation(3);
    });

    it('USDC input and redeem', async function () {
        await contracts.USDC.approve(contracts.manager.address, usdcAmount);
        let preBalanceUser0 =await  contracts.USDC.balanceOf(accounts[0]);
        let preBalanceContract =await  contracts.USDC.balanceOf(contracts.manager.address);
        await contracts.USDC.approve(contracts.manager.address, usdcAmount);
        let tx = await contracts.manager.addCollateral(contracts.USDC.address, usdcAmount);
        assert.equal(tx.receipt.status,true);
        let afterBalanceUser0 =await  contracts.USDC.balanceOf(accounts[0]);
        let afterBalanceContract =await  contracts.USDC.balanceOf(contracts.manager.address);
        let diffUser = preBalanceUser0 - afterBalanceUser0;
        let diffContract = afterBalanceContract - preBalanceContract;
        assert.equal(diffUser,usdcAmount);
        assert.equal(diffUser,diffContract);

        preBalanceUser0 =await  contracts.USDC.balanceOf(accounts[0]);
        preBalanceContract =await  contracts.USDC.balanceOf(contracts.manager.address);
        await contracts.USDC.approve(contracts.manager.address, optamount);
        await contracts.manager.buyOption(contracts.USDC.address, payamount, 9000e8, 1, month, optamount, 0);
        afterBalanceUser0 =await  contracts.USDC.balanceOf(accounts[0]);
        afterBalanceContract =await  contracts.USDC.balanceOf(contracts.manager.address);
        diffUser = preBalanceUser0 - afterBalanceUser0;
        diffContract = afterBalanceContract - preBalanceContract;
        assert.equal(diffUser,optamount);
        assert.equal(diffUser,diffContract);


        preBalanceUser0 =await  contracts.USDC.balanceOf(accounts[0]);
        preBalanceContract =await  contracts.USDC.balanceOf(contracts.manager.address);
        await contracts.manager.redeemCollateral(amount,contracts.FNX.address);
        afterBalanceUser0 =await  contracts.USDC.balanceOf(accounts[0]);
         afterBalanceContract =await  contracts.USDC.balanceOf(contracts.manager.address);
        diffUser = preBalanceUser0 - afterBalanceUser0;
        diffContract = afterBalanceContract - preBalanceContract;
        assert.equal(diffUser,usdcAmount);
        assert.equal(diffUser,diffContract);

    })

})