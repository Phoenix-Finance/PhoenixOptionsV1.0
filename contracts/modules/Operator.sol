pragma solidity ^0.4.11;
import './Ownable.sol';
import "./whiteList.sol";
contract Operator is Ownable {
    using whiteListAddress for address[];
    address[] private _operatorList;
    modifier onlyOperator() {
        require(_operatorList.isEligibleAddress(msg.sender),"Managerable: caller is not the Operator");
        _;
    }
    modifier onlyOperatorIndex(uint256 index) {
        require(_operatorList.length>index && _operatorList[index] == msg.sender,"Managerable: caller is not the eligible Operator");
        _;
    }
    function addOperator(address addAddress)public onlyOwner{
        _operatorList.addWhiteListAddress(addAddress);
    }
    function setOperator(uint256 index,address addAddress)public onlyOwner{
        _operatorList[index] = addAddress;
    }
    function removeOperator(address removeAddress)public onlyOwner returns (bool){
        return _operatorList.removeWhiteListAddress(removeAddress);
    }
    function getOperator()public view returns (address[]) {
        return _operatorList;
    }
}