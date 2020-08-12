pragma solidity ^0.4.26;
import "../modules/Ownable.sol";
interface IFnxPriceDb{
    function getPrice(string symbol) external view returns(uint256);
}
contract ImportFnxPriceDb is Ownable{
    IFnxPriceDb internal _FnxPriceDb;
    function getFnxPriceDbAddress() public view returns(address){
        return address(_FnxPriceDb);
    }
    function setFnxPriceDbAddress(address priceAddr)public onlyOwner{
        _FnxPriceDb = IFnxPriceDb(priceAddr);
    }
}