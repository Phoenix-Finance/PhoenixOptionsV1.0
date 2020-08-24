pragma solidity ^0.4.26;
import "./AddressWhiteList.sol";
import "./SafeMath.sol";
import "../interfaces/IERC20.sol";
    /**
     * @dev Implementation of a transaction fee manager.
     */
contract TransactionFee is AddressWhiteList {
    using SafeMath for uint256;
    struct fraction{
        uint256 numerator;
        uint256 denominator;
    }
    event RedeemFee(address indexed recieptor,address indexed settlement,uint256 payback);
    event AddFee(address indexed settlement,uint256 payback);
    event TransferPayback(address indexed recieptor,address indexed settlement,uint256 payback);
    // The total fees accumulated in the contract
    mapping (address => uint256) 	private feeBalances;
    fraction[] private FeeRates;
     /**
     * @dev Returns the rate of trasaction fee.
     */   
    uint256 constant internal buyFee = 0;
    uint256 constant internal sellFee = 1;
    uint256 constant internal exerciseFee = 2;
    uint256 constant internal addColFee = 3;
    uint256 constant internal redeemColFee = 4;
    constructor() internal{
        FeeRates.push(fraction(0, 1000));
        FeeRates.push(fraction(50, 1000));
        FeeRates.push(fraction(0, 1000));
        FeeRates.push(fraction(0, 1000));
        FeeRates.push(fraction(0, 1000));
    }
    function getFeeRate(uint256 feeType)public view returns (uint256,uint256){
        fraction storage feeRate = _getFeeRate(feeType);
        return (feeRate.numerator,feeRate.denominator);
    }
    /**
     * @dev set the rate of trasaction fee.
     * @param feeType the transaction fee type
     * @param numerator the numerator of transaction fee .
     * @param denominator thedenominator of transaction fee.
     * transaction fee = numerator/denominator;
     */   
    function setTransactionFee(uint256 feeType,uint256 numerator,uint256 denominator)public onlyOwner{
        fraction storage rate = _getFeeRate(feeType);
        rate.numerator = numerator;
        rate.denominator = denominator;
    }

    function getFeeBalance(address settlement)public view returns(uint256){
        return feeBalances[settlement];
    }
    function getAllFeeBalances()public view returns(address[],uint256[]){
        uint256[] memory balances = new uint256[](whiteList.length);
        for (uint256 i=0;i<whiteList.length;i++){
            balances[i] = feeBalances[whiteList[i]];
        }
        return (whiteList,balances);
    }
    function redeem(address currency)public onlyOwner{
        uint256 fee = feeBalances[currency];
        require (fee > 0, "It's empty balance");
        feeBalances[currency] = 0;
         if (currency == address(0)){
            msg.sender.transfer(fee);
        }else{
            IERC20 currencyToken = IERC20(currency);
           currencyToken.transfer(msg.sender,fee);
        }
        emit RedeemFee(msg.sender,currency,fee);
    }
    function redeemAll()public onlyOwner{
        for (uint256 i=0;i<whiteList.length;i++){
            redeem(whiteList[i]);
        }
    }
    function _addTransactionFee(address settlement,uint256 amount) internal {
        if (amount > 0){
            feeBalances[settlement] = feeBalances[settlement]+amount;
            emit AddFee(settlement,amount);
        }
    }
    function calculateFee(uint256 feeType,uint256 amount)public view returns (uint256){
        fraction storage feeRate = _getFeeRate(feeType);
        uint256 result = feeRate.numerator.mul(amount);
        return result/feeRate.denominator;
    }
    function _getFeeRate(uint256 feeType)internal view returns(fraction storage){
        require(feeType<FeeRates.length,"fee type is valid!");
        return FeeRates[feeType];
    }
    /**
      * @dev  transfer settlement payback amount;
      * @param recieptor payback recieptor
      * @param settlement settlement address
      * @param payback amount of settlement will payback 
      */
    function _transferPaybackAndFee(address recieptor,address settlement,uint256 payback,uint256 feeType)internal{
        if (payback == 0){
            return;
        }
        uint256 fee = calculateFee(feeType,payback);
        _transferPayback(recieptor,settlement,payback-fee);
        _addTransactionFee(settlement,fee);
    }
    /**
      * @dev  transfer settlement payback amount;
      * @param recieptor payback recieptor
      * @param settlement settlement address
      * @param payback amount of settlement will payback 
      */
    function _transferPayback(address recieptor,address settlement,uint256 payback)internal{
        if (payback == 0){
            return;
        }
        if (settlement == address(0)){
            recieptor.transfer(payback);
        }else{
            IERC20 collateralToken = IERC20(settlement);
            collateralToken.transfer(recieptor,payback);
        }
        emit TransferPayback(recieptor,settlement,payback);
    }
}