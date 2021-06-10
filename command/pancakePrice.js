let Web3 = require("Web3")
let web3 = new Web3(new Web3.providers.HttpProvider("https://bsc-dataseed1.binance.org/"));
let pancakeRouter = require("../build/contracts/pancakeRouter.json");
async function rinkebyQuery(){
    let usd = "0xe9e7cea3dedca5984780bafc599bd69add087d56"
    let wbnb = "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c"
    let routerV2 = await new web3.eth.Contract(pancakeRouter,"0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F");
    let addresses = [usd,wbnb,"0x0e09fabb73bd3ade0a17ecc321fd13a19e81ce82"]
    let amounts = await routerV2.methods.getAmountsOut("1000000000000000000",addresses).call();
    console.log(amounts);
    console.log(amounts[amounts.length-1].toString());
    //= 1e18/amounts[amounts.length-1]
    addresses = [usd,wbnb,"0xa184088a740c695e156f91f5cc086a06bb78b827"]
    amounts = await routerV2.methods.getAmountsOut("1000000000000000000",addresses).call();
    console.log(amounts);
    console.log(amounts[amounts.length-1].toString());
    //= 1e18/amounts[amounts.length-1]
    addresses = [usd,wbnb,"0xcf6bb5389c92bdda8a3747ddb454cb7a64626c63"]
    amounts = await routerV2.methods.getAmountsOut("1000000000000000000",addresses).call();
    console.log(amounts);
    console.log(amounts[amounts.length-1].toString());
    //= 1e18/amounts[amounts.length-1]
    addresses = [usd,wbnb,"0xeca41281c24451168a37211f0bc2b8645af45092"]
    amounts = await routerV2.methods.getAmountsOut("1000000000000000000",addresses).call();
    console.log(amounts);
    console.log(amounts[amounts.length-1].toString());
    //= 1e4/amounts[amounts.length-1]
    addresses = [usd,wbnb,"0xae9269f27437f0fcbc232d39ec814844a51d6b8f"]
    amounts = await routerV2.methods.getAmountsOut("1000000000000000000",addresses).call();
    console.log(amounts);
    console.log(amounts[amounts.length-1].toString());
    //= 1e18/amounts[amounts.length-1]

    addresses = [usd,wbnb,"0xf79037f6f6be66832de4e7516be52826bc3cbcc4"]
    amounts = await routerV2.methods.getAmountsOut("1000000000000000000",addresses).call();
    console.log(amounts);
    console.log(amounts[amounts.length-1].toString());
    addresses = [usd,wbnb,"0xF218184Af829Cf2b0019F8E6F0b2423498a36983"]
    amounts = await routerV2.methods.getAmountsOut("1000000000000000000",addresses).call();
    console.log(amounts);
    console.log(amounts[amounts.length-1].toString());
    return;


    result = await oracle.methods.getPrice(collateral0).call();
    console.log("wan price :",result.toString(10));
}

rinkebyQuery();