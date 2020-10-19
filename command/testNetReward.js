let Web3 = require("Web3")
const fs = require('fs');
let web3 = new Web3(new Web3.providers.HttpProvider("https://demodex.wandevs.org:48545"));
let OptionsPool = require("../build/contracts/OptionsPool.json");
let OptionsManagerV2 = require("../build/contracts/OptionsManagerV2.json");
let FNXMinePool = require("../build/contracts/FNXMinePool.json");
let FNXOracle = require("../build/contracts/FNXOracle.json");
let FPTCoin = require("../build/contracts/FPTCoin.json");
let collateral0 = "0x0000000000000000000000000000000000000000";
async function wanTest(){

    let fpt = await new web3.eth.Contract(FPTCoin.abi,"0x362aa050a9a67a778192a748bf1c8172f3205038");
    let oracle = await new web3.eth.Contract(FNXOracle.abi,"0x587b33ca62e138efbe69c05c64dab936596973f7");
    let manager = await new web3.eth.Contract(OptionsManagerV2.abi,"0x93750e1b3b9a06cd55917771f1b90ae119025026");

    for(var i= 	9220600;i<9232200;i+=100){
        try {
            let totalSupply = await fpt.methods.totalSupply().call(i);
            let mine = await new web3.eth.Contract(FNXMinePool.abi,"0xc05a7e55933b5320a3f209fab75d055f3c96c0de");
            let minevalue0 = await mine.methods.getTotalMined(collateral0).call(i);
            let minevalue1 = await mine.methods.getTotalMined("0xdF228001e053641FAd2BD84986413Af3BeD03E0B").call(i);
            let netWorth = await manager.methods.getTokenNetworth().call(i);
            let wanPrice = await oracle.methods.getPrice(collateral0).call(i);
            let fnxPrice = await oracle.methods.getPrice("0xdF228001e053641FAd2BD84986413Af3BeD03E0B").call(i);
            console.log(i,netWorth.toString(10),totalSupply.toString(10),minevalue0.toString(10),minevalue1.toString(10),wanPrice.toString(10),fnxPrice.toString(10));
        } catch (error) {
            i -= 100;
            continue;            
        }
    }


}
wanTest();