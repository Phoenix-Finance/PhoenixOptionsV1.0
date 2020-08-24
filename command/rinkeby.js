let Web3 = require("Web3")
const fs = require('fs');
let web3 = new Web3(new Web3.providers.HttpProvider("https://rinkeby.infura.io/v3/f977681c79004fad87aa00da8f003597"));
let contract = require("./contract/Contract.js")
let contractfunc = require("./contract/ContractFunc.js")
let OptionsPool = require("../build/contracts/OptionsPool.json");
let OptionsManagerV2 = require("../build/contracts/OptionsManagerV2.json");
let OptionsPrice = require("../build/contracts/OptionsPrice.json");
let FNXOracle = require("../build/contracts/FNXOracle.json");
async function rinkebyQuery(){
    let manager = await new web3.eth.Contract(OptionsManagerV2.abi,"0x0eab0c80a6819fed0986014d0bd077040fe846f1");
    let netWorth = await manager.methods.getTokenNetworth().call();
    console.log("netWorth :",netWorth.toString(10));
    let result = await manager.methods.getTotalCollateral().call();
    console.log("TotalCollateral :",result.toString(10));
    result = await manager.methods.getOccupiedCollateral().call();
    console.log("OccupiedCollateral :",result.toString(10));
    result = await manager.methods.getLeftCollateral().call();
    console.log("LeftCollateral :",result.toString(10));
    let oracle = await new web3.eth.Contract(FNXOracle.abi,"0x0574299391bf54e44918d529b4c9ac68237bb07e");
    let btcPrice = await oracle.methods.getUnderlyingPrice(1).call();
    console.log("btcPrice :",btcPrice.toString(10));
    let price = await new web3.eth.Contract(OptionsPrice.abi,"0xa18acb43e276a09a434df162b665ea05cac7efda");
    result = await price.methods.getOptionsPrice(btcPrice,1155837000000,604800,1,0).call();
    console.log("price :",result.toString(10));
    result = await oracle.methods.getPrice("0x1b95d8e5a5ea04908591c1b98a936b424705a959").call();
    console.log("fnx price :",result.toString(10));
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
wanTest();