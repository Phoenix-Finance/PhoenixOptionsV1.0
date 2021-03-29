
let FNXUpKeeper = artifacts.require("FNXUpKeeper");
const BN = require("bn.js");
let month = 30*60*60*24;
let collateral0 = "0x0000000000000000000000000000000000000000";
let {migration ,createAndAddErc20,AddCollateral0} = require("../testFunction.js");
//(address _optionsKeeper,address _collateralKeeper,address _managerKeeper,uint256 _updateInterval)
contract('FNXUpKeeper', function (accounts){
    it('FNXUpKeeper test upkeeper', async function (){
        let contracts = await migration(accounts);
        
        await createAndAddErc20(contracts);
        let upkeeper = await FNXUpKeeper.new(contracts.options.address,contracts.collateral.address,contracts.manager.address,10);
        await contracts.options.setOperator(1,upkeeper.address);
        await contracts.collateral.setOperator(0,upkeeper.address);
        await contracts.FNX.approve(contracts.manager.address,1000000000000000);
        await contracts.manager.addCollateral(contracts.FNX.address,1000000000000000);
        await contracts.FNX.approve(contracts.manager.address,2000000000000000);
        let strikePrice =  950000000000;
        let expiration = 24*3600;
        await contracts.manager.buyOption(contracts.FNX.address,1000000000000000,strikePrice,1,expiration,
            100000000000,1);
        let result = await upkeeper.checkUpkeep("0x");
        console.log(result[0]);
        if (result[0]){
            console.log("run keeper",result[1].toString(16));
            let tx = await upkeeper.performUpkeep(result[1]);
            console.log(tx);
        } 
    });
})