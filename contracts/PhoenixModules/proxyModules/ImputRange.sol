pragma solidity =0.5.16;
import './proxyOwner.sol';
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */
contract ImputRange is proxyOwner {
    
    //The maximum input amount limit.
    uint256 internal maxAmount;
    //The minimum input amount limit.
    uint256 internal minAmount;
    
    modifier InRange(uint256 amount) {
        require(maxAmount>=amount && minAmount<=amount,"input amount is out of input amount range");
        _;
    }
    /**
     * @dev Determine whether the input amount is within the valid range
     * @param amount Test value which is user input
     */
    function isInputAmountInRange(uint256 amount)public view returns (bool){
        return(maxAmount>=amount && minAmount<=amount);
    }
    /*
    function isInputAmountSmaller(uint256 Amount)public view returns (bool){
        return maxAmount>=amount;
    }
    function isInputAmountLarger(uint256 Amount)public view returns (bool){
        return minAmount<=amount;
    }
    */
    modifier Smaller(uint256 amount) {
        require(maxAmount>=amount,"input amount is larger than maximium");
        _;
    }
    modifier Larger(uint256 amount) {
        require(minAmount<=amount,"input amount is smaller than maximium");
        _;
    }
    /**
     * @dev get the valid range of input amount
     */
    function getInputAmountRange() public view returns(uint256,uint256) {
        return (minAmount,maxAmount);
    }
    /**
     * @dev set the valid range of input amount
     * @param _minAmount the minimum input amount limit
     * @param _maxAmount the maximum input amount limit
     */
    function setInputAmountRange(uint256 _minAmount,uint256 _maxAmount) public OwnerOrOrigin{
        minAmount = _minAmount;
        maxAmount = _maxAmount;
    }        
}