pragma solidity =0.5.16;
import "../modules/Ownable.sol";
interface IFnxPriceDb{
    function getPrice(string calldata symbol) external view returns(uint256);
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