let OptionsPrice = artifacts.require("OptionsPrice");
//let OptionsPrice = artifacts.require("OptionsPrice");
let newOptionsPriceTest = artifacts.require("newOptionsPriceTest");
let month = 30*60*60*24;
let day = 60*60*24;
let testFunc = require("./testFunction.js")
const ImpliedVolatility = artifacts.require("ImpliedVolatility");
contract('OptionsPrice', function (accounts){
    // it('OptionsPrice Call options', async function (){
    //     let priceInstance = await OptionsPrice.new();
    //     let testInstance = await newOptionsPriceTest.new();
    //     let tx = await testInstance.testNew(priceInstance.address);
    //     console.log(tx.receipt.gasUsed);
    //     let iv = await ImpliedVolatility.deployed();
    //     let oldPrice = await OptionsPrice.new(iv.address);
    //     tx = await testInstance.testOld(oldPrice.address);
    //     console.log(tx.receipt.gasUsed);
    // });
    // return;
    it('OptionsPrice Call options', async function (){
        let volInstance = await ImpliedVolatility.new();
        let priceInstance = await OptionsPrice.new(volInstance.address);
        for (var i=1000;i<10000;i+=1000){
            for (j=1000;j<10000;j+=1000){
                let price0 = await priceInstance.getOptionsPrice(i*1e8, j*1e8, month,1,0);
                price1 = await priceInstance.getOptionsPrice(i*1e8, j*1e8, month,1,1);
                console.log(i,j,price0.toString(10),price1.toString(10));
            }
        }

    });

});