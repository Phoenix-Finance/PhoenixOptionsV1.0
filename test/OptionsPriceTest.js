let OptionsPrice = artifacts.require("OptionsPrice");
const ImpliedVolatility = artifacts.require("ImpliedVolatility");
let month = 30*60*60*24;
let day = 60*60*24;
let testFunc = require("./testFunction.js")
contract('OptionsPrice', function (accounts){
    it('OptionsPrice Call options', async function (){
        let priceInstance = await OptionsPrice.deployed();
        for (var i=23000;i<2300000;i+=20000){
            for (j=500;j<23000;j+=2000){
//                let price = await priceInstance.getOptionsPrice(i*1e8, j*1e8, day,1,0);
//                console.log(i,j,price.toString(10));
                price = await priceInstance.getOptionsPrice(i*1e8, j*1e8, day,1,1);
                console.log(i,j,price.toString(10));
                break;
            }
        }

    });
});