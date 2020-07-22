let OptionsPrice = artifacts.require("OptionsPriceTest");
const ImpliedVolatility = artifacts.require("ImpliedVolatility");
let month = 30*60*60*24;
contract('OptionsPrice', function (accounts){
    it('OptionsPrice Call options', async function (){
        let priceInstance = await OptionsPrice.deployed();
        let ivAddress = "0x97b95c36FB7adE536527d4dBe41544a65E8391a7";
        let ivInstance = await ImpliedVolatility.at(ivAddress);
        let result = await ivInstance.ivMatrixMap[0x10000];
        console.log(result);
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