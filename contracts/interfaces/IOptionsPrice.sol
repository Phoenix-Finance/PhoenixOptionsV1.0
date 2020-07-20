pragma solidity ^0.4.26;
import "../modules/Ownable.sol";
interface IOptionsPrice {
    function getOptionsPrice(uint256 currentPrice, uint256 strikePrice, uint256 expiration,uint8 optType)external view returns (uint256);
    function getOptionsPrice_iv(uint256 currentPrice, uint256 strikePrice, uint256 expiration,
                uint256 ivNumerator,uint256 ivDenominator,uint8 optType)external view returns (uint256);
}
contract ImportOptionsPrice is Ownable{
    IOptionsPrice internal _optionsPrice;
    function getOptionsPriceAddress() public view returns(address){
        return address(_optionsPrice);
    }
    function setOptionsPriceAddress(address optionsPrice)public onlyOwner{
        _optionsPrice = IOptionsPrice(optionsPrice);
    }
}