pragma solidity =0.5.16;
import "./MinePoolData.sol";
import "../Proxy/baseProxy.sol";
/**
 * @title FPTCoin mine pool, which manager contract is FPTCoin.
 * @dev A smart-contract which distribute some mine coins by FPTCoin balance.
 *
 */
contract MinePoolProxy is MinePoolData,baseProxy {
    constructor (address implementation_) baseProxy(implementation_) public{
    }
    /**
     * @dev default function for foundation input miner coins.
     */
    function()external payable{
    }
    /**
     * @dev foundation redeem out mine coins.
     *  mineCoin mineCoin address
     *  amount redeem amount.
     */
    function redeemOut(address /*mineCoin*/,uint256 /*amount*/)public{
        delegateAndReturn();
    }
    /**
     * @dev retrieve total distributed mine coins.
     *  mineCoin mineCoin address
     */
    function getTotalMined(address /*mineCoin*/)public view returns(uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev retrieve minecoin distributed informations.
     *  mineCoin mineCoin address
     * @return distributed amount and distributed time interval.
     */
    function getMineInfo(address /*mineCoin*/)public view returns(uint256,uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev retrieve user's mine balance.
     *  account user's account
     *  mineCoin mineCoin address
     */
    function getMinerBalance(address /*account*/,address /*mineCoin*/)public view returns(uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev Set mineCoin mine info, only foundation owner can invoked.
     *  mineCoin mineCoin address
     *  _mineAmount mineCoin distributed amount
     *  _mineInterval mineCoin distributied time interval
     */
    function setMineCoinInfo(address /*mineCoin*/,uint256 /*_mineAmount*/,uint256 /*_mineInterval*/)public {
        delegateAndReturn();
    }
    /**
     * @dev Set the reward for buying options.
     *  mineCoin mineCoin address
     *  _mineAmount mineCoin reward amount
     */
    function setBuyingMineInfo(address /*mineCoin*/,uint256 /*_mineAmount*/)public {
        delegateAndReturn();
    }
    /**
     * @dev Get the reward for buying options.
     *  mineCoin mineCoin address
     */
    function getBuyingMineInfo(address /*mineCoin*/)public view returns(uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev Get the all rewards for buying options.
     */
    function getBuyingMineInfoAll()public view returns(address[] memory,uint256[] memory){
        delegateToViewAndReturn();
    }
    /**
     * @dev transfer mineCoin to recieptor when account transfer amount FPTCoin to recieptor, only manager contract can modify database.
     *  account the account transfer from
     *  recieptor the account transfer to
     *  amount the mine shared amount
     */
    function transferMinerCoin(address /*account*/,address /*recieptor*/,uint256 /*amount*/) public {
        delegateAndReturn();
    }
    /**
     * @dev mint mineCoin to account when account add collateral to collateral pool, only manager contract can modify database.
     *  account user's account
     *  amount the mine shared amount
     */
    function mintMinerCoin(address /*account*/,uint256 /*amount*/) public {
        delegateAndReturn();
    }
    /**
     * @dev Burn mineCoin to account when account redeem collateral to collateral pool, only manager contract can modify database.
     *  account user's account
     *  amount the mine shared amount
     */
    function burnMinerCoin(address /*account*/,uint256 /*amount*/) public {
        delegateAndReturn();
    }
    /**
     * @dev give amount buying reward to account, only manager contract can modify database.
     *  account user's account
     *  amount the buying shared amount
     */
    function addMinerBalance(address /*account*/,uint256 /*amount*/) public {
        delegateAndReturn();
    }
    /**
     * @dev changer mine coin distributed amount , only foundation owner can modify database.
     *  mineCoin mine coin address
     *  _mineAmount the distributed amount.
     */
    function setMineAmount(address /*mineCoin*/,uint256 /*_mineAmount*/)public {
        delegateAndReturn();
    }
    /**
     * @dev changer mine coin distributed time interval , only foundation owner can modify database.
     *  mineCoin mine coin address
     *  _mineInterval the distributed time interval.
     */
    function setMineInterval(address /*mineCoin*/,uint256 /*_mineInterval*/)public {
        delegateAndReturn();
    }
    /**
     * @dev user redeem mine rewards.
     *  mineCoin mine coin address
     *  amount redeem amount.
     */
    function redeemMinerCoin(address /*mineCoin*/,uint256 /*amount*/)public{
        delegateAndReturn();
    }
}