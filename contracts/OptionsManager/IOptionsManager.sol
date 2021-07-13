pragma solidity =0.5.16;
interface IOptionsManager {
    function initAddresses(address[] calldata collateral,uint256[] calldata rate,address oracleAddr,address optionsPriceAddr,address optionsPoolAddr,address collateralPoolAddr,address PPTCoinAddr) external;
}