pragma solidity ^0.4.26;
import "../modules/Ownable.sol";
interface IFNXMinePool {
    function mintMinerCoin(address account,uint256 amount) external;
    function burnMinerCoin(address account,uint256 amount) external;
    function addMinerBalance(address account,uint256 amount) external;
}
contract ImportFNXMinePool is Ownable{
    IFNXMinePool internal _FnxMinePool;
    function getOptionsPriceAddress() public view returns(address){
        return address(_FnxMinePool);
    }
    function setOptionsPriceAddress(address fnxMinePool)public onlyOwner{
        _FnxMinePool = IFNXMinePool(fnxMinePool);
    }
}