pragma solidity ^0.4.26;
import "../modules/Ownable.sol";
interface IFCTCoin {
    function lockedBalanceOf(address account) external view returns (uint256);
    function lockedWorthOf(address account) external view returns (uint256);
    function getLockedBalance(address account) external view returns (uint256,uint256);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
    function burnLocked(address account, uint256 amount) external;
    function addlockBalance(address account, uint256 amount,uint256 lockedWorth)external; 
    function getTotalLockedWorth() external view returns (uint256);
}
contract ImportIFCTCoin is Ownable{
    IFCTCoin internal _FCTCoin;
    function getFCTCoinAddress() public view returns(address){
        return address(_FCTCoin);
    }
    function setFCTCoinAddress(address FctCoinAddr)public onlyOwner{
        _FCTCoin = IFCTCoin(FctCoinAddr);
    }
}