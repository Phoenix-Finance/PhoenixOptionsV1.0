pragma solidity ^0.4.26;
    /**
     * @dev Implementation of a whiteList filters a eligible uint32.
     */
library whiteListUint32 {
    // add whiteList
    function addWhiteListUint32(uint32[] storage whiteList,uint32 temp) internal{
        uint256 index = _getEligibleIndexUint32(whiteList,temp);
        if (index==whiteList.length){
            whiteList.push(temp);
        }
    }
    function removeWhiteListUint32(uint32[] storage whiteList,uint32 temp)internal returns (bool) {
        uint256 index = _getEligibleIndexUint32(whiteList,temp);
        if (index<whiteList.length){
            if (index!=whiteList.length-1) {
                whiteList[index] = whiteList[whiteList.length-1];
            }
            whiteList.length--;
            return true;
        }
        return false;
    }
    function checkEligibleUint32(uint32[] storage whiteList,uint32 temp) internal view{
        uint256 index = _getEligibleIndexUint32(whiteList,temp);
        require(index<whiteList.length,"whiteList: using invalid value");
    }
    function isEligibleUint32(uint32[] storage whiteList,uint32 temp) internal view returns (bool){
        uint256 index = _getEligibleIndexUint32(whiteList,temp);
        return index<whiteList.length;
    }
    function _getEligibleIndexUint32(uint32[] storage whiteList,uint32 temp) internal view returns (uint256){
        for (uint256 i=0;i<whiteList.length;i++){
            if (whiteList[i] == temp)
                break;
        }
        return i;
    }
}
library whiteListUint256 {
    // add whiteList
    function addWhiteListUint256(uint256[] storage whiteList,uint256 temp) internal{
        uint256 index = _getEligibleIndexUint256(whiteList,temp);
        if (index==whiteList.length){
            whiteList.push(temp);
        }
    }
    function removeWhiteListUint256(uint256[] storage whiteList,uint256 temp)internal returns (bool) {
        uint256 index = _getEligibleIndexUint256(whiteList,temp);
        if (index<whiteList.length){
            if (index!=whiteList.length-1) {
                whiteList[index] = whiteList[whiteList.length-1];
            }
            whiteList.length--;
            return true;
        }
        return false;
    }
    function checkEligibleUint256(uint256[] storage whiteList,uint256 temp) internal view{
        uint256 index = _getEligibleIndexUint256(whiteList,temp);
        require(index<whiteList.length,"whiteList: using invalid value");
    }
    function isEligibleUint256(uint256[] storage whiteList,uint256 temp) internal view returns (bool){
        uint256 index = _getEligibleIndexUint256(whiteList,temp);
        return index<whiteList.length;
    }
    function _getEligibleIndexUint256(uint256[] storage whiteList,uint256 temp) internal view returns (uint256){
        for (uint256 i=0;i<whiteList.length;i++){
            if (whiteList[i] == temp)
                break;
        }
        return i;
    }
}
library whiteListAddress {
    // add whiteList
    function addWhiteListAddress(address[] storage whiteList,address temp) internal{
        uint256 index = _getEligibleIndexAddress(whiteList,temp);
        if (index==whiteList.length){
            whiteList.push(temp);
        }
    }
    function removeWhiteListAddress(address[] storage whiteList,address temp)internal returns (bool) {
        uint256 index = _getEligibleIndexAddress(whiteList,temp);
        if (index<whiteList.length){
            if (index!=whiteList.length-1) {
                whiteList[index] = whiteList[whiteList.length-1];
            }
            whiteList.length--;
            return true;
        }
        return false;
    }
    function checkEligibleAddress(address[] storage whiteList,address temp) internal view{
        uint256 index = _getEligibleIndexAddress(whiteList,temp);
        require(index<whiteList.length,"whiteList: using invalid address");
    }
    function isEligibleAddress(address[] storage whiteList,address temp) internal view returns (bool){
        uint256 index = _getEligibleIndexAddress(whiteList,temp);
        return index<whiteList.length;
    }
    function _getEligibleIndexAddress(address[] storage whiteList,address temp) internal view returns (uint256){
        for (uint256 i=0;i<whiteList.length;i++){
            if (whiteList[i] == temp)
                break;
        }
        return i;
    }
}