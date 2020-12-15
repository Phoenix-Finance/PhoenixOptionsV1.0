pragma solidity =0.5.16;
import "../optionsPrice.sol";
contract OptionsPriceTest is OptionsPrice{
    constructor (address ivContract) OptionsPrice(ivContract) public{
    }
        /**
     * @dev calculate option's price using B_S formulas
     * @param currentPrice current underlying price.
     * @param strikePrice option's strike price.
     * @param expiration option's expiration left time. Equal option's expiration timestamp - now.
     * @param underlying option's underlying id, 1 for BTC, 2 for ETH.
     * @param optType option's type, 0 for CALL, 2 for PUT.
     */
    uint256 fakeOptionPrice = 0;
    function getOptionsPrice(uint256 currentPrice, uint256 strikePrice, uint256 expiration,uint32 underlying,uint8 optType)public view returns (uint256){
        expiration = expiration * 4000;
        if(fakeOptionPrice>0) {
            return fakeOptionPrice;
        }
        return OptionsPrice.getOptionsPrice(currentPrice,strikePrice,expiration,underlying,optType);
    }
    /**
     * @dev calculate option's price using B_S formulas with user input iv.
     * @param currentPrice current underlying price.
     * @param strikePrice option's strike price.
     * @param expiration option's expiration left time. Equal option's expiration timestamp - now.
     * @param ivNumerator user input iv numerator.
     * @param optType option's type, 0 for CALL, 2 for PUT.
     */
    function getOptionsPrice_iv(uint256 currentPrice, uint256 strikePrice, uint256 expiration,
            uint256 ivNumerator,uint8 optType)public pure returns (uint256){
        expiration = expiration * 4000;
        return OptionsPrice.getOptionsPrice_iv(currentPrice,strikePrice,expiration,ivNumerator,optType);
    }

    function setOptionsPrice(uint256 optionPrice) public{
        fakeOptionPrice = optionPrice;
    }

}
