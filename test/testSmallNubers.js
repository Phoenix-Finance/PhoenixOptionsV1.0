const BN = require("bn.js");
let testSmallNumbers = artifacts.require("testSmallNumbers");
contract('testSmallNumbers', function (accounts){
    it('testSmallNumbers testing', async function (){
        let small = await testSmallNumbers.new();
        let exp = new BN(1);
        exp = exp.shln(32)/-32;
        for (var i=0;i<32;i++){
            let result = await small.testNormSDist(exp*i);
            console.log(result.toString(10))
        }
    })
})