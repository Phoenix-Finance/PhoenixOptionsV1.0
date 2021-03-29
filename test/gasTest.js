
const BN = require("bn.js");
let month = 30*60*60*24;
let collateral0 = "0x0000000000000000000000000000000000000000";
let {migration ,createAndAddUSDC,createAndAddErc20,AddCollateral0} = require("./testFunction.js");
contract('OptionsManagerV2', function (accounts){
    it('OptionsManagerV2 buy options gas fee by eth', async function (){
        let contracts = await migration(accounts);
        await AddCollateral0(contracts);
        await createAndAddErc20(contracts);
        await createAndAddUSDC(contracts);
        await contracts.manager.approve(accounts[0],new BN("10000000000000000000000",10));
        await contracts.FNX.approve(contracts.manager.address,10000000000000);
        await contracts.manager.addCollateral(contracts.FNX.address,10000000000000);
        await contracts.USDC.approve(contracts.manager.address,10000000000000);
        await contracts.manager.addCollateral(contracts.USDC.address,10000000000000);
        await contracts.manager.addCollateral(collateral0,10000000000000,{value:10000000000000});
        let price1 = await contracts.manager.getOptionsPrice(9250*1e8,9153*1e8,month,3,0,0);
        console.log(price1.toNumber())
        return
        let tx = await contracts.manager.buyOption(collateral0,10000000000000,9153*1e8,3,month,100000000,0,{value:10000000000000});
        console.log(tx.receipt.gasUsed);
        let curTime = new Date().getTime()/1000+month;
        let result = await contracts.options.getOptionsById(1);
        assert.equal(result[0].toNumber(),1,"optionsID error");   
        assert.equal(result[1],accounts[0],"options owner error");
        assert.equal(result[2],0,"options type error");
        assert.equal(result[3],2,"options underlying error");
        assert((curTime-result[4].toNumber())<20,"options underlying error");
        assert.equal(result[5].toNumber(),9153*1e8,"options strike error");
        assert.equal(result[6].toNumber(),100000000,"options amount error");
        result = await contracts.options.getOptionsExtraById(1);
        assert.equal(result[0],collateral0,"options settlement error");
        assert(Math.abs(result[1].toNumber()-50e8)<1e6,"options tokentime Price error");
        assert(Math.abs(result[2].toNumber()-9250e8)<1e6,"options underlyingPrice error");
        let optionPrice = await contracts.price.getOptionsPrice(9250e8,9153e8,month,2,0);
        assert(Math.abs(result[3].toNumber()-optionPrice.toNumber())<1e6,"options price error");
        let iv = await contracts.iv.calculateIv(2,0,month,9250e8,9153e8);
        assert(Math.abs(result[4].toNumber()-iv.toNumber())<1e6,"options iv error");
        result = await contracts.manager.getALLCollateralinfo(accounts[0]);
        for (var i=0;i<Object.keys(result).length;i++){
            for(var j=0;j<Object.keys(result[i]).length;j++){
                console.log(result[i][j].toString());
            }
        }
        result = await contracts.options.getUserAllOptionInfo(accounts[0]);
        console.log(result);
    });
    it('OptionsManagerV2 buy options gas fee by fnx', async function (){
        let contracts = await migration(accounts);
        await AddCollateral0(contracts);
        await createAndAddErc20(contracts);
        await createAndAddUSDC(contracts);
        await contracts.manager.approve(accounts[0],new BN("10000000000000000000000",10));
        await contracts.FNX.approve(contracts.manager.address,10000000000000);
        await contracts.manager.addCollateral(contracts.FNX.address,10000000000000);
        await contracts.USDC.approve(contracts.manager.address,10000000000000);
        await contracts.manager.addCollateral(contracts.USDC.address,10000000000000);
        await contracts.manager.addCollateral(collateral0,10000000000000,{value:10000000000000});
        await contracts.FNX.approve(contracts.manager.address,10000000000000);
        let tx = await contracts.manager.buyOption(contracts.FNX.address,10000000000000,9153*1e8,1,month,100000000,1);
        console.log(tx.receipt.gasUsed);
        let curTime = new Date().getTime()/1000+month;
        let result = await contracts.options.getOptionsById(1);
        assert.equal(result[0].toNumber(),1,"optionsID error");   
        assert.equal(result[1],accounts[0],"options owner error");
        assert.equal(result[2],1,"options type error");
        assert.equal(result[3],1,"options underlying error");
        assert((curTime-result[4].toNumber())<20,"options underlying error");
        assert.equal(result[5].toNumber(),9153*1e8,"options strike error");
        assert.equal(result[6].toNumber(),100000000,"options amount error");
        result = await contracts.options.getOptionsExtraById(1);
        assert.equal(result[0],contracts.FNX.address,"options settlement error");
        assert(Math.abs(result[1].toNumber()-50e8)<1e6,"options tokentime Price error");
        assert(Math.abs(result[2].toNumber()-9250e8)<1e6,"options underlyingPrice error");
        let optionPrice = await contracts.price.getOptionsPrice(9250e8,9153e8,month,1,1);
        assert(Math.abs(result[3].toNumber()-optionPrice.toNumber())<1e6,"options Price error");
        let iv = await contracts.iv.calculateIv(1,1,month,9250e8,9153e8);
        assert(Math.abs(result[4].toNumber()-iv.toNumber())<1e6,"options iv error");
        result = await contracts.manager.getALLCollateralinfo(accounts[0]);
        for (var i=0;i<Object.keys(result).length;i++){
            for(var j=0;j<Object.keys(result[i]).length;j++){
                console.log(result[i][j].toString());
            }
        }
        result = await contracts.options.getUserAllOptionInfo(accounts[0]);
        console.log(result);
    });

});
