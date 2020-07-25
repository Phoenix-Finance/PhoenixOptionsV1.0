const imVolatilityTest = artifacts.require("imVolatilityTest");
const BN = require("bn.js");
contract('imVolatilityTest', function (accounts){
    it('imVolatilityTest add IvMap', async function (){
        let volInstance = await imVolatilityTest.deployed();
        let btcP = {}
        let btcC = {}
        let pAry = [];
        let cAry = [];
        let curTime =Date.now()-48*60*60*1000;
        for (var i=0;i<IvMax.length;i++){
            stringAry = IvMax[i][0].split("-");
            //var str2 = "Jan 19 2017 13:00:00";
            var strTime = stringAry[1];
            if (strTime.length == 6){
                strTime = "0"+strTime;
            }
            var timeStr = strTime.slice(2,5)+ " " + strTime.slice(0,2) + " 20"+strTime.slice(5)+ " 16:00:00";
            var time = (new Date(timeStr).getTime()-curTime)/1000;
            if (stringAry[3] == "P"){
                pAry.push([time,stringAry[2],IvMax[i][1]]);
            }else{
                cAry.push([time,stringAry[2],IvMax[i][1]]);
            }
        }
        function compare(a,b){
            if (Math.floor(a[0]) == Math.floor(b[0])){
                return a[1]-b[1];
            }else{
                return Math.floor(a[0]) - Math.floor(b[0]);
            }
        }
        pAry.sort(compare);
        cAry.sort(compare);
        let tx = await SendArrayNew(volInstance,0,cAry);
//        console.log(tx);
        tx = await SendArrayNew(volInstance,1,pAry);
//        console.log(tx);
//        tx = await SendArrayNew(volInstance,1,cAry);
//        console.log(tx);
//        tx = await SendArrayNew(volInstance,0,pAry);
//        console.log(tx);
        let timeAryLen = await volInstance.getTimeMapLen(1,0);
        console.log(timeAryLen.toString(10));
        let bufferLen = await volInstance.getTimeAllBufferLen(1,0);
        console.log(bufferLen.toString(10));
        let buffer = await volInstance.getTimeAllBuffer(1,0);
        for (var i=0;i<buffer.length;i++){
            console.log(buffer[i].toString(16));
        }
        buffer = await volInstance.getTimeAllBuffer(1,1);
        for (var i=0;i<buffer.length;i++){
            console.log(buffer[i].toString(16));
        }
        for (var i=0;i<cAry.length;i++){
            let iv = await volInstance.calculateIv(1,0,Math.floor(cAry[i][0]*0.5),Math.floor(cAry[i][1]*0.5e8));
            console.log(iv[0].toString(10),iv[1].toString(10),cAry[i][2]);
        }
        for (var i=0;i<pAry.length;i++){
            let iv = await volInstance.calculateIv(1,1,Math.floor(pAry[i][0]*0.5),Math.floor(pAry[i][1]*0.5e8));
            console.log(iv[0].toString(10),iv[1].toString(10),pAry[i][2]);
        }
    });
});
async function SendArrayNew(volInstance,optype,Ary){
    let childLen = []
    let ivAry = []
    let time = Math.floor(Ary[0][0])
    for (var i=0;i<Ary.length;i++){
        if (time != Math.floor(Ary[i][0])){
            childLen.push(time);
            childLen.push(i);
            time = Math.floor(Ary[i][0]); 
        }
        ivAry.push(Math.floor(Ary[i][1]*1e4));
        ivAry.push(Math.floor(Ary[i][2]*1e6));
    }
    childLen.push(time);
    childLen.push(Ary.length);
    let len = childLen.length;
    let timeBn = [];
    timeBn.push(new BN(len))
    let buflen = Math.ceil((len+1)/8);
    var j=1;
    var index = 0;
    for (var i=0;i<buflen;i++){
        for (;j<8 && index<len;j++){
            let curBn = new BN(childLen[index]);
            timeBn[i] = timeBn[i].add(curBn.ushln(j*32));
            index++;
        }
        console.log(timeBn[i].toString(16));
        if(index<len){
            timeBn.push(new BN(0));
        }
        j = 0;
    }
    let ivBn = [];
    len = ivAry.length;
    let IvBn = [];
    IvBn.push(new BN(len))
    buflen = Math.ceil((len+1)/8);
    j=1;
    index = 0;
    for (var i=0;i<buflen;i++){
        for (;j<8 && index<len;j++){
//            console.log(ivAry[index]);
            let curBn = new BN(ivAry[index]);
            IvBn[i] = IvBn[i].add(curBn.ushln(j*32));
            index++;
        }
        console.log(IvBn[i].toString(16));
        if(index<len){
            IvBn.push(new BN(0));
        }
        j = 0;
    }
    let tx = await volInstance.setIvMatrix(1,optype,timeBn,IvBn);
    return tx;
}
/*
contract('ImpliedVol', function (accounts){
    it('ImpliedVol add IvMap', async function (){
        let volInstance = await ImpliedVol.deployed();
        let btcP = {}
        let btcC = {}
        let pAry = [];
        let cAry = [];
        let curTime =Date.now()-24*60*60*1000;
        for (var i=0;i<IvMax.length;i++){
            stringAry = IvMax[i][0].split("-");
            //var str2 = "Jan 19 2017 13:00:00";
            var strTime = stringAry[1];
            if (strTime.length == 6){
                strTime = "0"+strTime;
            }
            var timeStr = strTime.slice(2,5)+ " " + strTime.slice(0,2) + " 20"+strTime.slice(5)+ " 16:00:00";
            var time = (new Date(timeStr).getTime()-curTime)/1000;
            let timeBn = new BN(Math.floor(time));
            let priceBn = new BN(Math.floor(stringAry[2]*1e8));
            let IvBn = new BN(Math.floor(IvMax[i][1]*1e8));
            priceBn = priceBn.ushln(64);
            IvBn = IvBn.ushln(128);
            timeBn = timeBn.add(priceBn).add(IvBn);
            if (stringAry[3] == "P"){
                pAry.push([time,stringAry[2],timeBn]);
            }else{
                cAry.push([time,stringAry[2],timeBn]);
            }
        }
        function compare(a,b){
            if (Math.floor(a[0]) == Math.floor(b[0])){
                return a[1]-b[1];
            }else{
                return Math.floor(a[0]) - Math.floor(b[0]);
            }
        }
        pAry.sort(compare);
        cAry.sort(compare);
        let tx = await SendArray(volInstance,0,cAry);
        console.log(tx);
        tx = await SendArray(volInstance,1,pAry);
        console.log(tx);
        tx = await SendArray(volInstance,1,cAry);
        console.log(tx);
        tx = await SendArray(volInstance,0,pAry);
        console.log(tx);
//        let iv = await volInstance.calculateIv(1,0,3054861,9352*1e8);
//        console.log(iv[0].toString(10),iv[1].toString(10));
    });
});
*/
async function SendArray(volInstance,optype,Ary){
    let timeAry = []
    let childLen = []
    let ivAry = []
    let time = Math.floor(Ary[0][0])
    timeAry.push(time);
    for (var i=0;i<Ary.length;i++){
        if (time == Math.floor(Ary[i][0])){
            childLen[childLen.length-1]++;
        }else{ 
            time = Math.floor(Ary[i][0]); 
            timeAry.push(time);
            childLen.push(1);
        }
        ivAry.push(Ary[i][2]);
    }
    console.log(childLen);
    let tx = await volInstance.setIvMatrix(1,optype,childLen,ivAry);
    return tx;
}
let IvMax = [
    ["BTC-7AUG20-9750-P",0.4713],
    ["BTC-7AUG20-9750-C",0.4713],
    ["BTC-7AUG20-9500-P",0.4524],
    ["BTC-7AUG20-9500-C",0.4524],
    ["BTC-7AUG20-9250-P",0.4721],
    ["BTC-7AUG20-9250-C",0.4721],
    ["BTC-7AUG20-9000-P",0.4998],
    ["BTC-7AUG20-9000-C",0.4998],
    ["BTC-7AUG20-8750-P",0.5378],
    ["BTC-7AUG20-8750-C",0.5378],
    ["BTC-7AUG20-8500-P",0.5881],
    ["BTC-7AUG20-8500-C",0.5881],
    ["BTC-7AUG20-8250-P",0.6387],
    ["BTC-7AUG20-8250-C",0.6387],
    ["BTC-7AUG20-8000-P",0.6831],
    ["BTC-7AUG20-8000-C",0.6831],
    ["BTC-7AUG20-7750-P",0.7395],
    ["BTC-7AUG20-7750-C",0.7395],
    ["BTC-7AUG20-7500-P",0.7877],
    ["BTC-7AUG20-7500-C",0.7877],
    ["BTC-7AUG20-7250-P",0.8244],
    ["BTC-7AUG20-7250-C",0.8244],
    ["BTC-7AUG20-7000-P",0.8785],
    ["BTC-7AUG20-7000-C",0.8785],
    ["BTC-7AUG20-6750-P",0.925],
    ["BTC-7AUG20-6750-C",0.925],
    ["BTC-7AUG20-12500-P",0.7545],
    ["BTC-7AUG20-12500-C",0.7545],
    ["BTC-7AUG20-12250-P",0.7335],
    ["BTC-7AUG20-12250-C",0.7335],
    ["BTC-7AUG20-12000-P",0.7072],
    ["BTC-7AUG20-12000-C",0.7072],
    ["BTC-7AUG20-11750-P",0.6832],
    ["BTC-7AUG20-11750-C",0.6832],
    ["BTC-7AUG20-11500-P",0.6596],
    ["BTC-7AUG20-11500-C",0.6596],
    ["BTC-7AUG20-11250-P",0.6377],
    ["BTC-7AUG20-11250-C",0.6377],
    ["BTC-7AUG20-11000-P",0.5986],
    ["BTC-7AUG20-11000-C",0.5986],
    ["BTC-7AUG20-10750-P",0.5524],
    ["BTC-7AUG20-10750-C",0.5524],
    ["BTC-7AUG20-10500-P",0.5331],
    ["BTC-7AUG20-10500-C",0.5331],
    ["BTC-7AUG20-10250-P",0.5017],
    ["BTC-7AUG20-10250-C",0.5017],
    ["BTC-7AUG20-10000-P",0.4813],
    ["BTC-7AUG20-10000-C",0.4813],
    ["BTC-31JUL20-9750-P",0.4264],
    ["BTC-31JUL20-9750-C",0.4264],
    ["BTC-31JUL20-9500-P",0.4284],
    ["BTC-31JUL20-9500-C",0.4284],
    ["BTC-31JUL20-9250-P",0.4284],
    ["BTC-31JUL20-9250-C",0.4284],
    ["BTC-31JUL20-9000-P",0.4787],
    ["BTC-31JUL20-9000-C",0.4787],
    ["BTC-31JUL20-8750-P",0.5568],
    ["BTC-31JUL20-8750-C",0.5568],
    ["BTC-31JUL20-8500-P",0.6562],
    ["BTC-31JUL20-8500-C",0.6562],
    ["BTC-31JUL20-8000-P",0.7928],
    ["BTC-31JUL20-8000-C",0.7928],
    ["BTC-31JUL20-7500-P",0.9093],
    ["BTC-31JUL20-7500-C",0.9093],
    ["BTC-31JUL20-7000-P",0.9823],
    ["BTC-31JUL20-7000-C",0.9823],
    ["BTC-31JUL20-6500-P",0.9828],
    ["BTC-31JUL20-6500-C",0.9828],
    ["BTC-31JUL20-6000-P",0.983],
    ["BTC-31JUL20-6000-C",0.983],
    ["BTC-31JUL20-5500-P",0.9831],
    ["BTC-31JUL20-5500-C",0.9831],
    ["BTC-31JUL20-5000-P",0.9832],
    ["BTC-31JUL20-5000-C",0.9832],
    ["BTC-31JUL20-20000-P",1.0114],
    ["BTC-31JUL20-20000-C",1.0114],
    ["BTC-31JUL20-18000-P",0.9947],
    ["BTC-31JUL20-18000-C",0.9947],
    ["BTC-31JUL20-16000-P",0.9838],
    ["BTC-31JUL20-16000-C",0.9838],
    ["BTC-31JUL20-15000-P",0.9782],
    ["BTC-31JUL20-15000-C",0.9782],
    ["BTC-31JUL20-14000-P",0.9764],
    ["BTC-31JUL20-14000-C",0.9764],
    ["BTC-31JUL20-13000-P",0.9759],
    ["BTC-31JUL20-13000-C",0.9759],
    ["BTC-31JUL20-12000-P",0.8631],
    ["BTC-31JUL20-12000-C",0.8631],
    ["BTC-31JUL20-11500-P",0.7834],
    ["BTC-31JUL20-11500-C",0.7834],
    ["BTC-31JUL20-11000-P",0.6858],
    ["BTC-31JUL20-11000-C",0.6858],
    ["BTC-31JUL20-10500-P",0.5644],
    ["BTC-31JUL20-10500-C",0.5644],
    ["BTC-31JUL20-10000-P",0.4533],
    ["BTC-31JUL20-10000-C",0.4533],
    ["BTC-28AUG20-9500-P",0.5171],
    ["BTC-28AUG20-9500-C",0.5171],
    ["BTC-28AUG20-9000-P",0.5185],
    ["BTC-28AUG20-9000-C",0.5185],
    ["BTC-28AUG20-8500-P",0.5495],
    ["BTC-28AUG20-8500-C",0.5495],
    ["BTC-28AUG20-8000-P",0.6003],
    ["BTC-28AUG20-8000-C",0.6003],
    ["BTC-28AUG20-7500-P",0.6563],
    ["BTC-28AUG20-7500-C",0.6563],
    ["BTC-28AUG20-7000-P",0.7235],
    ["BTC-28AUG20-7000-C",0.7235],
    ["BTC-28AUG20-6500-P",0.7799],
    ["BTC-28AUG20-6500-C",0.7799],
    ["BTC-28AUG20-6000-P",0.8702],
    ["BTC-28AUG20-6000-C",0.8702],
    ["BTC-28AUG20-15000-P",0.7503],
    ["BTC-28AUG20-15000-C",0.7503],
    ["BTC-28AUG20-14000-P",0.6987],
    ["BTC-28AUG20-14000-C",0.6987],
    ["BTC-28AUG20-13000-P",0.6635],
    ["BTC-28AUG20-13000-C",0.6635],
    ["BTC-28AUG20-12000-P",0.6065],
    ["BTC-28AUG20-12000-C",0.6065],
    ["BTC-28AUG20-11500-P",0.5747],
    ["BTC-28AUG20-11500-C",0.5747],
    ["BTC-28AUG20-11000-P",0.5478],
    ["BTC-28AUG20-11000-C",0.5478],
    ["BTC-28AUG20-10500-P",0.5267],
    ["BTC-28AUG20-10500-C",0.5267],
    ["BTC-28AUG20-10000-P",0.5149],
    ["BTC-28AUG20-10000-C",0.5149],
    ["BTC-26MAR21-9000-P",0.7195],
    ["BTC-26MAR21-9000-C",0.7195],
    ["BTC-26MAR21-8000-P",0.7283],
    ["BTC-26MAR21-8000-C",0.7283],
    ["BTC-26MAR21-7000-P",0.7436],
    ["BTC-26MAR21-7000-C",0.7436],
    ["BTC-26MAR21-6000-P",0.7676],
    ["BTC-26MAR21-6000-C",0.7676],
    ["BTC-26MAR21-5000-P",0.8078],
    ["BTC-26MAR21-5000-C",0.8078],
    ["BTC-26MAR21-4000-P",0.8684],
    ["BTC-26MAR21-4000-C",0.8684],
    ["BTC-26MAR21-32000-P",0.843],
    ["BTC-26MAR21-32000-C",0.843],
    ["BTC-26MAR21-28000-P",0.8237],
    ["BTC-26MAR21-28000-C",0.8237],
    ["BTC-26MAR21-24000-P",0.7975],
    ["BTC-26MAR21-24000-C",0.7975],
    ["BTC-26MAR21-20000-P",0.7717],
    ["BTC-26MAR21-20000-C",0.7717],
    ["BTC-26MAR21-18000-P",0.7574],
    ["BTC-26MAR21-18000-C",0.7574],
    ["BTC-26MAR21-16000-P",0.7476],
    ["BTC-26MAR21-16000-C",0.7476],
    ["BTC-26MAR21-14000-P",0.7371],
    ["BTC-26MAR21-14000-C",0.7371],
    ["BTC-26MAR21-13000-P",0.7261],
    ["BTC-26MAR21-13000-C",0.7261],
    ["BTC-26MAR21-12000-P",0.7261],
    ["BTC-26MAR21-12000-C",0.7261],
    ["BTC-26MAR21-11000-P",0.7151],
    ["BTC-26MAR21-11000-C",0.7151],
    ["BTC-26MAR21-10000-P",0.7103],
    ["BTC-26MAR21-10000-C",0.7103],
    ["BTC-25SEP20-9500-P",0.5626],
    ["BTC-25SEP20-9500-C",0.5626],
    ["BTC-25SEP20-9000-P",0.5693],
    ["BTC-25SEP20-9000-C",0.5693],
    ["BTC-25SEP20-8500-P",0.5924],
    ["BTC-25SEP20-8500-C",0.5924],
    ["BTC-25SEP20-8000-P",0.6167],
    ["BTC-25SEP20-8000-C",0.6167],
    ["BTC-25SEP20-7000-P",0.6962],
    ["BTC-25SEP20-7000-C",0.6962],
    ["BTC-25SEP20-6000-P",0.8026],
    ["BTC-25SEP20-6000-C",0.8026],
    ["BTC-25SEP20-5000-P",0.9242],
    ["BTC-25SEP20-5000-C",0.9242],
    ["BTC-25SEP20-4500-P",0.9932],
    ["BTC-25SEP20-4500-C",0.9932],
    ["BTC-25SEP20-4000-P",1.0603],
    ["BTC-25SEP20-4000-C",1.0603],
    ["BTC-25SEP20-36000-P",1.044],
    ["BTC-25SEP20-36000-C",1.044],
    ["BTC-25SEP20-3500-P",1.1155],
    ["BTC-25SEP20-3500-C",1.1155],
    ["BTC-25SEP20-32000-P",1.044],
    ["BTC-25SEP20-32000-C",1.044],
    ["BTC-25SEP20-3000-P",1.1646],
    ["BTC-25SEP20-3000-C",1.1646],
    ["BTC-25SEP20-28000-P",0.9452],
    ["BTC-25SEP20-28000-C",0.9452],
    ["BTC-25SEP20-2500-P",1.3382],
    ["BTC-25SEP20-2500-C",1.3382],
    ["BTC-25SEP20-24000-P",0.8786],
    ["BTC-25SEP20-24000-C",0.8786],
    ["BTC-25SEP20-20000-P",0.8201],
    ["BTC-25SEP20-20000-C",0.8201],
    ["BTC-25SEP20-18000-P",0.7718],
    ["BTC-25SEP20-18000-C",0.7718],
    ["BTC-25SEP20-16000-P",0.7207],
    ["BTC-25SEP20-16000-C",0.7207],
    ["BTC-25SEP20-14000-P",0.661],
    ["BTC-25SEP20-14000-C",0.661],
    ["BTC-25SEP20-12000-P",0.5936],
    ["BTC-25SEP20-12000-C",0.5936],
    ["BTC-25SEP20-11000-P",0.5722],
    ["BTC-25SEP20-11000-C",0.5722],
    ["BTC-25SEP20-10500-P",0.5662],
    ["BTC-25SEP20-10500-C",0.5662],
    ["BTC-25SEP20-10000-P",0.5662],
    ["BTC-25SEP20-10000-C",0.5662],
    ["BTC-25JUL20-9875-P",0.4946],
    ["BTC-25JUL20-9875-C",0.4946],
    ["BTC-25JUL20-9750-P",0.4434],
    ["BTC-25JUL20-9750-C",0.4434],
    ["BTC-25JUL20-9625-P",0.3954],
    ["BTC-25JUL20-9625-C",0.3954],
    ["BTC-25JUL20-9500-P",0.3704],
    ["BTC-25JUL20-9500-C",0.3704],
    ["BTC-25JUL20-9375-P",0.4016],
    ["BTC-25JUL20-9375-C",0.4016],
    ["BTC-25JUL20-9250-P",0.4694],
    ["BTC-25JUL20-9250-C",0.4694],
    ["BTC-25JUL20-9125-P",0.5428],
    ["BTC-25JUL20-9125-C",0.5428],
    ["BTC-25JUL20-9000-P",0.6012],
    ["BTC-25JUL20-9000-C",0.6012],
    ["BTC-25JUL20-8875-P",0.6378],
    ["BTC-25JUL20-8875-C",0.6378],
    ["BTC-25JUL20-8750-P",0.6637],
    ["BTC-25JUL20-8750-C",0.6637],
    ["BTC-25JUL20-8625-P",0.7558],
    ["BTC-25JUL20-8625-C",0.7558],
    ["BTC-25JUL20-10375-P",0.6657],
    ["BTC-25JUL20-10375-C",0.6657],
    ["BTC-25JUL20-10250-P",0.6554],
    ["BTC-25JUL20-10250-C",0.6554],
    ["BTC-25JUL20-10125-P",0.6179],
    ["BTC-25JUL20-10125-C",0.6179],
    ["BTC-25JUL20-10000-P",0.524],
    ["BTC-25JUL20-10000-C",0.524],
    ["BTC-25DEC20-9000-P",0.6699],
    ["BTC-25DEC20-9000-C",0.6699],
    ["BTC-25DEC20-8000-P",0.6883],
    ["BTC-25DEC20-8000-C",0.6883],
    ["BTC-25DEC20-7000-P",0.7197],
    ["BTC-25DEC20-7000-C",0.7197],
    ["BTC-25DEC20-6000-P",0.7635],
    ["BTC-25DEC20-6000-C",0.7635],
    ["BTC-25DEC20-5000-P",0.8284],
    ["BTC-25DEC20-5000-C",0.8284],
    ["BTC-25DEC20-4000-P",0.9212],
    ["BTC-25DEC20-4000-C",0.9212],
    ["BTC-25DEC20-36000-P",0.8953],
    ["BTC-25DEC20-36000-C",0.8953],
    ["BTC-25DEC20-32000-P",0.8645],
    ["BTC-25DEC20-32000-C",0.8645],
    ["BTC-25DEC20-3000-P",1.05],
    ["BTC-25DEC20-3000-C",1.05],
    ["BTC-25DEC20-28000-P",0.8392],
    ["BTC-25DEC20-28000-C",0.8392],
    ["BTC-25DEC20-24000-P",0.798],
    ["BTC-25DEC20-24000-C",0.798],
    ["BTC-25DEC20-20000-P",0.7535],
    ["BTC-25DEC20-20000-C",0.7535],
    ["BTC-25DEC20-18000-P",0.7356],
    ["BTC-25DEC20-18000-C",0.7356],
    ["BTC-25DEC20-16000-P",0.7073],
    ["BTC-25DEC20-16000-C",0.7073],
    ["BTC-25DEC20-14000-P",0.6832],
    ["BTC-25DEC20-14000-C",0.6832],
    ["BTC-25DEC20-13000-P",0.6746],
    ["BTC-25DEC20-13000-C",0.6746],
    ["BTC-25DEC20-12000-P",0.6666],
    ["BTC-25DEC20-12000-C",0.6666],
    ["BTC-25DEC20-11000-P",0.6614],
    ["BTC-25DEC20-11000-C",0.6614],
    ["BTC-25DEC20-10000-P",0.6636],
    ["BTC-25DEC20-10000-C",0.6636],
    ["BTC-24JUL20-9750-P",0.505],
    ["BTC-24JUL20-9750-C",0.505],
    ["BTC-24JUL20-9500-P",0.3508],
    ["BTC-24JUL20-9500-C",0.3508],
    ["BTC-24JUL20-9250-P",0.4697],
    ["BTC-24JUL20-9250-C",0.4697],
    ["BTC-24JUL20-9000-P",0.6914],
    ["BTC-24JUL20-9000-C",0.6914],
    ["BTC-24JUL20-8750-P",0.6927],
    ["BTC-24JUL20-8750-C",0.6927],
    ["BTC-24JUL20-8500-P",0.6935],
    ["BTC-24JUL20-8500-C",0.6935],
    ["BTC-24JUL20-8250-P",0.6939],
    ["BTC-24JUL20-8250-C",0.6939],
    ["BTC-24JUL20-8000-P",0.6941],
    ["BTC-24JUL20-8000-C",0.6941],
    ["BTC-24JUL20-7750-P",0.6942],
    ["BTC-24JUL20-7750-C",0.6942],
    ["BTC-24JUL20-7500-P",0.6942],
    ["BTC-24JUL20-7500-C",0.6942],
    ["BTC-24JUL20-7250-P",0.6942],
    ["BTC-24JUL20-7250-C",0.6942],
    ["BTC-24JUL20-7000-P",0.6942],
    ["BTC-24JUL20-7000-C",0.6942],
    ["BTC-24JUL20-6750-P",0.6942],
    ["BTC-24JUL20-6750-C",0.6942],
    ["BTC-24JUL20-12250-P",0.6572],
    ["BTC-24JUL20-12250-C",0.6572],
    ["BTC-24JUL20-12000-P",0.6571],
    ["BTC-24JUL20-12000-C",0.6571],
    ["BTC-24JUL20-11750-P",0.6571],
    ["BTC-24JUL20-11750-C",0.6571],
    ["BTC-24JUL20-11500-P",0.657],
    ["BTC-24JUL20-11500-C",0.657],
    ["BTC-24JUL20-11250-P",0.6569],
    ["BTC-24JUL20-11250-C",0.6569],
    ["BTC-24JUL20-11000-P",0.6569],
    ["BTC-24JUL20-11000-C",0.6569],
    ["BTC-24JUL20-10750-P",0.6568],
    ["BTC-24JUL20-10750-C",0.6568],
    ["BTC-24JUL20-10500-P",0.6568],
    ["BTC-24JUL20-10500-C",0.6568],
    ["BTC-24JUL20-10250-P",0.6568],
    ["BTC-24JUL20-10250-C",0.6568],
    ["BTC-24JUL20-10000-P",0.6568],
    ["BTC-24JUL20-10000-C",0.6568]
]