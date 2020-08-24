"use strict";
const path = require('path');
//const solc = require('solc');
const fs = require('fs');
module.exports = class Contract {
    constructor(abi,contractAddr) {
        this.Abi = abi;
        if(contractAddr){
            this.setcontractAddress(contractAddr);
        }
    }
    setFromSolFile(solFile,tokenName,contractAddr) {
        this.setAbiFromFile(solFile, tokenName);
        if(contractAddr){
            this.setcontractAddress(contractAddr);
        }
    }
    setcontractAddress(contractAddr)
    {
        if(/^0x[0-9a-f]{40}$/i.test(contractAddr))
        {
            this.contractAddr = contractAddr;
        }
    }
    setAbiFromFile(tokenFile,tokenName)
    {
        let compile = this.compileSol(tokenFile);
        let maxId = 0;
        let contractName = "";
//        let bbb = compile.sources[""].AST;
        for (var i=0;i<compile.sources[""].AST.children.length;i++){
            if (maxId < compile.sources[""].AST.children[i].id) {
                maxId = compile.sources[""].AST.children[i].id;
//                contractName = compile.sources[""].AST.children[i].name
                contractName = compile.sources[""].AST.children[i].attributes.name;
            }
        }
        this.name = contractName;
        console.log(this.name);
        this.Abi = this.getAbi(compile,contractName);

    }
    compileSol(tokenFile)
    {
        let dirName = path.dirname(tokenFile);
//        function findImports (file) {
//            return fs.readFileSync(path.join(dirName,file), 'utf8');
//        }
        let content = fs.readFileSync(tokenFile, 'utf8');
 //       return solc.compile(content);
    }
    getAbi(compileSol,tokenName)
    {
        return JSON.parse(compileSol.contracts[':'+tokenName].interface);
    }
    getFunctionItem(funcName){
        for(var i = 0;i<this.Abi.length;++i){
            let item = this.Abi[i];
            if(item.name == funcName){
                return item;
            }
        }
    }
    getFunctionName(byteCode,web3){
        for(var i = 0;i<this.Abi.length;++i){
            let item = this.Abi[i];
            if (item.type == "function"){
                let code = this.getFunctionCode(item.name,web3);
                if (byteCode.startsWith(code)){
                    return item.name;
                }
            }
        }
    }
    getEventName(byteCode,web3){
        for(var i = 0;i<this.Abi.length;++i){
            let item = this.Abi[i];
            if (item.type == "event"){
                let code = this.getEventCode(item.name,web3);
                if (byteCode == code){
                    return item.name;
                }
            }
        }
    }
    getConstructor(){
        for(var i = 0;i<this.Abi.length;++i){
            let item = this.Abi[i];
            if(item.type == "constructor"){
                return item;
            }
        }
    }
    getFuncInterface(funcName,web3){
        let Contract = new web3.eth.Contract(this.Abi,this.contractAddr);
        return Contract.methods[funcName];
    }
    getcommandString(funcName){
        for(var i = 0;i<this.Abi.length;++i){
            let item = this.Abi[i];
            if(item.name == funcName){
                let command = funcName + '(';
                for(var j=0;j<item.inputs.length;++j)
                {
                    if(j!=0)
                    {
                        command = command + ',';
                    }
                    command = command + item.inputs[j].type;
                }
                command = command + ')';
                return command;
            }
        }
    }
//    commandSha3(command,web3){
//        return utils.sha3(command, 256);
//    }
    getFunctionCode(funcName,web3){
        return web3.eth.abi.encodeFunctionSignature(this.getFunctionItem(funcName))
//        return this.commandSha3(this.getcommandString(funcName),web3).slice(0,4).toString('hex');
    }
    getEventCode(funcName,web3){
        return web3.eth.abi.encodeEventSignature(this.getFunctionItem(funcName))
//        return '0x' + this.commandSha3(this.getcommandString(funcName),web3).toString('hex');
    }

    getInput(abi, method)
    {
        let input = {inputs : [],format:[]};
        for(var i= 0; i<abi.length; ++i){
            if(abi[i].name == method){
                input.inputs = abi[i].inputs;
                break;
            }
        }
        if(input.inputs.length) {
            for (let j = 0; j < input.inputs.length; j++) {
                if(!input.inputs[j].indexed){
                    input.format.push(input.inputs[j].type);
                }
            }
        }
        return input;
    }

    deployContractData(web3,keyFile,contract,...args) {
        let compiled = this.compileSol(keyFile);
        let  name = ':' + contract;
        let Contract = new web3.eth.Contract(JSON.parse(compiled.contracts[name].interface));
        return '0x' + Contract.deploy({data:compiled.contracts[name].bytecode,arguments:args}).encodeABI();
    }
}