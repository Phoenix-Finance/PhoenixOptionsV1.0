pragma solidity ^0.4.26;
import "./SharedCoin.sol";
import "./modules/SafeMath.sol";
import "./modules/Managerable.sol";
import "./interfaces/IFNXMinePool.sol";
contract FPTCoin is SharedCoin,ImportFNXMinePool,Managerable {
    using SafeMath for uint256;
    string public name = "finnexus pool token";
    string public symbol = "FPT";
    
    uint256 internal _totalLockedWorth = 0;
    mapping (address => uint256) internal lockedBalances;
    mapping (address => uint256) internal lockedTotalWorth;

    event AddLocked(address indexed owner, uint256 amount,uint256 worth);
    event BurnLocked(address indexed owner, uint256 amount,uint256 worth);
    constructor (address minePoolAddr) public{
        setFNXMinePoolAddress(minePoolAddr);
    }
    function getTotalLockedWorth() public view returns (uint256) {
        return _totalLockedWorth;
    }
    function lockedBalanceOf(address account) public view returns (uint256) {
        return lockedBalances[account];
    }
    function lockedWorthOf(address account) public view returns (uint256) {
        return lockedTotalWorth[account];
    }
    function getLockedBalance(address account) public view returns (uint256,uint256) {
        return (lockedBalances[account],lockedTotalWorth[account]);
    }
    function addMinerBalance(address account,uint256 amount) public onlyManager{
        _FnxMinePool.addMinerBalance(account,amount);
    }
    function burnLocked(address account, uint256 amount) public onlyManager{
        uint256 lockedAmount = lockedBalances[account];
        require(amount<=lockedAmount,"burnLocked: balance is insufficient");
        if(lockedAmount>0){
            uint256 lockedWorth = lockedTotalWorth[account];
            if (amount == lockedAmount){
                _subLockBalance(account,lockedAmount,lockedWorth);
            }else{
                uint256 burnWorth = amount.mul(lockedWorth.div(lockedAmount));
                _subLockBalance(account,amount,burnWorth);
            }
        }
    }
    function addlockBalance(address account, uint256 amount,uint256 lockedWorth)public onlyManager {
        burn(account,amount);
        _addLockBalance(account,amount,lockedWorth);
    }
    function transfer(address recipient, uint256 amount)public returns (bool){
        require(address(_FnxMinePool) != address(0),"FnxMinePool is not set");
        _FnxMinePool.transferMinerCoin(msg.sender,recipient,amount);
        return SharedCoin.transfer(recipient,amount);
    }
    function transferFrom(address sender, address recipient, uint256 amount)public returns (bool){
        require(address(_FnxMinePool) != address(0),"FnxMinePool is not set");
        _FnxMinePool.transferMinerCoin(sender,recipient,amount);
        return SharedCoin.transferFrom(sender,recipient,amount);
    }
    function burn(address account, uint256 amount) public onlyManager {
        require(address(_FnxMinePool) != address(0),"FnxMinePool is not set");
        _FnxMinePool.burnMinerCoin(account,amount);
        SharedCoin._burn(account,amount);
    }
    function mint(address account, uint256 amount) public onlyManager {
        require(address(_FnxMinePool) != address(0),"FnxMinePool is not set");
        _FnxMinePool.mintMinerCoin(account,amount);
        SharedCoin._mint(account,amount);
    }
    function _addLockBalance(address account, uint256 amount,uint256 lockedWorth)internal {
        lockedBalances[account]= lockedBalances[account].add(amount);
        lockedTotalWorth[account]= lockedTotalWorth[account].add(lockedWorth);
        _totalLockedWorth = _totalLockedWorth.add(lockedWorth);
        emit AddLocked(account, amount,lockedWorth);
    }
    function _subLockBalance(address account,uint256 amount,uint256 lockedWorth)internal {
        lockedBalances[account]= lockedBalances[account].sub(amount);
        lockedTotalWorth[account]= lockedTotalWorth[account].sub(lockedWorth);
        _totalLockedWorth = _totalLockedWorth.sub(lockedWorth);
        emit BurnLocked(account, amount,lockedWorth);
    }
    function redeemLockedCollateral(address account,uint256 tokenAmount,uint256 leftColateral)public onlyManager returns (uint256,uint256){
        if (leftColateral == 0){
            return(0,0);
        }
        uint256 lockedAmount = lockedBalances[account];
        uint256 lockedWorth = lockedTotalWorth[account];
        if (lockedAmount == 0){
            return (0,0);
        }
        uint256 redeemWorth = 0;
        uint256 lockedBurn = 0;
        uint256 lockedPrice = lockedWorth/lockedAmount;
        if (lockedAmount >= tokenAmount){
            lockedBurn = tokenAmount;
            redeemWorth = tokenAmount.mul(lockedPrice);
        }else{
            lockedBurn = lockedAmount;
            redeemWorth = lockedWorth;
        }
        if (redeemWorth > leftColateral) {
            lockedBurn = leftColateral.div(lockedPrice);
            redeemWorth = lockedBurn.mul(lockedPrice);
        }
        if (lockedBurn > 0){
            burnLocked(msg.sender,lockedBurn);
            return (lockedBurn,redeemWorth);
        }
        return (0,0);
    }
}
