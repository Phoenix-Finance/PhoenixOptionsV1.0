const fpoProxyAbi = require("../build/contracts/CollateralProxy.json").abi;
const oracleAbi = require("../build/contracts/FNXOracle.json").abi;
const Web3 = require("web3")
const BigNumber = require("bignumber.js");
const setupWeb3 = async () => {
    const eth_web3 = await new Web3(new Web3.providers.HttpProvider("https://main-light.eth.linkpool.io"))
//    const eth_web3 = await new Web3(new Web3.providers.HttpProvider("https://mainnet.infura.io/v3/f977681c79004fad87aa00da8f003597"))
    const wan_web3 = await new Web3(new Web3.providers.HttpProvider("https://gwan-ssl.wandevs.org:56891"))
    const bsc_web3 = await new Web3(new Web3.providers.HttpProvider("https://bsc-dataseed1.binance.org/"))
    return {eth_web3, wan_web3,bsc_web3}
  }
  
//Define all ETH addresses
const eth_fnx = {
    address : "0xef9cd7882c067686691b6ff49e650b43afbbcc6b",
    decimals: 18
  }
  const eth_usdc = {
    address : "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
    decimals: 6
  }
  const eth_usdt = {
    address : "0xdac17f958d2ee523a2206206994597c13d831ec7",
    decimals: 6
  }
  const eth_frax = {
    address : "0x853d955acef822db058eb8505911ed77f175b99e",
    decimals: 18
  }
  const bsc_fnx = {
    address : "0xdFd9e2A17596caD6295EcFfDa42D9B6F63F7B5d5",
    decimals: 18
  }
  const bsc_busd = {
    address : "0xe9e7cea3dedca5984780bafc599bd69add087d56",
    decimals: 18
  }
  const bsc_usdt = {
    address : "0x55d398326f99059ff775485246999027b3197955",
    decimals: 18
  }
  const wan_fnx = {
    address : "0xC6F4465A6a521124C8e3096B62575c157999D361",
    decimals: 18
  }
  const wan_wan = {
    address : "0x0000000000000000000000000000000000000000",
    decimals: 18
  }
  const wan_usdt = {
    address : "0x11e77e27af5539872efed10abaa0b408cfd9fbbd",
    decimals: 6
  }
  /*
  // Set number formatting default
  numeral.defaultFormat("0,0.00");
  
  // For converting to proper number of decimals
  const convertNum = (num, decimal) => {
    return Math.round((num / (10*10**(decimal-3))))/100
  }
  */
  const eth_oracle = "0x43BD92bF3Bb25EBB3BdC2524CBd6156E3Fdd41F3";
  const wan_oracle = "0x75456e0EC59D997eB5cb705DAB2958f796D698Bb";
  const bsc_oracle = "0x5fb39bdfa86f1a6010cd816085c2146776f08aac";
  const ethUSDCPool = {
    address : "0xff60d81287bf425f7b2838a61274e926440ddaa6",
    tokens :[eth_usdc,eth_usdt]
  }
  const ethFraxPool = {
    address : "0x6f88e8fbF5311ab47527f4Fb5eC10078ec30ab10",
    tokens :[eth_frax]
  }
  const ethFnxPool = {
    address : "0x919a35a4f40c479b3319e3c3a2484893c06fd7de",
    tokens :[eth_fnx]
  }
  const wanUSDTPool = {
    address : "0x297ff55afef50c9820d50ea757b5beba784757ad",
    tokens :[wan_usdt]
  }
  const wanFnxPool = {
    address : "0xe96e4d6075d1c7848ba67a6850591a095adb83eb",
    tokens :[wan_fnx,wan_wan]
  }
  
  const bscUSDTPool = {
    address : "0xa3f70add496d2c1c2c1be5514a5fcf0328337530",
    tokens :[bsc_busd,bsc_usdt]
  }
  const bscFnxPool = {
    address : "0xf2e1641b299e60a23838564aab190c52da9c9323",
    tokens :[bsc_fnx]
  }
  const denominator = new BigNumber("100000000000000000000000000");
  async function getPoolsTvl(pools,web3,oracleAddr){
    let oracle = await new web3.eth.Contract(oracleAbi, oracleAddr);
    let totalTvl = [];
    for (var i=0;i<pools.length;i++){
        let tvl0 = await getPoolTvl(pools[i],web3,oracle);
        totalTvl.push(tvl0)
    }
    return totalTvl;
  }
  async function getPoolTvl(pool,web3,oracle){
    let colProxy = await new web3.eth.Contract(fpoProxyAbi, pool.address);
    let totalTvl = new BigNumber(0);
    for (var i=0;i<pool.tokens.length;i++){
      let tokenTvl = await colProxy.methods.getNetWorthBalance(pool.tokens[i].address).call();
      let price = await oracle.methods.getPrice(pool.tokens[i].address).call();
      console.log(tokenTvl.toString(),price.toString());
      tokenTvl = new BigNumber(tokenTvl);
      price = new BigNumber(price);
      totalTvl = totalTvl.plus(tokenTvl.multipliedBy(price).dividedBy(denominator));
    }
    return totalTvl;
  }
  async function getData(){
    web3s = await setupWeb3();
    const {eth_web3, wan_web3,bsc_web3} = web3s;
    const currentBlockNumber = await wan_web3.eth.getBlockNumber()
    const currentEthBlockNumber = await eth_web3.eth.getBlockNumber()
    console.log(currentBlockNumber.toString(),currentEthBlockNumber.toString());
    let fpoTvlEth = await getPoolsTvl([ethUSDCPool,ethFraxPool,ethFnxPool],eth_web3,eth_oracle);
    console.log(fpoTvlEth)
    let fpoTvlWan = await getPoolsTvl([wanUSDTPool,wanFnxPool],wan_web3,wan_oracle);
    console.log(fpoTvlEth,fpoTvlWan);
    let fpoTvlBsc = await getPoolsTvl([bscUSDTPool,bscFnxPool],bsc_web3,bsc_oracle);
    console.log(fpoTvlEth.toString(),fpoTvlWan.toString(),fpoTvlBsc.toString())
  }
  
  getData();