pragma solidity =0.5.16;
import "../modules/SafeMath.sol";
import "./MinePoolData.sol";
import "../ERC20/IERC20.sol";
import "../ERC20/safeErc20.sol";
/**
 * @title FPTCoin mine pool, which manager contract is FPTCoin.
 * @dev A smart-contract which distribute some mine coins by FPTCoin balance.
 *
 */
contract FNXMinePool is MinePoolData {
    using SafeMath for uint256;
    constructor () public{
        initialize();
    }
    function initialize() onlyOwner public{
    }
    function update() onlyOwner public{
    }
    /**
     * @dev default function for foundation input miner coins.
     */
    function()external payable{

    }
    /**
     * @dev foundation redeem out mine coins.
     * @param mineCoin mineCoin address
     * @param amount redeem amount.
     */
    function redeemOut(address mineCoin,uint256 amount)public onlyOwner{
        if (mineCoin == address(0)){
            msg.sender.transfer(amount);
        }else{
            IERC20 token = IERC20(mineCoin);
            uint256 preBalance = token.balanceOf(address(this));
            SafeERC20.safeTransfer(token,msg.sender,amount);
            //token.transfer(msg.sender,amount);
            uint256 afterBalance = token.balanceOf(address(this));
            require(preBalance - afterBalance == amount,"settlement token transfer error!");
        }
    }
    /**
     * @dev retrieve total distributed mine coins.
     * @param mineCoin mineCoin address
     */
    function getTotalMined(address mineCoin)public view returns(uint256){
        uint256 _totalSupply = totalSupply();
        uint256 _mineInterval = mineInterval[mineCoin];
        if (_totalSupply > 0 && _mineInterval>0){
            uint256 _mineAmount = mineAmount[mineCoin];
            uint256 latestMined = _mineAmount.mul(now-latestSettleTime[mineCoin])/_mineInterval;
            return totalMinedCoin[mineCoin].add(latestMined);
        }
        return totalMinedCoin[mineCoin];
    }
    /**
     * @dev retrieve minecoin distributed informations.
     * @param mineCoin mineCoin address
     * @return distributed amount and distributed time interval.
     */
    function getMineInfo(address mineCoin)public view returns(uint256,uint256){
        return (mineAmount[mineCoin],mineInterval[mineCoin]);
    }
    /**
     * @dev retrieve user's mine balance.
     * @param account user's account
     * @param mineCoin mineCoin address
     */
    function getMinerBalance(address account,address mineCoin)public view returns(uint256){
        uint256 totalBalance = minerBalances[mineCoin][account];
        uint256 _totalSupply = totalSupply();
        uint256 balance = balanceOf(account);
        if (_totalSupply > 0 && balance>0){
            uint256 tokenNetWorth = _getCurrentTokenNetWorth(mineCoin);
            totalBalance= totalBalance.add(_settlement(mineCoin,account,balance,tokenNetWorth));
        }
        return totalBalance;
    }
    /**
     * @dev Set mineCoin mine info, only foundation owner can invoked.
     * @param mineCoin mineCoin address
     * @param _mineAmount mineCoin distributed amount
     * @param _mineInterval mineCoin distributied time interval
     */
    function setMineCoinInfo(address mineCoin,uint256 _mineAmount,uint256 _mineInterval)public onlyOwner {
        require(_mineAmount<1e30,"input mine amount is too large");
        require(_mineInterval>0,"input mine Interval must larger than zero");
        _mineSettlement(mineCoin);
        mineAmount[mineCoin] = _mineAmount;
        mineInterval[mineCoin] = _mineInterval;
        addWhiteList(mineCoin);
    }
    /**
     * @dev Set the reward for buying options.
     * @param mineCoin mineCoin address
     * @param _mineAmount mineCoin reward amount
     */
    function setBuyingMineInfo(address mineCoin,uint256 _mineAmount)public onlyOwner {
//        require(_mineAmount<1e30,"input mine amount is too large");
        buyingMineMap[mineCoin] = _mineAmount;
        addWhiteList(mineCoin);
    }
    /**
     * @dev Get the reward for buying options.
     * @param mineCoin mineCoin address
     */
    function getBuyingMineInfo(address mineCoin)public view returns(uint256){
        return buyingMineMap[mineCoin];
    }
    /**
     * @dev Get the all rewards for buying options.
     */
    function getBuyingMineInfoAll()public view returns(address[] memory,uint256[] memory){
        uint256 len = whiteList.length;
        address[] memory mineCoins = new address[](len);
        uint256[] memory mineNums = new uint256[](len);
        for (uint256 i=0;i<len;i++){
            mineCoins[i] = whiteList[i];
            mineNums[i] = buyingMineMap[mineCoins[i]];
        }
        return (mineCoins,mineNums);
    }
    /**
     * @dev transfer mineCoin to recieptor when account transfer amount FPTCoin to recieptor, only manager contract can modify database.
     * @param account the account transfer from
     * @param recieptor the account transfer to
     * @param amount the mine shared amount
     */
    function transferMinerCoin(address account,address recieptor,uint256 amount) public onlyManager {
        _mineSettlementAll();
        _transferMinerCoin(account,recieptor,amount);
    }
    /**
     * @dev mint mineCoin to account when account add collateral to collateral pool, only manager contract can modify database.
     * @param account user's account
     * @param amount the mine shared amount
     */
    function mintMinerCoin(address account,uint256 amount) public onlyManager {
        _mineSettlementAll();
        _mintMinerCoin(account,amount);
        emit MintMiner(account,amount);
    }
    /**
     * @dev Burn mineCoin to account when account redeem collateral to collateral pool, only manager contract can modify database.
     * @param account user's account
     * @param amount the mine shared amount
     */
    function burnMinerCoin(address account,uint256 amount) public onlyManager {
        _mineSettlementAll();
        _burnMinerCoin(account,amount);
        emit BurnMiner(account,amount);
    }
    /**
     * @dev give amount buying reward to account, only manager contract can modify database.
     * @param account user's account
     * @param amount the buying shared amount
     */
    function addMinerBalance(address account,uint256 amount) public onlyManager {
        uint256 len = whiteList.length;
        for (uint256 i=0;i<len;i++){
            address addr = whiteList[i];
            uint256 mineNum = buyingMineMap[addr];
            if (mineNum > 0){
                uint128 mineRate = uint128(mineNum);
                uint128 mineAdd = uint128(mineNum>>128);
                uint256 _mineAmount = mineRate*amount/calDecimals + mineAdd;
                minerBalances[addr][account] = minerBalances[addr][account].add(_mineAmount);
                //totalMinedCoin[addr] = totalMinedCoin[addr].add(_mineAmount);
                emit BuyingMiner(account,addr,_mineAmount);
            }
        }
    }
    /**
     * @dev changer mine coin distributed amount , only foundation owner can modify database.
     * @param mineCoin mine coin address
     * @param _mineAmount the distributed amount.
     */
    function setMineAmount(address mineCoin,uint256 _mineAmount)public onlyOwner {
        require(_mineAmount<1e30,"input mine amount is too large");
        _mineSettlement(mineCoin);
        mineAmount[mineCoin] = _mineAmount;
    }
    /**
     * @dev changer mine coin distributed time interval , only foundation owner can modify database.
     * @param mineCoin mine coin address
     * @param _mineInterval the distributed time interval.
     */
    function setMineInterval(address mineCoin,uint256 _mineInterval)public onlyOwner {
        require(_mineInterval>0,"input mine Interval must larger than zero");
        _mineSettlement(mineCoin);
        mineInterval[mineCoin] = _mineInterval;
    }
    /**
     * @dev user redeem mine rewards.
     * @param mineCoin mine coin address
     * @param amount redeem amount.
     */
    function redeemMinerCoin(address mineCoin,uint256 amount)public nonReentrant notHalted {
        _mineSettlement(mineCoin);
        _settlementAllCoin(mineCoin,msg.sender);
        uint256 minerAmount = minerBalances[mineCoin][msg.sender];
        require(minerAmount>=amount,"miner balance is insufficient");

        minerBalances[mineCoin][msg.sender] = minerAmount-amount;
        _redeemMineCoin(mineCoin,msg.sender,amount);
    }
    /**
     * @dev subfunction for user redeem mine rewards.
     * @param mineCoin mine coin address
     * @param recieptor recieptor's account
     * @param amount redeem amount.
     */
    function _redeemMineCoin(address mineCoin,address payable recieptor,uint256 amount)internal {
        if (amount == 0){
            return;
        }
        if (mineCoin == address(0)){
            recieptor.transfer(amount);
        }else{
            IERC20 minerToken = IERC20(mineCoin);
            uint256 preBalance = minerToken.balanceOf(address(this));
            SafeERC20.safeTransfer(minerToken,recieptor,amount);
//            minerToken.transfer(recieptor,amount);
            uint256 afterBalance = minerToken.balanceOf(address(this));
            require(preBalance - afterBalance == amount,"settlement token transfer error!");
        }
        emit RedeemMineCoin(recieptor,mineCoin,amount);
    }
    /**
     * @dev settle all mine coin.
     */    
    function _mineSettlementAll()internal{
        uint256 addrLen = whiteList.length;
        for(uint256 i=0;i<addrLen;i++){
            _mineSettlement(whiteList[i]);
        }
    }
    /**
     * @dev the auxiliary function for _mineSettlementAll.
     */    
    function _mineSettlement(address mineCoin)internal{
        uint256 latestMined = _getLatestMined(mineCoin);
        uint256 _mineInterval = mineInterval[mineCoin];
        if (latestMined>0){
            totalMinedWorth[mineCoin] = totalMinedWorth[mineCoin].add(latestMined.mul(calDecimals));
            totalMinedCoin[mineCoin] = totalMinedCoin[mineCoin]+latestMined;
        }
        if (_mineInterval>0){
            latestSettleTime[mineCoin] = now/_mineInterval*_mineInterval;
        }else{
            latestSettleTime[mineCoin] = now;
        }
    }
    /**
     * @dev the auxiliary function for _mineSettlementAll. Calculate latest time phase distributied mine amount.
     */ 
    function _getLatestMined(address mineCoin)internal view returns(uint256){
        uint256 _mineInterval = mineInterval[mineCoin];
        uint256 _totalSupply = totalSupply();
        if (_totalSupply > 0 && _mineInterval>0){
            uint256 _mineAmount = mineAmount[mineCoin];
            uint256 mintTime = (now-latestSettleTime[mineCoin])/_mineInterval;
            uint256 latestMined = _mineAmount*mintTime;
            return latestMined;
        }
        return 0;
    }
    /**
     * @dev subfunction, transfer mineCoin to recieptor when account transfer amount FPTCoin to recieptor
     * @param account the account transfer from
     * @param recipient the account transfer to
     * @param amount the mine shared amount
     */
    function _transferMinerCoin(address account,address recipient,uint256 amount)internal{
        uint256 addrLen = whiteList.length;
        for(uint256 i=0;i<addrLen;i++){
            settleMinerBalance(whiteList[i],account,recipient,amount,opTransferCoin);
        }
        emit TranserMiner(account,recipient,amount);
    }
    /**
     * @dev subfunction, mint mineCoin to account when account add collateral to collateral pool
     * @param account user's account
     * @param amount the mine shared amount
     */
    function _mintMinerCoin(address account,uint256 amount)internal{
        uint256 addrLen = whiteList.length;
        for(uint256 i=0;i<addrLen;i++){
            settleMinerBalance(whiteList[i],account,address(0),amount,opMintCoin);
        }
    }
    /**
     * @dev subfunction, settle user's mint balance when user want to modify mine database.
     * @param mineCoin the mine coin address
     * @param account user's account
     */
    function _settlementAllCoin(address mineCoin,address account)internal{
        settleMinerBalance(mineCoin,account,address(0),0,0);
    }
    /**
     * @dev subfunction, Burn mineCoin to account when account redeem collateral to collateral pool
     * @param account user's account
     * @param amount the mine shared amount
     */
    function _burnMinerCoin(address account,uint256 amount)internal{
        uint256 addrLen = whiteList.length;
        for(uint256 i=0;i<addrLen;i++){
            settleMinerBalance(whiteList[i],account,address(0),amount,opBurnCoin);
        }
    }
    /**
     * @dev settle user's mint balance when user want to modify mine database.
     * @param mineCoin the mine coin address
     * @param account user's account
     * @param recipient the recipient's address if operator is transfer
     * @param amount the input amount for operator
     * @param operators User operator to modify mine database.
     */
    function settleMinerBalance(address mineCoin,address account,address recipient,uint256 amount,uint256 operators)internal{
        uint256 _totalSupply = totalSupply();
        uint256 tokenNetWorth = _getTokenNetWorth(mineCoin);
        if (_totalSupply > 0){
            minerBalances[mineCoin][account] = minerBalances[mineCoin][account].add(
                    _settlement(mineCoin,account,balanceOf(account),tokenNetWorth));
            if (operators == opBurnCoin){
                totalMinedWorth[mineCoin] = totalMinedWorth[mineCoin].sub(tokenNetWorth.mul(amount));
            }else if (operators==opMintCoin){
                totalMinedWorth[mineCoin] = totalMinedWorth[mineCoin].add(tokenNetWorth.mul(amount));
            }else if (operators==opTransferCoin){
                minerBalances[mineCoin][recipient] = minerBalances[mineCoin][recipient].add(
                    _settlement(mineCoin,recipient,balanceOf(recipient),tokenNetWorth));
                minerOrigins[mineCoin][recipient] = tokenNetWorth;
            }
        }
        minerOrigins[mineCoin][account] = tokenNetWorth;
    }
    /**
     * @dev subfunction, settle user's latest mine amount.
     * @param mineCoin the mine coin address
     * @param account user's account
     * @param amount the input amount for operator
     * @param tokenNetWorth the latest token net worth
     */
    function _settlement(address mineCoin,address account,uint256 amount,uint256 tokenNetWorth)internal view returns (uint256) {
        uint256 origin = minerOrigins[mineCoin][account];
        require(tokenNetWorth>=origin,"error: tokenNetWorth logic error!");
        return amount.mul(tokenNetWorth-origin)/calDecimals;
    }
    /**
     * @dev subfunction, calculate current token net worth.
     * @param mineCoin the mine coin address
     */
    function _getCurrentTokenNetWorth(address mineCoin)internal view returns (uint256) {
        uint256 latestMined = _getLatestMined(mineCoin);
        uint256 _totalSupply = totalSupply();
        if (_totalSupply > 0){
            return (totalMinedWorth[mineCoin].add(latestMined*calDecimals))/_totalSupply;
        }
        return 0;
    }
    /**
     * @dev subfunction, calculate token net worth when settlement is completed.
     * @param mineCoin the mine coin address
     */
    function _getTokenNetWorth(address mineCoin)internal view returns (uint256) {
        uint256 _totalSupply = totalSupply();
        if (_totalSupply > 0){
            return totalMinedWorth[mineCoin]/_totalSupply;
        }
        return 0;
    }
    /**
     * @dev get FPTCoin's total supply.
     */
    function totalSupply()internal view returns(uint256){
        IERC20 _FPTCoin = IERC20(getManager());
        return _FPTCoin.totalSupply();
    }
    /**
     * @dev get FPTCoin's user balance.
     */
    function balanceOf(address account)internal view returns(uint256){
        IERC20 _FPTCoin = IERC20(getManager());
        return _FPTCoin.balanceOf(account);
    }
}