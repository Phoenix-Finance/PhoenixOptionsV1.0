pragma solidity ^0.5.1;
import "../modules/Managerable.sol";
import "../FNXMinePool/IFNXMinePool.sol";
import "../ERC20/Erc20Data.sol";
contract FPTData is Erc20Data,ImportFNXMinePool,Managerable{
    /**
    * @dev lock mechanism is used when user redeem collateral and left collateral is insufficient.
    * _totalLockedWorth stores total locked worth, priced in USD.
    * lockedBalances stores user's locked FPTCoin.
    * lockedTotalWorth stores user's locked worth, priced in USD. For locked FPTCoin's net worth is constant when It was locked.
    */
    uint256 internal _totalLockedWorth;
    mapping (address => uint256) internal lockedBalances;
    mapping (address => uint256) internal lockedTotalWorth;
    /**
     * @dev FPT has burn time limit. When user's balance is moved in som coins, he will wait `timeLimited` to burn FPT. 
     * latestTransferIn is user's latest time when his balance is moved in.
     */
    mapping(address=>uint256) internal latestTransferIn;
    uint256 internal timeLimited;
    /**
     * @dev Emitted when `owner` locked  `amount` FPT, which net worth is  `worth` in USD. 
     */
    event AddLocked(address indexed owner, uint256 amount,uint256 worth);
    /**
     * @dev Emitted when `owner` burned locked  `amount` FPT, which net worth is  `worth` in USD. 
     */
    event BurnLocked(address indexed owner, uint256 amount,uint256 worth);

}