const optionsFactory = artifacts.require("optionsFactory");
const testOptionsFactory = artifacts.require("testOptionsFactory");
const OptionsPool = artifacts.require("OptionsPool");
const OptionsNetWorthCal = artifacts.require("OptionsNetWorthCal");
const multiSignature = artifacts.require("multiSignature");
const phxProxy = artifacts.require("phxProxy");
const PPTCoin = artifacts.require("PPTCoin");
const acceleratedMinePool = artifacts.require("acceleratedMinePool");
const PHXVestingPool = artifacts.require("PHXVestingPool");
const CollateralPool = artifacts.require("CollateralPool");
const OptionsManagerV2 = artifacts.require("OptionsManagerV2");
const PHXOracle = artifacts.require("PHXOracle");
const ImpliedVolatility = artifacts.require("ImpliedVolatility");
const OptionsPrice = artifacts.require("OptionsPrice");
module.exports = {
    feeAddress : "0xc864f6c8f8a75c4885f8208964a85a7f517bdecb",
    createTestFactory: async function(account,owners){
        phxOracle = await PHXOracle.new();
        let volatility = await ImpliedVolatility.new();
        let optionsPrice = await OptionsPrice.new(volatility.address);
        let multiSign = await multiSignature.new(owners,3,{from:account});
        let OptionsPoolImpl = await OptionsPool.new(multiSign.address,{from:account});
        let OptionsCalImpl = await OptionsNetWorthCal.new(multiSign.address,{from:account});
        let CollateralPoolImpl = await CollateralPool.new(multiSign.address,{from:account});
        let optionsManagerImpl = await  OptionsManagerV2.new(multiSign.address,{from:account});
        let pptCoinImpl = await PPTCoin.new(multiSign.address,{from:account});
        let vestingPool =  await PHXVestingPool.new(multiSign.address,{from:account});
        let vestingPoolProxy = await phxProxy.new(vestingPool.address,multiSign.address,{from:account});
        vestingPool = await PHXVestingPool.at(vestingPoolProxy.address);
        await vestingPool.initMineLockedInfo(1622995200,86400*30,36,{from:account});
        let minePool =await acceleratedMinePool.new(multiSign.address,{from:account});
        let lFactory = await testOptionsFactory.new(multiSign.address,{from:account});
        proxy = await phxProxy.new(lFactory.address,multiSign.address,{from:account});
        lFactory = await testOptionsFactory.at(proxy.address);
        await lFactory.setImplementAddress("ETH",
        OptionsCalImpl.address,OptionsPoolImpl.address,CollateralPoolImpl.address,optionsManagerImpl.address,pptCoinImpl.address,
        minePool.address,vestingPool.address,phxOracle.address,volatility.address,optionsPrice.address)
        return {multiSignature : multiSign,
            optionsFactory : lFactory,
            oracle : phxOracle
            };
    },
    createFactory : async function(account,owners){
        phxOracle = await PHXOracle.new();
        let volatility = await ImpliedVolatility.new();
        let optionsPrice = await OptionsPrice.new(volatility.address);
        let multiSign = await multiSignature.new(owners,3,{from:account});
        let OptionsPoolImpl = await OptionsPool.new(multiSign.address,{from:account});
        let OptionsCalImpl = await OptionsNetWorthCal.new(multiSign.address,{from:account});
        let CollateralPoolImpl = await CollateralPool.new(multiSign.address,{from:account});
        let optionsManagerImpl = await  OptionsManagerV2.new(multiSign.address,{from:account});
        let pptCoinImpl = await PPTCoin.new(multiSign.address,{from:account});
        let vestingPool =  await PHXVestingPool.new(multiSign.address,{from:account});
        let vestingPoolProxy = await phxProxy.new(vestingPool.address,multiSign.address,{from:account});
        vestingPool = await PHXVestingPool.at(vestingPoolProxy.address);
        await vestingPool.initMineLockedInfo(1622995200,86400*30,36,{from:account});
        let minePool =await acceleratedMinePool.new(multiSign.address,{from:account});
        let lFactory = await optionsFactory.new(multiSign.address,{from:account});
        proxy = await phxProxy.new(lFactory.address,multiSign.address,{from:account});
        lFactory = await optionsFactory.at(proxy.address);
        await lFactory.setImplementAddress("ETH",
        OptionsCalImpl.address,OptionsPoolImpl.address,CollateralPoolImpl.address,optionsManagerImpl.address,pptCoinImpl.address,
        minePool.address,vestingPool.address,phxOracle.address,volatility.address,optionsPrice.address)
        return {multiSignature : multiSign,
            optionsFactory : lFactory,
            oracle : phxOracle
            };
    },
    createOptionsManager : async function(factory,account,owners,collateral,rate,underlying){
        await this.multiSignatureAndSend(factory.multiSignature,factory.optionsFactory,
                "createOptionsManager",account,owners,collateral,rate,underlying); 
        let length = await factory.optionsFactory.getOptionsMangerLength();
        let addresses = await factory.optionsFactory.getOptionsMangerAddress(length.subn(1));
        
        let contratcs = {
            manager : await OptionsManagerV2.at(addresses[0]),
            collateral : await CollateralPool.at(addresses[1]),
            options : await OptionsPool.at(addresses[2]),
            ppt : await PPTCoin.at(addresses[3]),
        }
        let mineAddress = await contratcs.ppt.minePool();
        contratcs.mine = await acceleratedMinePool.at(mineAddress);
        return contratcs;
    },
    multiSignatureAndSend: async function(multiContract,toContract,method,account,owners,...args){
        let msgData = await toContract.contract.methods[method](...args).encodeABI();
        let hash = await this.createApplication(multiContract,account,toContract.address,0,msgData)
        let index = await multiContract.getApplicationCount(hash)
        index = index.toNumber()-1;
        await multiContract.signApplication(hash,index,{from:owners[0]})
        await multiContract.signApplication(hash,index,{from:owners[1]})
        await multiContract.signApplication(hash,index,{from:owners[2]})
        await toContract[method](...args,{from:account});
    },
    createApplication: async function (multiSign,account,to,value,message){
        await multiSign.createApplication(to,value,message,{from:account});
        return await multiSign.getApplicationHash(account,to,value,message)
    },
    setAddressFromJson: async function(fileName,address) {
        var contract = require("@truffle/contract");
        let buildJson = require(fileName)
        let newContract = contract(buildJson)
        newContract.setProvider(web3.currentProvider);
        let artifact = await newContract.at(address);
        return artifact;
    },
    createFromJson: async function(fileName,account,...args) {
        var contract = require("@truffle/contract");
        let buildJson = require(fileName)
        let newContract = contract(buildJson)
        newContract.setProvider(web3.currentProvider);
        let artifact = await newContract.new(...args,{from : account});
        return artifact;
    }
}
