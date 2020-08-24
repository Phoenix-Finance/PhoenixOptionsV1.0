let Web3 = require("Web3")
const fs = require('fs');
let web3 = new Web3(new Web3.providers.HttpProvider("https://demodex.wandevs.org:48545"));
let contract = require("./contract/Contract.js")
let contractfunc = require("./contract/ContractFunc.js")
let IFnxPriceDb = require("../build/contracts/IFnxPriceDb.json");
let FNXOracle = require("../build/contracts/FNXOracle.json");
let collateral0 = "0x0000000000000000000000000000000000000000";
async function wanTest(){

    let priceDB = await new web3.eth.Contract(IFnxPriceDb.abi,"0x874091F169983C375DDF067b5ec0CE446855b55d");  
    let result = await priceDB.methods.getPrice("BTC").call();
    console.log("BTC :",result.toString(10));
    result = await priceDB.methods.getPrice("ETH").call();
    console.log("ETH :",result.toString(10));
    result = await priceDB.methods.getPrice("WAN").call();
    console.log("WAN :",result.toString(10));
    result = await priceDB.methods.getPrice("FNX").call();
    console.log("FNX :",result.toString(10));

    let oracle = await new web3.eth.Contract(FNXOracle.abi,"0x00db8fec3a5767c96c595814a8c70110ba5091e2");
    result = await oracle.methods.getUnderlyingPrice(1).call();
    console.log("btcPrice :",result.toString(10));
    result = await oracle.methods.getPrice(collateral0).call();
    console.log("wan price :",result.toString(10));
    result = await oracle.methods.getUnderlyingPrice("0xdF228001e053641FAd2BD84986413Af3BeD03E0B").call();
    console.log("fnx Price :",result.toString(10));
    return;
    let args = process.argv.splice(2)
    let txHash = args[0]
    let receipt = await web3.eth.getTransactionReceipt(txHash);
    console.log(receipt);
    let addr = "0xF416BDB17b90F153Eb076D52C4027a6c5371ca06";
    result = await web3.eth.getBalance(addr.toLowerCase());
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
wanTest();