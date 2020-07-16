pragma solidity ^0.4.26;
import "./SafeMath.sol";
import "./CollateralPool.sol";
import "./IOptionsPrice.sol";
contract OptionsMangerV2 is CollateralPool {
    using SafeMath for uint256;
    IOptionsPrice internal optionsPrice;
    function buyOption(address settlement,uint256 settlementAmount, uint256 strikePrice,uint32 underlying,
        uint256 expiration,uint256 amount,uint8 optType)public payable{
        require(isEligibleUnderlyingAsset(underlying) , "underlying is unsupported asset");
        settlementAmount = getPayableAmount(settlement,settlementAmount);
        require(settlementAmount>0 , "settlement amount is zero!");
        uint256 currentPrice = _oracle.getUnderlyingPrice(underlying);
        uint256 optPrice = optionsPrice.getOptionsPrice(currentPrice,strikePrice,expiration,optType);
        uint256 allPay = optPrice.mul(amount);
        uint256 settlePrice = _oracle.getPrice(settlement);
        uint256 allSettle = settlePrice.mul(settlementAmount);
        require(allSettle>=allPay,"settlement asset is insufficient!");
    }
    function sellOption()public payable{

    }
    function exerciseOption()public payable{

    }

}