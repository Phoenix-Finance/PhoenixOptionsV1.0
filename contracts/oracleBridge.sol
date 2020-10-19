pragma solidity =0.5.16;
import "./interfaces/IFnxPriceDb.sol";
contract oracleBridge is ImportFnxPriceDb {
    mapping (address=>string) private assetsMap;
    mapping (uint256=>string) private underlyingsMap;
    uint256 constant private maxPrice = 1<<60;
    uint256 constant private minPrice = 100;
    constructor () public{
        assetsMap[address(0)] = "WAN";
        assetsMap[0xdF228001e053641FAd2BD84986413Af3BeD03E0B] = "FNX";
        underlyingsMap[1] = "BTC";
        underlyingsMap[2] = "ETH";
    }
    function getPrice(address asset) public view returns (uint256) {
        string memory symbol = assetsMap[asset];
        require(bytes(symbol).length > 0,"Asset is not supported!");
        uint256 price = _FnxPriceDb.getPrice(symbol);
        require(price > minPrice && price < maxPrice,"Asset price is got failed!");
        return price / 10;

    }
    function getUnderlyingPrice(uint256 underlying) public view returns (uint256) {
        string memory symbol = underlyingsMap[underlying];
        require(bytes(symbol).length > 0,"Asset is not supported!");
        uint256 price = _FnxPriceDb.getPrice(symbol);
        require(price > minPrice && price < maxPrice,"underlying price is got failed!");
        return price / 10;
    }
}
