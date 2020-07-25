let OptionsPrice = artifacts.require("OptionsPrice");
const imVolatility32 = artifacts.require("imVolatility32");
let month = 30*60*60*24;
let testFunc = require("./testFunction.js")
contract('OptionsPrice', function (accounts){
    it('OptionsPrice Call options', async function (){
        let volInstance = await imVolatility32.deployed();
        await testFunc.AddImpliedVolatility(volInstance,false);
        let priceInstance = await OptionsPrice.deployed();
        let price = await priceInstance.getOptionsPrice(931703000000, 951703000000, month,1,0);
        for (var i=5000;i<13000;i+=2000){
            for (j=5000;j<13000;j+=2000){
                let price = await priceInstance.getOptionsPrice(i*1e8, j*1e8, month,1,0);
                console.log(i,j,price.toString(10));
                price = await priceInstance.getOptionsPrice(i*1e8, j*1e8, month,1,1);
                console.log(i,j,price.toString(10));
            }
        }

    });
});