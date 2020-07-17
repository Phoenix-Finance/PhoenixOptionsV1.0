const OptionsPrice = artifacts.require("OptionsPriceTest");
let month = 30*60*60*24;
contract('OptionsPrice', function (accounts){
    it('OptionsPrice Call options', async function (){
        let priceInstance = await OptionsPrice.deployed();;
        for (var i=5000;i<13000;i+=500){
            for (j=5000;j<13000;j+=500){
                let price = await priceInstance.getOptionsPrice_iv(i*1e8, j*1e8, month,5,10,1);
                console.log(i,j,price.toString(10));
            }
        }

    });
});