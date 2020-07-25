let Web3 = require("Web3")
let web3 = new Web3(new Web3.providers.HttpProvider("https://demodex.wandevs.org:48545"));
let optionsManager = require("../build/contracts/OptionsMangerV2.json");
let CompoundOracle = require("../build/contracts/CompoundOracle.json");
let marketTrading = require("../build/contracts/OptionsPool.json");
let FNXCoin = require("../build/contracts/FNXCoin.json");
let erc20 = require("../build/contracts/IERC20.json");
let collateral0 = "0x0000000000000000000000000000000000000000";
async function wanMainNet(){
    let oracle = await new web3.eth.Contract(CompoundOracle.abi,"0x9590e4DA7D7Cdb8745e79E4C05668A36574100D4");
    let owner = await oracle.methods.owner().call();
    console.log(owner);
    return;
    let manager = await new web3.eth.Contract(optionsManager.abi,"0xea6ca106373842a09c83459A4a977136E278e9F9");
    let whiteList = await manager.methods.getWhiteList().call();
    console.log(whiteList);
    let fnx = await new web3.eth.Contract(FNXCoin.abi,"0xdf228001e053641fad2bd84986413af3bed03e0b");
    let fnxBal = await fnx.methods.balanceOf("0xe732e883d03e230b7a5c2891c10222fe0a1fb2cb").call();
    console.log(fnxBal.toString(10));
    return;
    addr = "0x65e5E104C8E96636aEF4728C3623484aE1A21Fa9".toLowerCase();
    let used = await manager.methods.calculateOptionsValueUSD(collateral0,addr).call();
    let balance = await manager.methods.getWriterCollateralBalance(addr,collateral0).call();
    console.log(used.toString(10),balance.toString(10));
    used = await manager.methods.calculateOptionsValueUSD("0xc6f4465a6a521124c8e3096b62575c157999d361",addr).call();
    balance = await manager.methods.getWriterCollateralBalance(addr,"0xc6f4465a6a521124c8e3096b62575c157999d361").call();
    console.log(used.toString(10),balance.toString(10));
    let optionList = await manager.methods.getOptionsTokenList().call();
    for (var i=0;i<optionList.length;i++){
        let optionInfo = await manager.methods.getOptionsTokenInfo(optionList[i]).call();
        console.log(optionList[i],optionInfo);
        let writers = await manager.methods.getOptionsTokenWriterList(optionList[i]).call();
        for (var j=0;j<writers.length;j++){
            let tokenNum = await manager.methods.getWriterOptionsTokenBalance(writers[j],optionList[i]).call();
            console.log(optionList[i],tokenNum);
        }
        let token = await new web3.eth.Contract(erc20.abi,optionList[i]);
        let balance = await token.methods.balanceOf("0xe1e4a74A0232AcA5F55a4163DcaE8B6546bf0827").call();
        console.log(optionList[i],balance);
    }
    let market = await new web3.eth.Contract(marketTrading.abi,"0xe1e4a74A0232AcA5F55a4163DcaE8B6546bf0827");
    for (var i=0;i<optionList.length;i++){
        let payList = await market.methods.getPayOrderList(optionList[i],"0xc6f4465a6a521124c8e3096b62575c157999d361").call();
        let sellList = await market.methods.getSellOrderList(optionList[i],"0xc6f4465a6a521124c8e3096b62575c157999d361").call();
        console.log("fnx buy",payList,"fnx sell",sellList);
        payList = await market.methods.getPayOrderList(optionList[i],collateral0).call();
        sellList = await market.methods.getSellOrderList(optionList[i],collateral0).call();
        console.log("wan buy",payList,"wan sell",sellList);
    }
}
wanMainNet();