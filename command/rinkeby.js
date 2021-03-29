let Web3 = require("Web3");
const fs = require('fs');
//let web3 = new Web3(new Web3.providers.HttpProvider("https://rinkeby.infura.io/v3/f977681c79004fad87aa00da8f003597"));
let web3 = new Web3(new Web3.providers.HttpProvider("https://demodex.wandevs.org:48545"));
let contract = require("./contract/Contract.js")
let contractfunc = require("./contract/ContractFunc.js")
let OptionsPool = require("../build/contracts/OptionsPool.json");
let OptionsManagerV2 = require("../build/contracts/OptionsManagerV2.json");
let OptionsPrice = require("../build/contracts/OptionsPrice.json");
let FNXOracle = require("../build/contracts/FNXOracle.json");
let FPTCoin = require("../build/contracts/FPTCoin.json");
let ImpliedVol = require("../build/contracts/ImpliedVolatility.json");
async function rinkebyQuery(){
    let iv = await new web3.eth.Contract(ImpliedVol.abi,"0xb753bbfbf48e7d6de6c865e36675690879f9b9ec");
    let atmIv = await iv.methods.calculateIv(1,0,3600,9250e8,9250e8).call();
    console.log("btc atmIv : ",atmIv[0]);
    let oracle = await new web3.eth.Contract(FNXOracle.abi,"0xfeae9278a9553591045425a27188e1e0a071aee5");
    let btcPrice = await oracle.methods.getUnderlyingPrice(1).call();
    console.log("btcPrice :",btcPrice.toString(10));

    /*
    let times = await fpt.methods.lockedBalanceOf("0xa936B6F2557c096C0052a9A4765963B381D33896").call();
    console.log("burn limted time : ",times.toString(10));
    let manager = await new web3.eth.Contract(OptionsManagerV2.abi,"0xf5887c9e5cb7a5cf7aa21dc19af5fff372e238a5");
    let result = await manager.methods.getWhiteList().call();
    console.log("getWhiteList :",result);
    for(var i = 0;i<result.length;i++){
        let value = await manager.methods.getNetWorthBalance(result[i]).call();
        console.log(`${result[i]} balance : ${value.toString(10)}`);
    }
    let netWorth = await manager.methods.getTokenNetworth().call();
    console.log("netWorth :",netWorth.toString(10));
     result = await manager.methods.getTotalCollateral().call();
    console.log("TotalCollateral :",result.toString(10));
    result = await manager.methods.getOccupiedCollateral().call();
    console.log("OccupiedCollateral :",result.toString(10));
    result = await manager.methods.getLeftCollateral().call();
    console.log("LeftCollateral :",result.toString(10));
    let oracle = await new web3.eth.Contract(FNXOracle.abi,"0x3b4ca9ff4603d50fd96564e8ce18394772056784");
    let btcPrice = await oracle.methods.getUnderlyingPrice(1).call();
    console.log("btcPrice :",btcPrice.toString(10));
    btcPrice = await oracle.methods.getPrice("0x63ae282E874fC4291916996BE1537B274aEbAE9a").call();
    console.log("USDC Price :",btcPrice.toString(10));
    let price = await new web3.eth.Contract(OptionsPrice.abi,"0xa18acb43e276a09a434df162b665ea05cac7efda");
    result = await price.methods.getOptionsPrice(btcPrice,1155837000000,604800,1,0).call();
    console.log("price :",result.toString(10));
    result = await oracle.methods.getPrice("0xB642Cef1cffD9cCEa0e6724887b722B27A3E7D23").call();
    console.log("fnx price :",result.toString(10));
    */
}
rinkebyQuery();
async function wanTest(){
    var args = process.argv.splice(2)
    let txHash = args[0]
    let receipt = await web3.eth.getTransactionReceipt(txHash);
    console.log(receipt);
    let addr = "0xF416BDB17b90F153Eb076D52C4027a6c5371ca06";
    let result = await web3.eth.getBalance(addr.toLowerCase());
    console.log(result);
    let market = JSON.parse(fs.readFileSync('./build/contracts/OptionsManagerV2.json'));
    let tx = await web3.eth.getTransaction(txHash);
    console.log(tx);
    let con = new contract(market.abi);
    
    let name = con.getFunctionName(tx.input,web3);
    console.log(name)
    let func = new contractfunc(con,name);
    func.initParse(web3);
    let dict = func.parseContractMethodPara(tx.input.slice(10),web3);
    console.log(tx.input.slice(10),dict);
    receipt = await web3.eth.getTransactionReceipt(txHash);
    for (var i=0;i<receipt.logs.length;i++){
        let name = con.getEventName(receipt.logs[i].topics[0],web3);
        console.log(name);
        console.log(receipt.logs[i]);
    }
}
//wanTest();