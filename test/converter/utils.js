
sleep = function sleep(milliSeconds) {
  var startTime = new Date().getTime();
  while (new Date().getTime() < startTime + milliSeconds);
};

pause = async function pause(web3,endBlk) {
  let blkNum = await web3.eth.getBlockNumber();;
  while (blkNum <= endBlk){
    sleep(1000);
    blkNum = await web3.eth.getBlockNumber();
    console.log(blkNum)
  }
  console.log("pause break")
};

exports.sleep = sleep;
exports.pause = pause;
