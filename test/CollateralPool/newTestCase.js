let IERC20 = artifacts.require("IERC20");
let USDT = artifacts.require("USDTCoin");
let {migration ,createAndAddErc20,createAndAddUSDC,AddCollateral0} = require("../testFunction.js");
contract('OptionsManagerV2', function (accounts) {
    let usdcAmount = 10000000000;
    it('USDT input ', async function () {
        let contracts = await migration(accounts);
        await createAndAddErc20(contracts);
        await createAndAddUSDC(contracts);
        let usdt = await USDT.new();
        await usdt.approve(contracts.manager.address, usdcAmount);
        let preBalanceUser0 =await  usdt.balanceOf(accounts[0]);
        let preBalanceContract =await  usdt.balanceOf(contracts.collateral.address);
        //await USDT.approve(contracts.manager.address, usdcAmount);
        await contracts.manager.setCollateralRate(usdt.address,1200);
    })
})