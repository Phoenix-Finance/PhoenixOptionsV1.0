pragma solidity ^0.4.26;
import "./interfaces/IFNXMinePool.sol";
import "./modules/SafeMath.sol";
contract MinePoolManager is ImportFNXMinePool{
    using SafeMath for uint256;
    mapping(address=>uint256) collateralMinerRate;
    mapping(address=>uint256) buyerMinerRate;
    uint256 constant _calDecimal = 1000;
    function setCollateralMinerRate(address collateral,uint256 thousandths) public onlyOwner{
        collateralMinerRate[collateral] = thousandths;
    }
    function setBuyerMinerRate(address settlement,uint256 thousandths) public onlyOwner{
        collateralMinerRate[settlement] = thousandths;
    }
    function getCollateralMinerRate(address collateral) public view returns(uint256){
        return collateralMinerRate[collateral];
    }
    function getBuyerMinerRate(address settlement) public view returns(uint256){
        return collateralMinerRate[settlement];
    }
    function addCollateralMiner(address acount,address collateral,uint256 amount) internal {
        uint256 mineAmount = amount.mul(collateralMinerRate[collateral]).div(_calDecimal);
        _FnxMinePool.mintMinerCoin(acount,mineAmount);
    }
    function burnCollateralMiner(address acount,address collateral,uint256 amount) internal {
        uint256 mineAmount = amount.mul(collateralMinerRate[collateral]).div(_calDecimal);
        _FnxMinePool.burnMinerCoin(acount,mineAmount);
    }
    function AddBuyerMineCoin(address acount,address settlement,uint256 amount) internal {
        uint256 mineAmount = amount.mul(buyerMinerRate[settlement]).div(_calDecimal);
        _FnxMinePool.addMinerBalance(acount,mineAmount);
    }
}