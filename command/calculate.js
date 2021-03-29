let exp = 0.05;
console.log(Math.round(-8.99*4294967296))
console.log(Math.round(9*4294967296))
console.log(Math.round(0.05*4294967296))


for (var i=0;i<9;i++){
    let txt = "";
    for (var j=1;j<11;j++){
        txt += Math.round(Math.pow(i*10+j,exp)*4294967296) + ",";
    }
    console.log(txt)
}