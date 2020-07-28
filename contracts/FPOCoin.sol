pragma solidity ^0.4.26;
import "./SharedCoin.sol";
import "./modules/SafeMath.sol";
contract FPOCoin is SharedCoin  {
    using SafeMath for uint256;
    string public name = "SharedCoin";
    string public symbol = "SCoin";
    
    uint256 internal _totalLockedWorth = 0;
    mapping (address => uint256) public lockedBalances;
    mapping (address => uint256) public lockedTotalWorth;

    event AddLocked(address indexed owner, uint256 amount,uint256 worth);
    event BurnLocked(address indexed owner, uint256 amount,uint256 worth);
    constructor () public{
    }

    function getLockedBalance(address account) public view returns (uint256,uint256) {
        return (lockedBalances[account],lockedTotalWorth[account]);
    }
    /**
    * @dev Destroys `amount` tokens from `account`, reducing the
    * total supply.
    *
    * Emits a {Transfer} event with `to` set to the zero address.
    *
    * Requirements
    *
    * - `account` cannot be the zero address.
    * - `account` must have at least `amount` tokens.
    */
    function _burnLocked(address account, uint256 amount) internal{
        uint256 lockedAmount = lockedBalances[account];
        if(lockedAmount>0){
            uint256 lockedWorth = lockedTotalWorth[account];
            if (amount >= lockedAmount){
                _subLockBalance(account,lockedAmount,lockedWorth);
            }else{
                uint256 burnWorth = amount.mul(lockedWorth.div(lockedAmount));
                _subLockBalance(account,amount,burnWorth);
            }
        }
    }
    function addlockBalance(address account, uint256 amount,uint256 lockedWorth)internal {
        _subBalance(account,amount);
        _addLockBalance(account,amount,lockedWorth);
    }
    function _addLockBalance(address account, uint256 amount,uint256 lockedWorth)internal {
        lockedBalances[account]+= amount;
        lockedTotalWorth[account]+= lockedWorth;
        _totalLockedWorth -= lockedWorth;
        emit AddLocked(account, amount,lockedWorth);
    }
    function _subLockBalance(address account,uint256 amount,uint256 lockedWorth)internal {
        lockedBalances[account]-= amount;
        lockedTotalWorth[account]-= lockedWorth;
        _totalLockedWorth -= lockedWorth;
        emit BurnLocked(account, amount,lockedWorth);
    }
}
