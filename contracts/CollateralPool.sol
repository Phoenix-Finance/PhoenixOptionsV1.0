pragma solidity ^0.4.26;
import "./OptionsPool.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./SharedCoin.sol";
import "./underlyingAssets.sol";

contract CollateralPool is OptionsPool,ReentrancyGuard,SharedCoin {
    using SafeMath for uint256;
    uint256 private _calDecimal = 10000000000;
    fraction public collateralRate;
    enum eBalance{
        collateral,
        premium
    }
    //address collaterel
    mapping (address => uint256) public collateralBalances;
    mapping (address => uint256) public premiumBalances;
    //token net worth till tillBlockNumber
    uint256 public tokenNetWorth = 1e8;
    //user paying for collateral usd;
    mapping (address => uint256) public userCollateralPaying;
    //account -> collateral -> amount
    mapping (address => mapping (address => uint256)) public userInputCollateral;

    function addCollateral(address collateral,uint256 amount)public payable {
        amount = getPayableAmount(collateral,amount);
        require(amount>0 , "settlement amount is zero!");
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
        require(isEligibleAddress(collateral) , "settlement is unsupported token");
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
            uint256 redeemColFee = 4;
            worth = _redeemCollateral(worth,collateral,redeemColFee);
            for (uint256 i=0;worth>0 && i<whiteList.length;i++){
                worth = _redeemCollateral(worth,whiteList[i],redeemColFee);    
            } 
            _paybackWorth(worth,redeemColFee);
        }
    }
    function _redeemCollateral(uint256 worth,address collateral,uint256 feeType)internal returns (uint256){
        require(isEligibleAddress(collateral) , "settlement is unsupported token");
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
        _transferPaybackAndFee(msg.sender,collateral,transferAmount,feeType);
        if (redeemAmount>amount){
            return worth.sub(transferAmount.mul(price));
        }
        return 0;
    }
    function _paybackWorth(uint256 worth,uint256 feeType) internal {
        _paybackWorth_sub(eBalance.premium,worth,feeType);
    }
    function _paybackWorth_sub(eBalance _balance,uint256 worth,uint256 feeType) internal returns (uint256) {
        if (worth == 0){
            return;
        }
        mapping (address => uint256) balances = _balance == eBalance.collateral ? collateralBalances : premiumBalances;
        uint256 totalNum = 0;
        uint256 totalPrice = 0;
        for (uint256 i=0;i<whiteList.length;i++){
            totalNum = totalNum.add(balances[whiteList[i]]);
            uint256 price = _oracle.getPrice(whiteList[i]);
            totalPrice.add(price.mul(balances[whiteList[i]]));
        }
        if (totalPrice == 0){
            return worth;
        }
        uint256 totalCal = worth;
        if (worth > totalPrice){
            worth = worth - totalPrice;
            totalCal = totalPrice;
        }else{
            worth = 0;
        }
        totalCal = totalCal.mul(_calDecimal);
        uint256 rate = totalCal.mul(totalNum).div(totalPrice);
        for (i=0;i<whiteList.length;i++){
            uint256 _payBack = balances[whiteList[i]].mul(rate).div(totalNum).div(_calDecimal);
            balances[whiteList[i]] = balances[whiteList[i]].sub(_payBack);
            _transferPaybackAndFee(msg.sender,whiteList[i],_payBack,feeType);
        } 
        return worth;
    }
    function getPayableAmount(address settlement,uint256 settlementAmount) internal returns (uint256) {
        require(isEligibleAddress(settlement) , "settlement is unsupported token");
        uint256 colAmount = 0;
        if (settlement == address(0)){
            colAmount = msg.value;
        }else if (settlementAmount > 0){
            IERC20 oToken = IERC20(settlement);
            oToken.transferFrom(msg.sender, address(this), settlementAmount);
            colAmount = settlementAmount;
        }
        return colAmount;
    }
    function calculateCollateral(uint256 amount)internal view returns (uint256){
        uint256 result = collateralRate.numerator.mul(amount);
        return result.div(collateralRate.denominator);
    }

}