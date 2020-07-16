
# Options Contract

Options Contract is a permissionless options protocal stack.

## Environment

Our development environment consists of the following:

-   Buidler - Framework
-   Solidity Visual Auditor - VS Code
-   Web3/Truffle plugins for Buidler
-   Mocha - testing framework
-   Truffle assertions - unit testing

## contracts

### OptionsToken

The OptionsToken is an ERC20 token with options expiration. It inherits the ERC-20 token standard.It can tranfer before expiration.


### OptionsManager

The OptionsManager is a manager contract for Options tokens. It can 
-  create an options token.
-  add collateral and mint optionsToken.
-  exercise options.
-  liquidate options.

### OptionsFormulas

The OptionsFormulas is a calculator for Options tokens.

### MatchMakingTrading

The MatchMakingTrading is a trading pool for Options tokens.
