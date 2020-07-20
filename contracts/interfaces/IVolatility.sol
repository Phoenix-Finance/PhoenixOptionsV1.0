pragma solidity ^0.4.26;
import "../modules/Ownable.sol";
interface IVolatility {
    function calculateIv(uint256 expiration,uint256 price)external view returns (uint256,uint256);
}
contract ImportVolatility is Ownable{
    IVolatility internal _volatility;
    function getVolatilityAddress() public view returns(address){
        return address(_volatility);
    }
    function setVolatilityAddress(address volatility)public onlyOwner{
        _volatility = IVolatility(volatility);
    }
}