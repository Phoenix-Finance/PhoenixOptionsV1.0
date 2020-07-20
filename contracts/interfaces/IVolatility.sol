pragma solidity ^0.4.26;
interface IVolatility {
    function calculateIv(uint256 expiration,uint256 price)external view returns (uint256,uint256);
}