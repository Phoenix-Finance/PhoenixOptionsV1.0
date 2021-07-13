pragma solidity =0.5.16;
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * each operator can be granted exclusive access to specific functions.
 *
 */
contract Operator {
    mapping(uint256=>address) internal _operators;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OriginTransferred(address indexed previousOrigin, address indexed newOrigin);
    event OperatorTransferred(address indexed previousOperator, address indexed newOperator,uint256 indexed index);
    constructor()  public{
        _operators[0] = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
        _operators[1] = tx.origin;
        emit OriginTransferred(address(0), tx.origin);
    }
    /**
     * @dev modifier, Only indexed operator can be granted exclusive access to specific functions. 
     *
     */
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _operators[0];
    }
        /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Operator: caller is not the owner");
        _;
    }
    modifier onlyManager() {
        require(msg.sender == _operators[2], "Operator: caller is not the manager");
        _;
    }
    modifier onlyOrigin() {
        require(msg.sender == _operators[1], "Operator: caller is not the origin");
        _;
    }
    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _operators[0];
    }
    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_operators[0], address(0));
        _operators[0] = address(0);
    }
    function renounceOrigin() public onlyOrigin {
        emit OriginTransferred(_operators[1], address(0));
        _operators[1] = address(0);
    }
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    function transferOrigin(address newOrigin) public onlyOrigin {
        require(newOrigin != address(0), "Operator: new origin is the zero address");
        emit OwnershipTransferred(_operators[1], newOrigin);
        _operators[1] = newOrigin;
    }
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Operator: new owner is the zero address");
        emit OwnershipTransferred(_operators[0], newOwner);
        _operators[0] = newOwner;
    }
    modifier onlyOperator(uint256 index) {
        require(_operators[index] == msg.sender,"Operator: caller is not the eligible Operator");
        _;
    }
    modifier onlyOperator2(uint256 index1,uint256 index2) {
        require(_operators[index1] == msg.sender || _operators[index2] == msg.sender,"Operator: caller is not the eligible Operator");
        _;
    }
    modifier onlyOperator3(uint256 index1,uint256 index2,uint256 index3) {
        require(_operators[index1] == msg.sender || _operators[index2] == msg.sender || _operators[index3] == msg.sender,
            "Operator: caller is not the eligible Operator");
        _;
    }
    function setManager(address newManager) public onlyOwner{
        emit OperatorTransferred(_operators[2], newManager,2);
        _operators[2] = newManager;
    }
    /**
     * @dev modify indexed operator by owner. 
     *
     */
    function setOperator(uint256 index,address newAddress)public onlyOperator2(0,1) {
        require(index>2, "Index must greater than 2");
        emit OperatorTransferred(_operators[index], newAddress,index);
        _operators[index] = newAddress;
    }
    function getOperator(uint256 index)public view returns (address) {
        return _operators[index];
    }
}