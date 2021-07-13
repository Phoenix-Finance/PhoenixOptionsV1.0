pragma solidity =0.5.16;
import "../optionsFactory/optionsFactory.sol";
contract testOptionsFactory is optionsFactory{
    address public latestAddress;
    constructor (address multiSignature) optionsFactory(multiSignature) public{

    }
    function testCreatePPTCoin() public {
        latestAddress = createPPTCoin();
    }
    function testCreateOptionsPool(uint32[] memory underlyings) public {
        latestAddress = createOptionsPool(underlyings);
    }
    function testCreateCollateralPool(uint32[] memory underlyings) public {
        address optionsPool = createOptionsPool(underlyings);
        latestAddress = createCollateralPool(optionsPool);
    }
    function testSetProxyManager(address proxy,address manager)public {
        proxyOperator(proxy).setManager(manager);
    }
    function testCreateMinePool() public {
        latestAddress = createAcceleratedMinePool();
    }
}