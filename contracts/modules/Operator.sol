pragma solidity ^0.4.11;
import './Ownable.sol';
import "./whiteList.sol";
contract Operator is Ownable {

    address[] private _operatorList;
    modifier onlyOperator() {
        require(whiteListAddress.isEligibleAddress(_operatorList,msg.sender),"Managerable: caller is not the Operator");
        _;
    }
    modifier onlyOperatorIndex(uint256 index) {
        require(_operatorList.length>index && _operatorList[index] == msg.sender,"Managerable: caller is not the eligible Operator");
        _;
    }
    function addOperator(address addAddress)public onlyOwner{
        whiteListAddress.addWhiteListAddress(_operatorList,addAddress);
    }
    function setOperator(uint256 index,address addAddress)public onlyOwner{
        _operatorList[index] = addAddress;
    }
    function removeOperator(address removeAddress)public onlyOwner returns (bool){
        return whiteListAddress.removeWhiteListAddress(_operatorList,removeAddress);
    }
    function getOperator()public view returns (address[]) {
        return _operatorList;
    }
}