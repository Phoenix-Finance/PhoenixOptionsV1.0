pragma solidity =0.5.16;
import './Ownable.sol';

contract timeLimitation is Ownable {
    
    /**
     * @dev FPT has burn time limit. When user's balance is moved in som coins, he will wait `timeLimited` to burn FPT. 
     * latestTransferIn is user's latest time when his balance is moved in.
     */
    mapping(uint256=>uint256) internal itemTimeMap;
    uint256 internal limitation = 1 hours;
    /**
     * @dev set time limitation, only owner can invoke. 
     * @param _limitation new time limitation.
     */ 
    function setTimeLimitation(uint256 _limitation) public onlyOwner {
        limitation = _limitation;
    }
    function setItemTimeLimitation(uint256 item) internal{
        itemTimeMap[item] = now;
    }
    function getTimeLimitation() public view returns (uint256){
        return limitation;
    }
    /**
     * @dev Retrieve user's start time for burning. 
     * @param item item key.
     */ 
    function getItemTimeLimitation(uint256 item) public view returns (uint256){
        return itemTimeMap[item]+limitation;
    }
    modifier OutLimitation(uint256 item) {
        require(itemTimeMap[item]+limitation<now,"Time limitation is not expired!");
        _;
    }    
}