"use strict";

module.exports = class ContractFunc {
    constructor(contract,contractFunc) {
        this.contract = contract;
        this.contractFunc = contractFunc;
    }
    getSolInferface(web3){
        return this.contract.getFuncInterface(this.contractFunc,web3);
    }
    initParse(web3)
    {
        if(this.contract.Abi)
        {
            if(this.contractFunc){
                this.input = this.contract.getInput(this.contract.Abi,this.contractFunc);
                this.cmdCode = this.contract.getFunctionCode(this.contractFunc,web3);
            }
        }
    }
    getViewData(web3,...args){
        let method = this.getSolInferface(web3);
        return method(...args).call();
    }
    getData(web3,...args){
        let method = this.getSolInferface(web3);
        return method(...args).encodeABI();
    }
    parseContractMethodPara(paraData,web3) {
        return web3.eth.abi.decodeParameters(this.input.format,paraData);
    }
}