pragma solidity ^0.5.1;
import "./SharedCoin.sol";
import "./modules/SafeMath.sol";
import "./modules/Managerable.sol";
import "./interfaces/IFNXMinePool.sol";
/**
 * @title FPTCoin is finnexus collateral Pool token, implement ERC20 interface.
 * @dev ERC20 token. Its inside value is collatral pool net worth.
 *
 */
contract FPTCoin is SharedCoin,ImportFNXMinePool,Managerable {
    using SafeMath for uint256;
    /**
    * @dev lock mechanism is used when user redeem collateral and left collateral is insufficient.
    * _totalLockedWorth stores total locked worth, priced in USD.
    * lockedBalances stores user's locked FPTCoin.
    * lockedTotalWorth stores user's locked worth, priced in USD. For locked FPTCoin's net worth is constant when It was locked.
    */
    uint256 public _totalLockedWorth;
    mapping (address => uint256) public lockedBalances;
    mapping (address => uint256) public lockedTotalWorth;
    /**
     * @dev FPT has burn time limit. When user's balance is moved in som coins, he will wait `timeLimited` to burn FPT. 
     * latestTransferIn is user's latest time when his balance is moved in.
     */
    mapping(address=>uint256) public latestTransferIn;
    uint256 public timeLimited;
    /**
     * @dev Emitted when `owner` locked  `amount` FPT, which net worth is  `worth` in USD. 
     */
    event AddLocked(address indexed owner, uint256 amount,uint256 worth);
    /**
     * @dev Emitted when `owner` burned locked  `amount` FPT, which net worth is  `worth` in USD. 
     */
    event BurnLocked(address indexed owner, uint256 amount,uint256 worth);

    /**
     * @dev constructor function. set FNX minePool contract address. 
     * @param minePoolAddr FNX minePool contract address.
     */ 
    function initialize(address minePoolAddr) public{
        SharedCoin.initialize();
        return;
        _FnxMinePool = IFNXMinePool(minePoolAddr);
        timeLimited = 1 hours;
        _owner = msg.sender;
    }
    /**
     * @dev set FPT burn time limited, only owner can invoke. 
     * @param _timeLimited new burning time limited.
     */ 
    function setBurnTimeLimited(uint256 _timeLimited) public onlyOwner {
        timeLimited = _timeLimited;
    }
    /**
     * @dev Retrieve user's start time for burning. 
     * @param user user's account.
     */ 
    function getUserBurnTimeLimite(address user) public view returns (uint256){
        return latestTransferIn[user]+timeLimited;
    }
    /**
     * @dev Retrieve total locked worth. 
     */ 
    function getTotalLockedWorth() public view returns (uint256) {
        return _totalLockedWorth;
    }
    /**
     * @dev Retrieve user's locked balance. 
     * @param account user's account.
     */ 
    function lockedBalanceOf(address account) public view returns (uint256) {
        return lockedBalances[account];
    }
    /**
     * @dev Retrieve user's locked net worth. 
     * @param account user's account.
     */ 
    function lockedWorthOf(address account) public view returns (uint256) {
        return lockedTotalWorth[account];
    }
    /**
     * @dev Retrieve user's locked balance and locked net worth. 
     * @param account user's account.
     */ 
    function getLockedBalance(address account) public view returns (uint256,uint256) {
        return (lockedBalances[account],lockedTotalWorth[account]);
    }
    /**
     * @dev Interface to manager FNX mine pool contract, add miner balance when user has bought some options. 
     * @param account user's account.
     * @param amount user's pay for buying options, priced in USD.
     */ 
    function addMinerBalance(address account,uint256 amount) public onlyManager{
        _FnxMinePool.addMinerBalance(account,amount);
    }
    /**
     * @dev Burn user's locked balance, when user redeem collateral. 
     * @param account user's account.
     * @param amount amount of burned FPT.
     */ 
    function burnLocked(address account, uint256 amount) public onlyManager{
        require(latestTransferIn[account]+timeLimited<now,"FPT coin locked time is not expired!");
        uint256 lockedAmount = lockedBalances[account];
        require(amount<=lockedAmount,"burnLocked: balance is insufficient");
        if(lockedAmount>0){
            uint256 lockedWorth = lockedTotalWorth[account];
            if (amount == lockedAmount){
                _subLockBalance(account,lockedAmount,lockedWorth);
            }else{
                uint256 burnWorth = amount*lockedWorth/lockedAmount;
                _subLockBalance(account,amount,burnWorth);
            }
        }
    }
    /**
     * @dev Move user's FPT to locked balance, when user redeem collateral. 
     * @param account user's account.
     * @param amount amount of locked FPT.
     * @param lockedWorth net worth of locked FPT.
     */ 
    function addlockBalance(address account, uint256 amount,uint256 lockedWorth)public onlyManager {
        burn(account,amount);
        _addLockBalance(account,amount,lockedWorth);
    }
    /**
     * @dev Move user's FPT to 'recipient' balance, a interface in ERC20. 
     * @param recipient recipient's account.
     * @param amount amount of FPT.
     */ 
    function transfer(address recipient, uint256 amount)public returns (bool){
        require(address(_FnxMinePool) != address(0),"FnxMinePool is not set");
        _FnxMinePool.transferMinerCoin(msg.sender,recipient,amount);
        latestTransferIn[recipient] = now;
        return SharedCoin.transfer(recipient,amount);
    }
    /**
     * @dev Move sender's FPT to 'recipient' balance, a interface in ERC20. 
     * @param sender sender's account.
     * @param recipient recipient's account.
     * @param amount amount of FPT.
     */ 
    function transferFrom(address sender, address recipient, uint256 amount)public returns (bool){
        require(address(_FnxMinePool) != address(0),"FnxMinePool is not set");
        _FnxMinePool.transferMinerCoin(sender,recipient,amount);
        latestTransferIn[recipient] = now;
        return SharedCoin.transferFrom(sender,recipient,amount);
    }
    /**
     * @dev burn user's FPT when user redeem FPTCoin. 
     * @param account user's account.
     * @param amount amount of FPT.
     */ 
    function burn(address account, uint256 amount) public onlyManager {
        require(latestTransferIn[account]+timeLimited<now,"FPT coin locked time is not expired!");
        require(address(_FnxMinePool) != address(0),"FnxMinePool is not set");
        _FnxMinePool.burnMinerCoin(account,amount);
        SharedCoin._burn(account,amount);
    }
    /**
     * @dev mint user's FPT when user add collateral. 
     * @param account user's account.
     * @param amount amount of FPT.
     */ 
    function mint(address account, uint256 amount) public onlyManager {
        require(address(_FnxMinePool) != address(0),"FnxMinePool is not set");
        _FnxMinePool.mintMinerCoin(account,amount);
        latestTransferIn[account] = now;
        SharedCoin._mint(account,amount);
    }
    /**
     * @dev An auxiliary function, add user's locked balance. 
     * @param account user's account.
     * @param amount amount of FPT.
     * @param lockedWorth net worth of FPT.
     */ 
    function _addLockBalance(address account, uint256 amount,uint256 lockedWorth)internal {
        lockedBalances[account]= lockedBalances[account].add(amount);
        lockedTotalWorth[account]= lockedTotalWorth[account].add(lockedWorth);
        _totalLockedWorth = _totalLockedWorth.add(lockedWorth);
        emit AddLocked(account, amount,lockedWorth);
    }
    /**
     * @dev An auxiliary function, deduct user's locked balance. 
     * @param account user's account.
     * @param amount amount of FPT.
     * @param lockedWorth net worth of FPT.
     */ 
    function _subLockBalance(address account,uint256 amount,uint256 lockedWorth)internal {
        lockedBalances[account]= lockedBalances[account].sub(amount);
        lockedTotalWorth[account]= lockedTotalWorth[account].sub(lockedWorth);
        _totalLockedWorth = _totalLockedWorth.sub(lockedWorth);
        emit BurnLocked(account, amount,lockedWorth);
    }
    /**
     * @dev An interface of redeem locked FPT, when user redeem collateral, only manager contract can invoke. 
     * @param account user's account.
     * @param tokenAmount amount of FPT.
     * @param leftCollateral left available collateral in collateral pool, priced in USD.
     */ 
    function redeemLockedCollateral(address account,uint256 tokenAmount,uint256 leftCollateral)public onlyManager returns (uint256,uint256){
        if (leftCollateral == 0){
            return(0,0);
        }
        uint256 lockedAmount = lockedBalances[account];
        uint256 lockedWorth = lockedTotalWorth[account];
        if (lockedAmount == 0 || lockedWorth == 0){
            return (0,0);
        }
        uint256 redeemWorth = 0;
        uint256 lockedBurn = 0;
        uint256 lockedPrice = lockedWorth/lockedAmount;
        if (lockedAmount >= tokenAmount){
            lockedBurn = tokenAmount;
            redeemWorth = tokenAmount*lockedPrice;
        }else{
            lockedBurn = lockedAmount;
            redeemWorth = lockedWorth;
        }
        if (redeemWorth > leftCollateral) {
            lockedBurn = leftCollateral/lockedPrice;
            redeemWorth = lockedBurn*lockedPrice;
        }
        if (lockedBurn > 0){
            burnLocked(account,lockedBurn);
            return (lockedBurn,redeemWorth);
        }
        return (0,0);
    }
}
