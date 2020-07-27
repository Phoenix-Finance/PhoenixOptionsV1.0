const OptionsPoolTest = artifacts.require("OptionsPoolTest");
contract('OptionsPoolTest', function (accounts){
    it('OptionsPoolTest add collateral', async function (){
        let optionsInstance = await OptionsPoolTest.deployed();
        console.log("call option : value = max(strike price,underlying price)");
        console.log("call option : payback = max(strike price,underlying price) - strike price");
        for (var i= 5000;i<8000;i+=500){
            for (var j= 5000;j<8000;j+=500){
                let worth = await optionsInstance.getOptionsWorth(0,i,j);
                let expect = Math.max(i,j);
                assert.equal(worth,expect,"call option : value are not equal")
                worth = await optionsInstance.getOptionsPayback(0,i,j);
                let payback = expect - i;
                assert.equal(worth,payback,"call option : value are not equal")
            }
        }
        console.log("pull option : value = min(strike price,underlying price)");
        console.log("pull option : payback = strike price - min(strike price,underlying price)");
        for (var i= 5000;i<8000;i+=500){
            for (var j= 5000;j<8000;j+=500){
                let worth = await optionsInstance.getOptionsWorth(1,i,j);
                let expect = Math.min(i,j);
                assert.equal(worth,expect,"pull option : value are not equal")
                worth = await optionsInstance.getOptionsPayback(1,i,j);
                let payback = i - expect;
                assert.equal(worth,payback,"pull option : value are not equal")
            }
        }
    })
})