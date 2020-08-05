const ImpliedVolatility = artifacts.require("ImpliedVolatility");
let testFunc = require("./testFunction.js");
const BN = require("bn.js");
let daySeconds = 24*3600;
contract('ImpliedVolatility', function (accounts){
    it('ImpliedVolatility test iv', async function (){
        let volInstance = await ImpliedVolatility.deployed();
        let price = new BN(1);
        price = price.ushln(100);
        await calculateIv(volInstance,10,9000*1e8,11000*1e8);
    });
});
async function calculateIv(volInstance,expiration,curprice,strikePrice){
    let iv = await volInstance.calculateIv(1,0,expiration,curprice,strikePrice);
    console.log(iv[0].toNumber()/iv[1].toNumber());
}