pragma solidity =0.5.16;

import "../PhoenixModules/modules/SafeMath.sol";
import "../PhoenixModules/ERC20/IERC20.sol";
import "./CollateralData.sol";
import "../PhoenixModules/ERC20/safeErc20.sol";
    /**
     * @dev Implementation of a transaction fee manager.
     */
contract TransactionFee is CollateralData {
    using SafeMath for uint256;
    constructor() internal{
    }
    function initialize() public{
        versionUpdater.initialize();
        FeeRates.push(50);
        FeeRates.push(0);
        FeeRates.push(50);
        FeeRates.push(0);
        FeeRates.push(0);
    }
    function getFeeRateAll()public view returns (uint32[] memory){
        return FeeRates;
    }
    function getFeeRate(uint256 feeType)public view returns (uint32){
        return FeeRates[feeType];
    }
    /**
     * @dev set the rate of trasaction fee.
     * @param feeType the transaction fee type
     * @param thousandth the numerator of transaction fee .
     * transaction fee = thousandth/1000;
     */   
    function setTransactionFee(uint256 feeType,uint32 thousandth)public onlyOrigin{
        FeeRates[feeType] = thousandth;
    }

    function getFeeBalance(address settlement)public view returns(uint256){
        return feeBalances[settlement];
    }
    function redeem(address currency)public onlyOrigin nonReentrant{
        uint256 fee = feeBalances[currency];
        require (fee > 0, "It's empty balance");
        feeBalances[currency] = 0;
        _redeem(msg.sender,currency,fee);
    }
    function _addTransactionFee(address settlement,uint256 amount) internal {
        if (amount > 0){
            feeBalances[settlement] = feeBalances[settlement]+amount;
            emit AddFee(settlement,amount);
        }
    }
    function calculateFee(uint256 feeType,uint256 amount)public view returns (uint256){
        return FeeRates[feeType]*amount/1000;
    }
    /**
      * @dev  transfer settlement payback amount;
      * @param recieptor payback recieptor
      * @param settlement settlement address
      * @param payback amount of settlement will payback 
      */
    function _transferPaybackAndFee(address payable recieptor,address settlement,uint256 payback,uint256 feeType)internal{
        if (payback == 0){
            return;
        }
        uint256 fee = FeeRates[feeType]*payback/1000;
        _transferPayback(recieptor,settlement,payback-fee);
        _addTransactionFee(settlement,fee);
    }
    /**
      * @dev  transfer settlement payback amount;
      * @param recieptor payback recieptor
      * @param settlement settlement address
      * @param payback amount of settlement will payback 
      */
    function _transferPayback(address payable recieptor,address settlement,uint256 payback)internal{
        if (payback == 0){
            return;
        }
        _redeem(recieptor,settlement,payback);
    }
}