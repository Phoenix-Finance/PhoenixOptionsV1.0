pragma solidity =0.5.16;
import "./SharedCoin.sol";
import "../modules/SafeMath.sol";
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */

/**
 * @title PPTCoin is Phoenix collateral Pool token, implement ERC20 interface.
 * @dev ERC20 token. Its inside value is collatral pool net worth.
 *
 */
contract PPTCoin is SharedCoin {
    using SafeMath for uint256;
    constructor (address multiSignature) proxyOwner(multiSignature) public{
    }
    function initialize() public{
        versionUpdater.initialize();
        _totalSupply = 0;
        decimals = 18;
        totalLimit = uint256(-1);
        userLimit = uint256(-1);
    }
    function setMinePool(address acceleratedMinePool) external onlyOwner{
        minePool = IAcceleratedMinePool(acceleratedMinePool);
    }
    function update() public versionUpdate{
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
     * @dev Move user's PPT to locked balance, when user redeem collateral. 
     * @param account user's account.
     * @param amount amount of locked PPT.
     * @param lockedWorth net worth of locked PPT.
     */ 
    function addlockBalance(address account, uint256 amount,uint256 lockedWorth)public onlyManager {
        burn(account,amount);
        _addLockBalance(account,amount,lockedWorth);
    }
    /**
     * @dev Move user's PPT to 'recipient' balance, a interface in ERC20. 
     * @param recipient recipient's account.
     * @param amount amount of PPT.
     */ 
    function transfer(address recipient, uint256 amount)public returns (bool){
        SharedCoin.transfer(recipient,amount);
        if (address(minePool) != address(0)){
            minePool.transferPPTCoin(msg.sender,recipient);
        }
        return true;
    }
        /**
     * @dev Move sender's PPT to 'recipient' balance, a interface in ERC20. 
     * @param sender sender's account.
     * @param recipient recipient's account.
     * @param amount amount of PPT.
     */ 
    function transferFrom(address sender, address recipient, uint256 amount)public returns (bool){
        SharedCoin.transferFrom(sender,recipient,amount);
        if (address(minePool) != address(0)){
            minePool.transferPPTCoin(sender,recipient);
        }
        return true;            
    }
    /**
     * @dev burn user's PPT when user redeem PPTCoin. 
     * @param account user's account.
     * @param amount amount of PPT.
     */ 
    function burn(address account, uint256 amount) public onlyManager OutLimitation(account) {
        SharedCoin._burn(account,amount);
        if (address(minePool) != address(0)){
            minePool.changePPTStake(account);
        }
    }
    /**
     * @dev mint user's PPT when user add collateral. 
     * @param account user's account.
     * @param amount amount of PPT.
     */ 
    function mint(address account, uint256 amount) public onlyManager belowTotalLimit(_totalSupply+amount) belowUserLimit(balances[account]+amount) {
        SharedCoin._mint(account,amount);
        if (address(minePool) != address(0)){
            minePool.changePPTStake(account);
        }
    }
    /**
     * @dev An auxiliary function, add user's locked balance. 
     * @param account user's account.
     * @param amount amount of PPT.
     * @param lockedWorth net worth of PPT.
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
     * @param amount amount of PPT.
     * @param lockedWorth net worth of PPT.
     */ 
    function _subLockBalance(address account,uint256 amount,uint256 lockedWorth)internal {
        lockedBalances[account]= lockedBalances[account].sub(amount);
        lockedTotalWorth[account]= lockedTotalWorth[account].sub(lockedWorth);
        _totalLockedWorth = _totalLockedWorth.sub(lockedWorth);
        emit BurnLocked(account, amount,lockedWorth);
    }
    /**
     * @dev An interface of redeem locked PPT, when user redeem collateral, only manager contract can invoke. 
     * @param account user's account.
     * @param tokenAmount amount of PPT.
     * @param leftCollateral left available collateral in collateral pool, priced in USD.
     */ 
    function redeemLockedCollateral(address account,uint256 tokenAmount,uint256 leftCollateral)public onlyManager OutLimitation(account) returns (uint256,uint256){
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
            _subLockBalance(account,lockedBurn,redeemWorth);
            return (lockedBurn,redeemWorth);
        }
        return (0,0);
    }
}
