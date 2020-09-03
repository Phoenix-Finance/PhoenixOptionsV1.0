pragma solidity =0.5.16;
import "../modules/Ownable.sol";
interface IFNXMinePool {
    function transferMinerCoin(address account,address recieptor,uint256 amount)external;
    function mintMinerCoin(address account,uint256 amount) external;
    function burnMinerCoin(address account,uint256 amount) external;
    function addMinerBalance(address account,uint256 amount) external;
}
contract ImportFNXMinePool is Ownable{
    IFNXMinePool internal _FnxMinePool;
    function getFNXMinePoolAddress() public view returns(address){
        return address(_FnxMinePool);
    }
    function setFNXMinePoolAddress(address fnxMinePool)public onlyOwner{
        _FnxMinePool = IFNXMinePool(fnxMinePool);
    }
}