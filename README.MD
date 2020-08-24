
# Options Contract

Options Contract v2 is a permissionless options pool protocal stack.

## Environment

Our development environment consists of the following:

-   Buidler - Framework
-   Solidity Visual Auditor - VS Code
-   Web3/Truffle plugins for Buidler
-   Mocha - testing framework
-   Truffle assertions - unit testing

## contracts

### FPTCoin

The FPTCoin is an ERC20 token. It inherits the ERC-20 token standard.It is finnexus collateral Pool token. Its inside value is collatral pool net worth.

### FNXMinePool

The FNXMinePool is FPTCoin mine pool, which manager contract is FPTCoin.
A smart-contract which distribute some mine coins buy FPTCoin balance.

### CollateralPool

The CollateralPool is collateral pool contract whcich stores users' deposit collateral coin and necessary storage data.

### OptionsManagerV2

The OptionsManager is a manager contract for Options tokens. It can 
-  buy, sell or exercise options token.
-  add or redeem collateral.

### OptionsPrice

The OptionsPrice is an Options price calculation contract, which calculates options' price, using B-S formulas.

### ImpliedVolatility

The ImpliedVolatility is an Options Implied volatility calculation.
