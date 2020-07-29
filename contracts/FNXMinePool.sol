pragma solidity ^0.4.26;
import "./modules/SafeMath.sol";
import "./modules/Managerable.sol";
import "./modules/AddressWhiteList.sol";
import "./modules/ReentrancyGuard.sol";
import "./interfaces/IERC20.sol";
contract FNXMinePool is Managerable,AddressWhiteList,ReentrancyGuard {
    using SafeMath for uint256;
    uint256 constant calDecimals = 1e18;
    mapping(address=>mapping(address=>uint256)) internal minerBalances;
    mapping(address=>mapping(address=>uint256)) internal minerOrigins;
    mapping(address=>uint256) internal totalMinedWorth;
    mapping(address=>uint256) internal totalMinedCoin;
    mapping(address=>uint256) internal latestSettleTime;
    mapping(address=>uint256) internal mineAmount;
    mapping(address=>uint256) internal mineInterval;
    struct buyingMine {
        address mineCoin;
        uint256 mineAmount;
    }
    buyingMine[] internal buyingMineInfo;
    uint256 constant opBurnCoin = 1;
    uint256 constant opMintCoin = 2;
    uint256 constant opTransferCoin = 3;
    constructor () public{
    }
    function()public payable{

    }
    event RedeemMineCoin(address indexed from, address indexed to, uint256 value);
    function getTotalMined(address mineCoin)public view returns(uint256){
        uint256 _totalSupply = totalSupply();
        uint256 _mineInterval = mineInterval[mineCoin];
        if (_totalSupply > 0 && _mineInterval>0){
            uint256 _mineAmount = mineAmount[mineCoin];
            uint256 latestMined = _mineAmount.mul(now-latestSettleTime[mineCoin]).div(_mineInterval);
            return totalMinedCoin[mineCoin] + latestMined;
        }
        return totalMinedCoin[mineCoin];
    }
    function getMineInfo(address mineCoin)public view returns(uint256,uint256){
        return (mineAmount[mineCoin],mineInterval[mineCoin]);
    }

    function getMinerBalance(address account,address mineCoin)public view returns(uint256){
        uint256 totalBalance = minerBalances[mineCoin][account];
        uint256 _totalSupply = totalSupply();
        uint256 balance = balanceOf(account);
        if (_totalSupply > 0 && balance>0){
            uint256 tokenNetWorth = _getTokenNetWorth(mineCoin);
            totalBalance= totalBalance.add(_settlement(mineCoin,account,balance,tokenNetWorth));
        }
        return totalBalance;
    }
    function setMineCoinInfo(address mineCoin,uint256 _mineAmount,uint256 _mineInterval)public onlyOwner {
        _mineSettlement(mineCoin);
        mineAmount[mineCoin] = _mineAmount;
        mineInterval[mineCoin] = _mineInterval;
        addWhiteList(mineCoin);
    }
    function transferMinerCoin(address account,address recieptor,uint256 amount) public onlyManager {
        _mineSettlementAll();
        _transferMinerCoin(account,recieptor,amount);
    }
    function mintMinerCoin(address account,uint256 amount) public onlyManager {
        _mineSettlementAll();
        _mintMinerCoin(account,amount);
    }
    function burnMinerCoin(address account,uint256 amount) public onlyManager {
        _mineSettlementAll();
        _burnMinerCoin(account,amount);
    }
    function addMinerBalance(address account,uint256 amount) public onlyManager {
        uint256 len = buyingMineInfo.length;
        for (uint256 i=0;i<len;i++){
            buyingMine memory info = buyingMineInfo[i];
            uint256 _mineAmount = info.mineAmount.mul(amount).div(calDecimals);
            minerBalances[info.mineCoin][account] = minerBalances[info.mineCoin][account].add(_mineAmount);
            totalMinedCoin[info.mineCoin] = totalMinedCoin[info.mineCoin].add(_mineAmount);
        }
    }
    function setMineAmount(address mineCoin,uint256 _mineAmount)public onlyOwner {
        _mineSettlement(mineCoin);
        mineAmount[mineCoin] = _mineAmount;
    }
    function setMineInterval(address mineCoin,uint256 _mineInterval)public onlyOwner {
        _mineSettlement(mineCoin);
        mineInterval[mineCoin] = _mineInterval;
    }
    function redeemMinerCoin(address mineCoin,uint256 amount)public nonReentrant notHalted {
        _mineSettlement(mineCoin);
        _settlementAllCoin(mineCoin,msg.sender);
        uint256 minerAmount = minerBalances[mineCoin][msg.sender];
        require(minerAmount>=amount,"miner balance is insufficient");
        minerBalances[mineCoin][msg.sender] = minerAmount.sub(amount);
        _redeemMineCoin(mineCoin,msg.sender,amount);
    }
    function _redeemMineCoin(address mineCoin,address recieptor,uint256 amount)internal {
        if (amount == 0){
            return;
        }
        if (mineCoin == address(0)){
            recieptor.transfer(amount);
        }else{
            IERC20 minerToken = IERC20(mineCoin);
            minerToken.transfer(recieptor,amount);
        }
        emit RedeemMineCoin(recieptor,mineCoin,amount);
    }
    function _mineSettlementAll()internal{
        uint256 addrLen = whiteList.length;
        for(uint256 i=0;i<addrLen;i++){
            _mineSettlement(whiteList[i]);
        }
    }
    function _mineSettlement(address mineCoin)internal{
        uint256 _mineInterval = mineInterval[mineCoin];
        uint256 _totalSupply = totalSupply();
        if (_totalSupply > 0 && _mineInterval>0){
            uint256 _mineAmount = mineAmount[mineCoin];
            uint256 latestMined = _mineAmount.mul(now-latestSettleTime[mineCoin]).div(_mineInterval);
            totalMinedWorth[mineCoin] = totalMinedWorth[mineCoin].add(latestMined*calDecimals);
            totalMinedCoin[mineCoin] = totalMinedCoin[mineCoin].add(latestMined);
        }
        if (_mineInterval>0){
            latestSettleTime[mineCoin] = now.div(_mineInterval)*_mineInterval;
        }else{
            latestSettleTime[mineCoin] = now;
        }
    }
    function _transferMinerCoin(address account,address recipient,uint256 amount)internal{
        uint256 addrLen = whiteList.length;
        for(uint256 i=0;i<addrLen;i++){
            settleMinerBalance(whiteList[i],account,recipient,amount,opTransferCoin);
        }
    }
    function _mintMinerCoin(address account,uint256 amount)internal{
        uint256 addrLen = whiteList.length;
        for(uint256 i=0;i<addrLen;i++){
            settleMinerBalance(whiteList[i],account,address(0),amount,opMintCoin);
        }
    }
    function _settlementAllCoin(address mineCoin,address account)internal{
        settleMinerBalance(mineCoin,account,address(0),0,0);
    }
    function _burnMinerCoin(address account,uint256 amount)internal{
        uint256 addrLen = whiteList.length;
        for(uint256 i=0;i<addrLen;i++){
            settleMinerBalance(whiteList[i],account,address(0),amount,opBurnCoin);
        }
    }
    function settleMinerBalance(address mineCoin,address account,address recipient,uint256 amount,uint256 operators)internal{
        uint256 _totalSupply = totalSupply();
        if (_totalSupply > 0){
            uint256 tokenNetWorth = _getTokenNetWorth(mineCoin);
            if(amount>0){
                minerBalances[mineCoin][account] = minerBalances[mineCoin][account].add(
                        _settlement(mineCoin,account,balanceOf(account),tokenNetWorth));
                if (operators == opBurnCoin){
                    totalMinedWorth[mineCoin] = totalMinedWorth[mineCoin].sub(tokenNetWorth.mul(amount));
                }else if (operators==opMintCoin){
                    totalMinedWorth[mineCoin] = totalMinedWorth[mineCoin].add(tokenNetWorth.mul(amount));
                }else if (operators==opTransferCoin){
                    minerOrigins[mineCoin][recipient] = tokenNetWorth;
                }
            }
            minerOrigins[mineCoin][account] = tokenNetWorth;
        }
    }
    function _settlement(address mineCoin,address account,uint256 amount,uint256 tokenNetWorth)internal view returns (uint256) {
        uint256 origin = minerOrigins[mineCoin][account];
        require(tokenNetWorth>=origin,"error: tokenNetWorth logic error!");
        return amount.mul(tokenNetWorth-origin).div(calDecimals);
    }
    function _getTokenNetWorth(address mineCoin)internal view returns (uint256) {
        uint256 _totalSupply = totalSupply();
        if (_totalSupply > 0){
            totalMinedWorth[mineCoin].div(_totalSupply);
        }
        return 0;
    }
    function totalSupply()internal view returns(uint256){
        IERC20 _FCTCoin = IERC20(getManager());
        return _FCTCoin.totalSupply();
    }
    function balanceOf(address account)internal view returns(uint256){
        IERC20 _FCTCoin = IERC20(getManager());
        return _FCTCoin.balanceOf(account);
    }
}