pragma solidity =0.5.16;

import "../proxyModules/versionUpdater.sol";
import "../proxyModules/Halt.sol";

contract TokenConverterData is versionUpdater,Halt {
    uint256 constant internal currentVersion = 2;
    function implementationVersion() public pure returns (uint256) 
    {
        return currentVersion;
    }
    //the locjed reward info
    struct lockedReward {
        uint256 startTime; //this tx startTime for locking
        uint256 total;     //record input amount in each lock tx    
        mapping (uint256 => uint256) alloc;//the allocation table
    }
    
    struct lockedIdx {
        uint256 beginIdx;//the first index for user converting input claimable tx index 
        uint256 totalIdx;//the total number for converting tx
    }
    
    address public cphxAddress; //cphx token address
    address public phxAddress;  //phx token address
    uint256 public timeSpan = 30*24*3600;//time interval span time ,default one month
    uint256 public dispatchTimes = 6;    //allocation times,default 6 times
    uint256 public txNum = 100; //100 times transfer tx 
    uint256 public lockPeriod = dispatchTimes*timeSpan;
    
    //the user's locked total balance
    mapping (address => uint256) public lockedBalances;//locked balance for each user
    
    mapping (address =>  mapping (uint256 => lockedReward)) public lockedAllRewards;//converting tx record for each user
    
    mapping (address => lockedIdx) public lockedIndexs;//the converting tx index info

    mapping (address => uint256[]) public userTxIdxs;//address idx number
    /**
     * @dev Emitted when `owner` locked  `amount` FPT, which net worth is  `worth` in USD. 
     */
    event InputCphx(address indexed owner, uint256 indexed amount,uint256 indexed worth);
    /**
     * @dev Emitted when `owner` burned locked  `amount` FPT, which net worth is  `worth` in USD.
     */
    event Claimphx(address indexed owner, uint256 indexed amount,uint256 indexed worth);

}