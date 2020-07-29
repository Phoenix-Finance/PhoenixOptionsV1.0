pragma solidity ^0.4.26;
import "./interfaces/IFNXMinePool.sol";
import "./modules/SafeMath.sol";
contract MinePoolManager is ImportFNXMinePool{
    using SafeMath for uint256;
    uint256 buyerMinerRate;
    uint256 constant _calDecimal = 1000;
    constructor () public{
    }
    function setBuyerMinerRate(uint256 thousandths) public onlyOwner{
        buyerMinerRate = thousandths;
    }
    function getBuyerMinerRate() public view returns(uint256){
        return buyerMinerRate;
    }
    function AddBuyerMineCoin(address mineCoin,address account,uint256 amount) internal {
        uint256 mineAmount = amount.mul(buyerMinerRate).div(_calDecimal);
        _FnxMinePool.addMinerBalance(account,mineCoin,mineAmount);
    }
}