const imVolatility32 = artifacts.require("imVolatility32");
let testFunc = require("./testFunction.js")
contract('imVolatilityTest', function (accounts){
    it('imVolatilityTest add IvMap', async function (){
        let volInstance = await imVolatility32.deployed();
        await testFunc.AddImpliedVolatility(volInstance,true);
    });
});
