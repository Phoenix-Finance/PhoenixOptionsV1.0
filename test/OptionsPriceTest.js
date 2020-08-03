let OptionsPrice = artifacts.require("OptionsPrice");
const imVolatility32 = artifacts.require("imVolatility32");
let month = 30*60*60*24;
let testFunc = require("./testFunction.js")
contract('OptionsPrice', function (accounts){
    it('OptionsPrice Call options', async function (){
        let volInstance = await imVolatility32.deployed();
        await testFunc.AddImpliedVolatility(volInstance,false);
        let priceInstance = await OptionsPrice.deployed();
        for (var i= 10;i<1000;i+=10){
            let price0 = await priceInstance.getOptionsPrice(11000*1e8, 9000*1e8, i,1,0);
            let price1 = await priceInstance.getOptionsPrice(11000*1e8, 11000*1e8, i,1,0);
            let price2 = await priceInstance.getOptionsPrice(11000*1e8, 13000*1e8, i,1,0);
            console.log(price0.toString(10),price1.toString(10),price2.toString(10))
        }
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