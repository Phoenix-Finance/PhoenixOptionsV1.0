const ImpliedVolatility = artifacts.require("ImpliedVolatility");
let testFunc = require("./testFunction.js");
const BN = require("bn.js");
let daySeconds = 24*3600;
contract('ImpliedVolatility', function (accounts){
    it('ImpliedVolatility test iv', async function (){
        let volInstance = await ImpliedVolatility.new();
        for (i =5000;i<=20000;i+=100){
            await calculateIv(volInstance,3600,i,10000);
        }
    });
});
async function calculateIv(volInstance,expiration,curprice,strikePrice){
    let iv = await volInstance.calculateIv(1,0,expiration,curprice,strikePrice);
    console.log(iv.toNumber()/4294967296);
}