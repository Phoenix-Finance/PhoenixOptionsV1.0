pragma solidity ^0.4.26;
import "./modules/SafeMath.sol";
import "./modules/Managerable.sol";
import "./interfaces/IERC20.sol";
contract FNXMinePool is Managerable {
    using SafeMath for uint256;
    mapping(address=>uint256) public minerBalances;
    mapping(address=>uint256) internal minerOrigins;

    mapping (address => uint256) public balances;
    uint256 internal _totalSupply = 0;
    uint256 internal calDecimals = 1e18;

    IERC20 internal minerCoin;
    uint256 internal totalMinedWorth;
    uint256 internal totalMinedCoin;
    uint256 internal latestSettleTime;
    uint256 internal mineAmount;
    uint256 internal mineInterval;

    constructor (address _minerCoin) public{
        minerCoin = IERC20(_minerCoin);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    function getTotalMined()public view returns(uint256){
        return totalMinedCoin;
    }
    function getMineInfo()public view returns(uint256,uint256){
        return (mineAmount,mineInterval);
    }
    function getMinerTokenBalance(address account)public view returns(uint256){
        return balances[account];
    }
    function getMinerCoinAddress()public view returns(address){
        return address(minerCoin);
    }
    function setMinerCoinAddress(address _minerCoin)public onlyOwner{
        minerCoin = IERC20(_minerCoin);
    }
    function getMinerTokenTotalSuply()public view returns(uint256){
        return _totalSupply;
    }
    function getMinerBalance(address account)public view returns(uint256){
        uint256 totalBalance = minerBalances[account];
        if (_totalSupply > 0 && balances[account]>0){
            uint256 tokenNetWorth = _getTokenNetWorth();
            totalBalance= totalBalance.add(_settlement(account,balances[account],tokenNetWorth));
        }
        return totalBalance;
    }
    function mintMinerCoin(address account,uint256 amount) public onlyManager {
        _mineSettlement();
        _mintMinerCoin(account,amount);
    }
    function burnMinerCoin(address account,uint256 amount) public onlyManager {
        _mineSettlement();
        _burnMinerCoin(account,amount);
    }
    function addMinerBalance(address account,uint256 amount) public onlyManager {
        minerBalances[account] = minerBalances[account].add(amount);
        totalMinedCoin = totalMinedCoin.add(amount);
    }
    function setMineAmount(uint256 _mineAmount)public onlyOwner {
        _mineSettlement();
        mineAmount = _mineAmount;
    }
    function setMineInterval(uint256 _mineInterval)public onlyOwner {
        _mineSettlement();
        mineInterval = _mineInterval;
    }
    function redeemMinerCoin(address account,uint256 amount)public {
        _mineSettlement();
        _settlementAllCoin(account);
        require(minerBalances[account]>=amount,"miner balance is insufficient");
        minerBalances[account] = minerBalances[account].sub(amount);
        minerCoin.transfer(account,amount);
    }
    function _mineSettlement()internal{
        if (_totalSupply > 0){
            uint256 latestMined = mineAmount.mul(now-latestSettleTime).div(mineInterval);
            totalMinedWorth = totalMinedWorth.add(latestMined*calDecimals);
            totalMinedCoin = totalMinedCoin.add(latestMined);
        }
        latestSettleTime = now.div(mineInterval)*mineInterval;
    }
    function _mintMinerCoin(address account,uint256 amount)internal{
        if (_totalSupply > 0){
            uint256 tokenNetWorth = _getTokenNetWorth();
            minerBalances[account] = minerBalances[account].add(_settlement(account,balances[account],tokenNetWorth));
            totalMinedWorth = totalMinedWorth.add(tokenNetWorth.mul(amount));
            minerOrigins[account] = tokenNetWorth;
        }
        _mint(account,amount);
    }
    function _settlementAllCoin(address account)internal{
        if (_totalSupply > 0 && balances[account]>0){
            uint256 tokenNetWorth = _getTokenNetWorth();
            minerBalances[account] = minerBalances[account].add(_settlement(account,balances[account],tokenNetWorth));
            minerOrigins[account] = tokenNetWorth;
        }
    }
    function _burnMinerCoin(address account,uint256 amount)internal{
        if (_totalSupply > 0){
            uint256 tokenNetWorth = _getTokenNetWorth();
            _burn(account,amount);
            minerBalances[account] = minerBalances[account].add(_settlement(account,amount,tokenNetWorth));
            totalMinedWorth = totalMinedWorth.sub(tokenNetWorth.mul(amount));
        }
    }
    function _settlement(address account,uint256 amount,uint256 tokenNetWorth )internal view returns (uint256) {
        uint256 origin = minerOrigins[account];
        require(tokenNetWorth>=origin,"error: tokenNetWorth logic error!");
        return amount.mul(tokenNetWorth-origin).div(calDecimals);
    }
    function _getTokenNetWorth()internal view returns (uint256) {
        if (_totalSupply > 0){
            totalMinedWorth.div(_totalSupply);
        }
        return 0;
    }
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _addBalance(account,amount);
        emit Transfer(address(0), account, amount);
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
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "burn from the zero address");
        _subBalance(account,amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    /**
     * @dev add `recipient`'s balance to iterable mapping balances.
     */
    function _addBalance(address recipient, uint256 amount) internal {
        require(recipient != address(0), "transfer to the zero address");

        balances[recipient] = balances[recipient].add(amount);
    }
        /**
     * @dev add `recipient`'s balance to iterable mapping balances.
     */
    function _subBalance(address recipient, uint256 amount) internal {
        require(recipient != address(0), "transfer to the zero address");
        balances[recipient] = balances[recipient].sub(amount);
    }
}