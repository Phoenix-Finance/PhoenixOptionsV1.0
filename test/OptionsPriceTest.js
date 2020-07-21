let OptionsPrice = artifacts.require("OptionsPriceTest");
let month = 30*60*60*24;
contract('OptionsPrice', function (accounts){
    it('OptionsPrice Call options', async function (){
        let priceInstance = await OptionsPrice.deployed();
        for (var i=47527142;i<47527200;i++){
            console.log(i);
            let price = await priceInstance.getOptionsPrice_ivTwice(925000000000, 925000000000,i,47527142,100000000,0);
        }      
        return;
      
        for (var i=5000;i<13000;i+=2000){
            for (j=5000;j<13000;j+=2000){
                month -=100;
                let price = await priceInstance.getOptionsPrice_iv(i*1e8, j*1e8, month--,i,j*1000,0);
                console.log(i,j,price.toString(10));
                price = await priceInstance.getOptionsPrice_iv(i*1e8, j*1e8, month--,i,j*1000,1);
                console.log(i,j,price.toString(10));
            }
        }

    });
});