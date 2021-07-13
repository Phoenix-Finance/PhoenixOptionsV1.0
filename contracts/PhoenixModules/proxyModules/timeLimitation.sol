pragma solidity =0.5.16;
import './proxyOwner.sol';

contract timeLimitation is proxyOwner {
    
    /**
     * @dev PPT has burn time limit. When user's balance is moved in som coins, he will wait `timeLimited` to burn PPT. 
     * latestTransferIn is user's latest time when his balance is moved in.
     */
    struct addressInfo {
        uint128 time;
        bool bIgnoreFrom;
        bool bIgnoreTo;
    }
    mapping(address=>addressInfo) internal addressTimeMap;
    uint256 public limitation;
    /**
     * @dev set time limitation, only owner can invoke. 
     * @param _limitation new time limitation.
     */ 
    function setTimeLimitation(uint256 _limitation) public OwnerOrOrigin {
        limitation = _limitation;
    }
    function getAccountInfo(address account) public view returns(bool,bool){
        return (addressTimeMap[account].bIgnoreFrom,addressTimeMap[account].bIgnoreTo);
    }
    function setAccountInfo(address account,bool bIgnoreFrom,bool bIgnoreTo) public OwnerOrOrigin{
        addressTimeMap[account].bIgnoreFrom = bIgnoreFrom;
        addressTimeMap[account].bIgnoreTo = bIgnoreTo;
    }
    function setTransferTimeLimitation(address from,address to) internal{
        if (!addressTimeMap[from].bIgnoreFrom && !addressTimeMap[to].bIgnoreTo){
            addressTimeMap[to].time = uint128(now);
        }
    }
    /**
     * @dev Retrieve user's start time for burning. 
     * @param account user's account.
     */ 
    function getTimeLimitation(address account) public view returns (uint256){
        return addressTimeMap[account].time+limitation;
    }
    modifier OutLimitation(address account) {
        require(addressTimeMap[account].time+limitation<now,"Time limitation is not expired!");
        _;
    }    
}