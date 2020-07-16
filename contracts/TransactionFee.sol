pragma solidity ^0.4.26;
import "./AddressWhiteList.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
    /**
     * @dev Implementation of a transaction fee manager.
     */
contract TransactionFee is AddressWhiteList {
    modifier nonContract() {                // contracts pls go
        require(tx.origin == msg.sender);
        _;
    }

    using SafeMath for uint256;
    /* represents floting point numbers, where number = value * 10 ** exponent
    i.e 0.1 = 10 * 10 ** -2 */
    struct Number {
        uint256 value;
        int32 exponent;
    }
    event TransferPayback(address indexed recieptor,address indexed collateral,uint256 payback);
    // The total fees accumulated in the contract
    mapping (address => uint256) 	public managerFee;
    // Number(3,-3) = 0.3%
    Number public transactionFee = Number(3, -3);
     /**
     * @dev Returns the rate of trasaction fee.
     */   
    function getTransactionFee()public view returns (uint256,int32){
        return (transactionFee.value,transactionFee.exponent);
    }
    /**
     * @dev set the rate of trasaction fee.
     * @param value the significant figures of transaction fee .
     * @param exponent the exponent figures of transaction fee.
     * transaction fee = Number(value,exponent);
     */   
    function setTransactionFee(uint256 value,int32 exponent)public onlyOwner{
        transactionFee.value = value;
        transactionFee.exponent = exponent;
    }
    function getFeeBalance(address settlement)public view returns(uint256){
        return managerFee[settlement];
    }
    function getAllFeeBalances()public view returns(address[],uint256[]){
        uint256[] memory balances = new uint256[](whiteList.length);
        for (uint256 i=0;i<whiteList.length;i++){
            balances[i] = managerFee[whiteList[i]];
        }
        return (whiteList,balances);
    }
    function redeem(address currency)public onlyOwner{
        uint256 fee = managerFee[currency];
        require (fee > 0, "It's empty balance");
        managerFee[currency] = 0;
         if (currency == address(0)){
            msg.sender.transfer(fee);
        }else{
        IERC20 currencyToken = IERC20(currency);
           currencyToken.transfer(msg.sender,fee);
        }
    }
    function redeemAll()public onlyOwner{
        for (uint256 i=0;i<whiteList.length;i++){
            uint256 fee = managerFee[whiteList[i]];
            if (fee > 0){
                managerFee[whiteList[i]] = 0;
                IERC20 collateralToken = IERC20(whiteList[i]);
                if (whiteList[i] == address(0)){
                    msg.sender.transfer(fee);
                }else{
                    collateralToken.transfer(msg.sender,fee);
                }
            }
        }
    }
        /**
      * @dev  transfer collateral payback amount;
      * @param recieptor payback recieptor
      * @param collateral collateral address
      * @param payback amount of collateral will payback 
      */
    function _transferPayback(address recieptor,address collateral,uint256 payback)internal{
        if (payback == 0){
            return;
        }
        if (collateral == address(0)){
            recieptor.transfer(payback);
        }else{
            IERC20 collateralToken = IERC20(collateral);
            collateralToken.transfer(recieptor,payback);
        }
        emit TransferPayback(recieptor,collateral,payback);
    }
    function _addTransactionFee(address settleMent,uint256 amount) internal {
        managerFee[settleMent] = managerFee[settleMent].add(amount);
    }
    function _calNumberMulUint(Number number,uint256 value) internal pure returns (uint256){
        uint256 result = number.value.mul(value);
        if (number.exponent > 0) {
            result = result.mul(10**uint256(number.exponent));
        } else {
            result = result.div(10**uint256(-1*number.exponent));
        }
        return result;
    }
}