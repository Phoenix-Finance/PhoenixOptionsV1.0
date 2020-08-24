
let FPTCoin = require("../build/contracts/FPTCoin.json");
let FNXMinePool = require("../build/contracts/FNXMinePool.json");
let OptionsPool = require("../build/contracts/OptionsPool.json");
let OptionsManagerV2 = require("../build/contracts/OptionsManagerV2.json");
let Web3 = require("Web3")
let web3 = new Web3(new Web3.providers.HttpProvider("https://demodex.wandevs.org:48545"));
let fnxAddr = "0xdF228001e053641FAd2BD84986413Af3BeD03E0B";
let collateral0 = "0x0000000000000000000000000000000000000000";
async function wanTestNet(){

    let optionPool = await new web3.eth.Contract(OptionsPool.abi,"0xb37a379a6f364c5c33244218b46a3475f7c3caf9");
    let result = await optionPool.methods.getOptionInfoLength().call();
    console.log(result);
    for (var i=0;i<50;i++){
        let info = await optionPool.methods.getOptionsById(i+1).call();
        console.log(info);
    }
    result = await optionPool.methods.getUserOptionsID("0xe732e883d03e230b7a5c2891c10222fe0a1fb2cb").call();
    console.log(result);
    result = await optionPool.methods.getUserOptionsID("0xc864f6c8f8a75c4885f8208964a85a7f517bdecb").call();
    console.log(result);
    let fptCoin = await new web3.eth.Contract(FPTCoin.abi,"0x45e7b6f09e965b292a14f47822b646074d6e1b79");
    let balance = await fptCoin.methods.balanceOf("0xe732e883d03e230b7a5c2891c10222fe0a1fb2cb").call()
    console.log(balance);
    let addr = await fptCoin.methods.getFNXMinePoolAddress().call()
    console.log(addr);
    let minePool = await new web3.eth.Contract(FNXMinePool.abi,addr);
    let mine = await minePool.methods.getMinerBalance("0xe732e883d03e230b7a5c2891c10222fe0a1fb2cb",collateral0).call()
    console.log(1,mine);
    mine = await minePool.methods.getMinerBalance("0xe732e883d03e230b7a5c2891c10222fe0a1fb2cb",fnxAddr).call()
    console.log(2,mine);
    let manager = await new web3.eth.Contract(OptionsManagerV2.abi,"0x1d0c7fe7970ad304aa9ade5e06c6b1f0af14adb4");
    mine = await manager.methods.getTokenNetworth().call();
    console.log(3,mine.toString(10));
}
wanTestNet();