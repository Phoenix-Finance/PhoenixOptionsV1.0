pragma solidity =0.5.16;
import "./TokenConverterData.sol";
import "../modules/SafeMath.sol";
import "../ERC20/IERC20.sol";

/**
 * @title FPTCoin is finnexus collateral Pool token, implement ERC20 interface.
 * @dev ERC20 token. Its inside value is collatral pool net worth.
 *
 */
contract TokenConverter is TokenConverterData {
    using SafeMath for uint256;
    constructor (address multiSignature) proxyOwner(multiSignature) public{
    }
    modifier inited (){
    	  require(cphxAddress!=address(0));
    	  require(phxAddress!=address(0));
    	  _;
    } 


    function update() versionUpdate public{
    }
    
    /**
     * @dev constructor function. set phx minePool contract address. 
     */ 
    function setParameter(address _cphxAddress,address _phxAddress,uint256 _timeSpan,uint256 _dispatchTimes,uint256 _txNum) originOnce public{
        if (_cphxAddress != address(0))
            cphxAddress = _cphxAddress;
            
        if (_phxAddress != address(0))
            phxAddress = _phxAddress;
            
        if (_timeSpan != 0) 
            timeSpan = _timeSpan;
            
        if (_dispatchTimes != 0) 
            dispatchTimes = _dispatchTimes;
        
        if (_txNum != 0) 
            txNum = _txNum;   
        lockPeriod = dispatchTimes*timeSpan;
    }
    
    /**
     * @dev getting back the left mine token
     * @param reciever the reciever for getting back mine token
     */
    function getbackLeftphx(address reciever)  public onlyOrigin {
        uint256 bal =  IERC20(phxAddress).balanceOf(address(this));
        IERC20(phxAddress).transfer(reciever,bal);
    }  

    /**
     * @dev Retrieve user's locked balance. 
     * @param account user's account.
     */ 
    function lockedBalanceOf(address account) public view returns (uint256) {
        return lockedBalances[account];
    }


    /**
     * @dev user input cnfx to get phx
     * @param amount phx amount
     */ 
    function inputCphxForInstallmentPay(uint256 amount) external inited {
        require(amount>0,"amount should be bigger than 0");
        
        IERC20(cphxAddress).transferFrom(msg.sender,address(this),amount);
        uint256 idx = now.div(24*3600);//lockedIndexs[msg.sender].totalIdx;

        uint256 latest = userTxIdxs[msg.sender].length;
        if(latest == 0 || userTxIdxs[msg.sender][latest-1]!=idx){
            userTxIdxs[msg.sender].push(idx);
        }

        uint256 divAmount = amount.div(dispatchTimes);

        if( lockedAllRewards[msg.sender][idx].total==0) {
            lockedAllRewards[msg.sender][idx] = lockedReward(now,amount);
        } else {
            lockedAllRewards[msg.sender][idx].startTime = now;
            lockedAllRewards[msg.sender][idx].total = lockedAllRewards[msg.sender][idx].total.add(amount);
        }
        
        //index 0 to save the left token num
        lockedAllRewards[msg.sender][idx].alloc[0] = lockedAllRewards[msg.sender][idx].alloc[0].add(amount.sub(divAmount));
        uint256 i=2;
        //idx = 1, the reward give user immediately
        for(;i<dispatchTimes;i++){
            lockedAllRewards[msg.sender][idx].alloc[i] = lockedAllRewards[msg.sender][idx].alloc[i].add(divAmount);
        }
        lockedAllRewards[msg.sender][idx].alloc[i] = lockedAllRewards[msg.sender][idx].alloc[i].add(amount.sub(divAmount.mul(dispatchTimes-1)));

        lockedBalances[msg.sender] = lockedBalances[msg.sender].add(amount.sub(divAmount));

        IERC20(phxAddress).transfer(msg.sender,divAmount);

        emit InputCphx(msg.sender,amount,divAmount);
    }
    
      /**
     * @dev user user claim expired reward
     */ 
    function claimphxExpiredReward() external inited {
        require(phxAddress!=address(0),"phx token should be set");
        
        uint256 txcnt = 0;
        uint256 idx = lockedIndexs[msg.sender].beginIdx;
        uint256 endIdx = userTxIdxs[msg.sender].length;
        uint256 totalRet = 0;

        uint256 pretxid = 0;
        for(;idx<endIdx && txcnt<txNum;idx++) {
           //i used for the user input cphx tx idx,too much i used before,no changed now
           uint256 i = userTxIdxs[msg.sender][idx];
           if(i!=pretxid){
                pretxid = i;
            } else {
                continue;
           }

           if (now >= lockedAllRewards[msg.sender][i].startTime + timeSpan) {
               if (lockedAllRewards[msg.sender][i].alloc[0] > 0) {
                    if (now >= lockedAllRewards[msg.sender][i].startTime + lockPeriod) {
                        totalRet = totalRet.add(lockedAllRewards[msg.sender][i].alloc[0]);
                        lockedAllRewards[msg.sender][i].alloc[0] = 0;
                        //updated last expired idx
                        lockedIndexs[msg.sender].beginIdx = idx;
                    } else {
                      
                        uint256 timeIdx = (now - lockedAllRewards[msg.sender][i].startTime).div(timeSpan) + 1;
                        uint256 j = 2;
                        uint256 subtotal = 0;
                        for(;j<timeIdx+1;j++) {
                            subtotal = subtotal.add(lockedAllRewards[msg.sender][i].alloc[j]);
                            lockedAllRewards[msg.sender][i].alloc[j] = 0;
                        }
                        
                        //updated left locked balance,possible?
                        if(subtotal<=lockedAllRewards[msg.sender][i].alloc[0]){
                            lockedAllRewards[msg.sender][i].alloc[0] = lockedAllRewards[msg.sender][i].alloc[0].sub(subtotal);
                        } else {
                            subtotal = lockedAllRewards[msg.sender][i].alloc[0];
                            lockedAllRewards[msg.sender][i].alloc[0] = 0;
                        }
                        
                        totalRet = totalRet.add(subtotal);
                    }
                    
                    txcnt = txcnt + 1;
               }
                
           } else {
               //the item after this one is pushed behind this,not needed to caculate
               break;
           }
        }
        
        lockedBalances[msg.sender] = lockedBalances[msg.sender].sub(totalRet);
        //transfer back to user
        IERC20(phxAddress).transfer(msg.sender,totalRet);
        
        emit Claimphx(msg.sender,totalRet,txcnt);
    }
    
      /**
     * @dev get user claimable balance
     * @param _user the user address
     */ 
    function getClaimAbleBalance(address _user) public view returns (uint256) {
        require(phxAddress!=address(0),"phx token should be set");
        
        uint256 txcnt = 0;
        uint256 idx = lockedIndexs[_user].beginIdx;
       //uint256 endIdx = lockedIndexs[_user].totalIdx;
        uint256 endIdx = userTxIdxs[_user].length;
        uint256 totalRet = 0;
        uint256 pretxid = 0;

        for(;idx<endIdx && txcnt<txNum;idx++) {
            uint256 i = userTxIdxs[_user][idx];
            if(i!=pretxid){
                pretxid = i;
            } else {
                continue;
            }
           //only count the rewards over at least one timeSpan
           if (now >= lockedAllRewards[_user][i].startTime + timeSpan) {
               
               if (lockedAllRewards[_user][i].alloc[0] > 0) {
                    if (now >= lockedAllRewards[_user][i].startTime + lockPeriod) {
                        totalRet = totalRet.add(lockedAllRewards[_user][i].alloc[0]);
                    } else {
                        uint256 timeIdx = (now - lockedAllRewards[_user][i].startTime).div(timeSpan) + 1;
                        uint256 j = 2;
                        uint256 subtotal = 0;
                        for(;j<timeIdx+1;j++) {
                            subtotal = subtotal.add(lockedAllRewards[_user][i].alloc[j]);
                        }
                        
                        //updated left locked balance,possible?
                        if(subtotal>lockedAllRewards[_user][i].alloc[0]){
                            subtotal = lockedAllRewards[_user][i].alloc[0];
                        }
                        
                        totalRet = totalRet.add(subtotal);
                    }
                    
                    txcnt = txcnt + 1;
               }
                
           } else {
               //the item after this one is pushed behind this,not needed to caculate
               break;
           }
        }
        
        return totalRet;
    }


    function getUserConvertRecords(address _user)
            public
            view
            returns
    (uint256,uint256[] memory,uint256[] memory) {
        uint256 idx = lockedIndexs[_user].beginIdx;
        //uint256 endIdx = userTxIdxs[_user].length;
        uint256 len = (userTxIdxs[_user].length - idx);
        uint256 retidx = 0;
        uint256 pretxid = 0;

        uint256[] memory retStArr = new uint256[]((dispatchTimes+1)*len);
        uint256[] memory retAllocArr = new uint256[]((dispatchTimes+1)*len);

        for(;idx<userTxIdxs[_user].length;idx++) {
            uint256 i = userTxIdxs[_user][idx];

            if(i!=pretxid){
                pretxid = i;
            } else {
                continue;
            }

            for(uint256 j=0;j<=dispatchTimes;j++) {
                retAllocArr[retidx*(dispatchTimes+1)+j] = lockedAllRewards[_user][i].alloc[j];
                if(j==0) {
                    retStArr[retidx*(dispatchTimes+1)+j] = 0;
                } else {
                    retStArr[retidx*(dispatchTimes+1)+j] = lockedAllRewards[_user][i].startTime.add(timeSpan*(j-1));
                }
            }
            retidx++;
        }

        return (dispatchTimes+1,retStArr,retAllocArr);
    }
    
}
