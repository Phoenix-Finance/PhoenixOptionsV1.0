pragma solidity ^0.4.26;
import "./OptionslPool.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./SharedCoin.sol";
import "./underlyingAssets.sol";

contract CollateralPool is OptionslPool,ReentrancyGuard,SharedCoin {
    using SafeMath for uint256;
    uint256 private _calDecimal = 10000000000;
    //address collaterel
    mapping (address => uint256) public collateralBalances;
    mapping (address => uint256) public PremiumBalances;
    //token net worth till tillBlockNumber
    uint256 public tokenNetWorth = 1e8;
    //user paying for collateral usd;
    mapping (address => uint256) public userCollateralPaying;
    //account -> collateral -> amount
    mapping (address => mapping (address => uint256)) public userInputCollateral;
    function addCollateral(address collateral,uint256 amount)public payable {
        collateralBalances[collateral] = collateralBalances[collateral].add(amount);
        userInputCollateral[msg.sender][collateral] = userInputCollateral[msg.sender][collateral].add(amount);
        uint256 price = _oracle.getPrice(collateral);
        uint256 userPaying = price.mul(amount);
        uint256 mintAmount = userPaying.div(tokenNetWorth);
        userCollateralPaying[msg.sender] = userCollateralPaying[msg.sender].add(userPaying);
        _mint(msg.sender,mintAmount);
    }
    //calculate token
    function redeemCollateral(uint256 tokenAmount,address collateral)public {
        require(balances[msg.sender]>=tokenAmount,"SCoin balance is insufficient!");
        if (tokenAmount == 0){
            return;
        }
        uint256 totalOccupied = getTotalOccupiedCollateral();
        uint256 totalWorth = _totalSupply.mul(tokenNetWorth);
        uint256 redeemWorth = tokenAmount.mul(tokenNetWorth);
        if (totalOccupied.add(redeemWorth)<=totalWorth) {
            uint256 redeemPaying = userCollateralPaying[msg.sender].mul(tokenAmount).div(balances[msg.sender]);
            userCollateralPaying[msg.sender] = userCollateralPaying[msg.sender].sub(redeemPaying);
            _burn(msg.sender, tokenAmount);
            uint256 worth = tokenAmount.mul(tokenNetWorth);
            worth = _redeemCollateral(worth,collateral);
            for (uint256 i=0;worth>0 && i<whiteList.length;i++){
                worth = _redeemCollateral(worth,whiteList[i]);    
            } 
            _paybackWorth(worth);
        }
    }
    function _redeemCollateral(uint256 worth,address collateral)internal returns (uint256){
        uint256 amount = userInputCollateral[msg.sender][collateral];
        if (amount == 0){
            return worth;
        }
        uint256 price = _oracle.getPrice(collateral);
        uint256 redeemAmount = worth.div(price);
        if (redeemAmount == 0){
            return 0;
        }
        uint256 transferAmount = (redeemAmount>amount) ? amount : redeemAmount;
        userInputCollateral[msg.sender][collateral] = userInputCollateral[msg.sender][collateral].sub(transferAmount);
        _transferPayback(msg.sender,collateral,transferAmount);
        if (redeemAmount>amount){
            return worth.sub(transferAmount.mul(price));
        }
        return 0;
    }
    function _paybackWorth(uint256 worth) internal {
        if (worth == 0){
            return;
        }
        uint256 totalCal = worth.mul(_calDecimal);
        uint256 totalNum = 0;
        uint256 totalPrice = 0;
        for (uint256 i=0;i<whiteList.length;i++){
            totalNum = totalNum.add(PremiumBalances[whiteList[i]]);
            uint256 price = _oracle.getPrice(whiteList[i]);
            totalPrice.add(price.mul(PremiumBalances[whiteList[i]]));
        }
        uint256 rate = totalCal.mul(totalNum).div(totalPrice);
        for (i=0;i<whiteList.length;i++){
            uint256 _payBack = PremiumBalances[whiteList[i]].mul(rate).div(totalNum).div(_calDecimal);
            PremiumBalances[whiteList[i]] = PremiumBalances[whiteList[i]].sub(_payBack);
            _transferPayback(msg.sender,whiteList[i],_payBack);
        } 
    }
}