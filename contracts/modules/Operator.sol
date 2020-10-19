pragma solidity =0.5.16;
import './Ownable.sol';
import "./whiteList.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * each operator can be granted exclusive access to specific functions.
 *
 */
contract Operator is Ownable {
    using whiteListAddress for address[];
    address[] private _operatorList;
    /**
     * @dev modifier, every operator can be granted exclusive access to specific functions. 
     *
     */
    modifier onlyOperator() {
        require(_operatorList.isEligibleAddress(msg.sender),"Managerable: caller is not the Operator");
        _;
    }
    /**
     * @dev modifier, Only indexed operator can be granted exclusive access to specific functions. 
     *
     */
    modifier onlyOperatorIndex(uint256 index) {
        require(_operatorList.length>index && _operatorList[index] == msg.sender,"Operator: caller is not the eligible Operator");
        _;
    }
    /**
     * @dev add a new operator by owner. 
     *
     */
    function addOperator(address addAddress)public onlyOwner{
        _operatorList.addWhiteListAddress(addAddress);
    }
    /**
     * @dev modify indexed operator by owner. 
     *
     */
    function setOperator(uint256 index,address addAddress)public onlyOwner{
        _operatorList[index] = addAddress;
    }
    /**
     * @dev remove operator by owner. 
     *
     */
    function removeOperator(address removeAddress)public onlyOwner returns (bool){
        return _operatorList.removeWhiteListAddress(removeAddress);
    }
    /**
     * @dev get all operators. 
     *
     */
    function getOperator()public view returns (address[] memory) {
        return _operatorList;
    }
    /**
     * @dev set all operators by owner. 
     *
     */
    function setOperators(address[] memory operators)public onlyOwner {
        _operatorList = operators;
    }
}