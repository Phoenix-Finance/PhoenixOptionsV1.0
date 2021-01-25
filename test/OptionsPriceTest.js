let OptionsPrice = artifacts.require("OptionsPrice");
const ImpliedVolatility = artifacts.require("ImpliedVolatility");
let month = 30*60*60*24;
let day = 60*60*24;
let testFunc = require("./testFunction.js")
contract('OptionsPrice', function (accounts){
    it('OptionsPrice cal OptionsPriceRatio test', async function (){
        let iv = await ImpliedVolatility.new();
        let priceInstance = await OptionsPrice.new(iv.address);
        let result = await priceInstance.calOptionsPriceRatio(163,163,2150);
        console.log(result.toString(10)/4294967296);
        result = await priceInstance.calOptionsPriceRatio(680,680,1237);
        console.log(result.toString(10)/4294967296);

    });
    return
    it('OptionsPrice Call options', async function (){
        let iv = await ImpliedVolatility.new();
        let priceInstance = await OptionsPrice.new(iv.address);

        for (var i=1000;i<10000;i+=1000){
            for (j=1000;j<10000;j+=1000){
//                let result = await iv.calculateIv(1,0,day,i*1e8, j*1e8);
//                console.log(result[0].toString(10),result[1].toString(10));
//                result = await priceInstance.testCalculateND1ND2_iv(i*1e8, j*1e8,day,result[0],result[1]);
//                console.log(result[0].toString(10),result[1].toString(10),result[2].toString(10),result[3].toString(10));
                let price0 = await priceInstance.getOptionsPrice(i*1e8, j*1e8, day,1,0);
                //console.log(i,j,price.toString(10));
                price1 = await priceInstance.getOptionsPrice(i*1e8, j*1e8, day,1,1);
                console.log(i,j,price0.toString(10),price1.toString(10));
            }
        }

    });
    it('OptionsPrice calOptionsPriceRatio test', async function (){
        let iv = await ImpliedVolatility.new();
        let priceInstance = await OptionsPrice.new(iv.address);
        2,150
        1,237
        for (var i=6000;i<=10000;i+=1000){
            for (var j=10000;j<=100000;j+=10000){
                let result = await priceInstance.calOptionsPriceRatio(i,10000,j);
                console.log(i,j,result.toString(10)/4294967296);
            }
        }

    });
});