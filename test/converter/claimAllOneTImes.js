const { time, expectEvent} = require("@openzeppelin/test-helpers")
let utils = require('./utils.js');

let CFNC = artifacts.require("PHXCoin");
let TokenConverter = artifacts.require("TokenConverter");
//let TokenConverterProxy = artifacts.require("TokenConverterProxy");
let multiSignature = artifacts.require("multiSignature");

const BN = require("bn.js");
const assert = require('assert');

const ONE_HOUR = 60*60;
const ONE_DAY = ONE_HOUR * 24;
const ONE_MONTH = 30 * ONE_DAY;

contract('TokenConverter', function (accounts) {
    let cfnxAmount0 = new BN("30000000000000000000");
    let cfnxAmount1 = new BN("60000000000000000000");
    let cfnxAmount2 = new BN("120000000000000000000");
    let cfnxAmount3 = new BN("125000000000000000000");
    let fnxAmount = new BN("90000000000000000000000");

    let CFNXInst;
    let FNXInst;
    let CvntInst;
    let CvntProxyInst;

    before(async () => {
        let owners = [accounts[0],accounts[1],accounts[2]];
        multiSigInst = await multiSignature.new(owners,2);

        CFNXInst = await CFNC.new();
        console.log("cfnx address:" + CFNXInst.address);

        FNXInst = await CFNC.new();
        console.log("fnx address:" + CFNXInst.address);

        CvntInst = await TokenConverter.new(multiSigInst.address);
        console.log("converter address:" + CvntInst.address);

        CvntProxyInst = CvntInst; //await TokenConverterProxy.new(CvntInst.address);
        console.log("proxy address:" + CvntProxyInst.address);

        let tx = await CvntProxyInst.setParameter(CFNXInst.address,FNXInst.address,0,0,0);
        assert.equal(tx.receipt.status,true);
        ////init process
        tx = await CFNXInst.mint(accounts[1],cfnxAmount1.mul(new BN(20)));
        assert.equal(tx.receipt.status,true);

        tx = await CFNXInst.mint(accounts[2],cfnxAmount2);
        assert.equal(tx.receipt.status,true);

        tx = await CFNXInst.mint(accounts[3],cfnxAmount3);
        assert.equal(tx.receipt.status,true);

        tx = await FNXInst.mint(CvntProxyInst.address,fnxAmount);
        assert.equal(tx.receipt.status,true);

        tx = await CFNXInst.approve(CvntProxyInst.address,cfnxAmount1.mul(new BN(20)),{from:accounts[1]});
        assert.equal(tx.receipt.status,true);

        tx = await CFNXInst.approve(CvntProxyInst.address,cfnxAmount2.mul(new BN(20)),{from:accounts[2]});
        assert.equal(tx.receipt.status,true);

        tx = await CFNXInst.approve(CvntProxyInst.address,cfnxAmount3.mul(new BN(20)),{from:accounts[3]});
        assert.equal(tx.receipt.status,true);
    });

    it('1 User1 input CFNX and get 1/6 FNX', async function () {
        let beforeFnxUser =  await FNXInst.balanceOf(accounts[1]);
        let beforeCFnxBalanceUser = await CFNXInst.balanceOf(accounts[1]);
        console.log(beforeCFnxBalanceUser);
        console.log(await CFNXInst.allowance(accounts[1],CvntProxyInst.address));

        let beforeFnxBalanceProxy = await CFNXInst.balanceOf(CvntProxyInst.address);
        let tx = await CvntProxyInst.inputCphxForInstallmentPay(cfnxAmount0,{from:accounts[1]});
        assert.equal(tx.receipt.status,true);

        time.increase(ONE_DAY+10)
        tx = await CvntProxyInst.inputCphxForInstallmentPay(cfnxAmount0,{from:accounts[1]});
        assert.equal(tx.receipt.status,true);

        time.increase(ONE_DAY+10)
        tx = await CvntProxyInst.inputCphxForInstallmentPay(cfnxAmount0,{from:accounts[1]});
        assert.equal(tx.receipt.status,true);

        time.increase(ONE_DAY+10)
        tx = await CvntProxyInst.inputCphxForInstallmentPay(cfnxAmount0,{from:accounts[1]});
        assert.equal(tx.receipt.status,true);

    })


    it('2 user balances', async function () {
        await time.increase(5*ONE_MONTH + 10);

        let lockedBalance = await CvntProxyInst.lockedBalanceOf(accounts[1]);
        console.log(web3.utils.fromWei(lockedBalance.toString(10)))

        let useRecords = await CvntProxyInst.getUserConvertRecords(accounts[1]);

        console.log(useRecords);
        let dimLen = useRecords[0];
        for(var i=0;i<useRecords[1].length;i++) {
            if(i%dimLen==0) {
                console.log("\nthe convert idx:" + (i/dimLen));
                if(web3.utils.fromWei(useRecords[2][i])==0) {
                    console.log("all of this convert idx is claimed")
                } else {
                    console.log("total locked amount of this convert:"+ web3.utils.fromWei(useRecords[2][i]));
                }

                continue;
            }
            console.log("expiredTime:"+useRecords[1][i].toString(10),
                        "   amount:"+ web3.utils.fromWei(useRecords[2][i]));
        }

    })

})