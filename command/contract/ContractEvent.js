"use strict";

let ContractFunc = require("./ContractFunc.js");
module.exports = class ContractEvent extends ContractFunc {
    constructor(contract,contractEvent) {
        super(contract,contractEvent)
    }
    initParse(web3)
    {
        if(this.contract.Abi)
        {
            if(this.contractFunc){
                this.input = this.contract.getInput(this.contract.Abi,this.contractFunc);
                this.cmdCode = this.contract.getEventCode(this.contractFunc,web3);
            }
        }
    }
    parseContractMethodPara(paraData,web3) {
        var dict = {};
        let paras = web3.eth.abi.decodeParameters(this.input.format,paraData);
        for(let j=0,k=0; k<this.input.inputs.length && j<paras.length; k++){
            if(this.input.inputs[k].indexed)
                continue;
            dict[this.input.inputs[k].name] = paras[j];
            ++j;
        }
        return dict;
    }
}