pragma solidity =0.5.16;
import "./FPTData.sol";
import "../ERC20/Erc20BaseProxy.sol";

/**
 * @title FPTCoin is finnexus collateral Pool token, implement ERC20 interface.
 * @dev ERC20 token. Its inside value is collatral pool net worth.
 *
 */
contract FPTProxy is FPTData,Erc20BaseProxy {
    constructor (address implementation_,address minePoolAddr,string memory tokenName) Erc20BaseProxy(implementation_) public{
        _FnxMinePool = IFNXMinePool(minePoolAddr);
        name = tokenName;
        symbol = tokenName;
    }
    /**
     * @dev Retrieve user's start time for burning. 
     *  user user's account.
     */ 
    function getUserBurnTimeLimite(address /*user*/) public view returns (uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev Retrieve total locked worth. 
     */ 
    function getTotalLockedWorth() public view returns (uint256) {
        delegateToViewAndReturn();
    }
    /**
     * @dev Retrieve user's locked balance. 
     *  account user's account.
     */ 
    function lockedBalanceOf(address /*account*/) public view returns (uint256) {
        delegateToViewAndReturn();
    }
    /**
     * @dev Retrieve user's locked net worth. 
     *  account user's account.
     */ 
    function lockedWorthOf(address /*account*/) public view returns (uint256) {
        delegateToViewAndReturn();
    }
    /**
     * @dev Retrieve user's locked balance and locked net worth. 
     *  account user's account.
     */ 
    function getLockedBalance(address /*account*/) public view returns (uint256,uint256) {
        delegateToViewAndReturn();
    }
    /**
     * @dev Interface to manager FNX mine pool contract, add miner balance when user has bought some options. 
     *  account user's account.
     *  amount user's pay for buying options, priced in USD.
     */ 
    function addMinerBalance(address /*account*/,uint256 /*amount*/) public{
        delegateAndReturn();
    }
    /**
     * @dev Move user's FPT to locked balance, when user redeem collateral. 
     *  account user's account.
     *  amount amount of locked FPT.
     *  lockedWorth net worth of locked FPT.
     */ 
    function addlockBalance(address /*account*/, uint256 /*amount*/,uint256 /*lockedWorth*/)public {
        delegateAndReturn();
    }

    /**
     * @dev burn user's FPT when user redeem FPTCoin. 
     *  account user's account.
     *  amount amount of FPT.
     */ 
    function burn(address /*account*/, uint256 /*amount*/) public {
        delegateAndReturn();
    }
    /**
     * @dev mint user's FPT when user add collateral. 
     *  account user's account.
     *  amount amount of FPT.
     */ 
    function mint(address /*account*/, uint256 /*amount*/) public {
        delegateAndReturn();
    }
    /**
     * @dev An interface of redeem locked FPT, when user redeem collateral, only manager contract can invoke. 
     *  account user's account.
     *  tokenAmount amount of FPT.
     *  leftCollateral left available collateral in collateral pool, priced in USD.
     */ 
    function redeemLockedCollateral(address /*account*/,uint256 /*tokenAmount*/,uint256 /*leftCollateral*/)
            public returns (uint256,uint256){
        delegateAndReturn();
    }
}
