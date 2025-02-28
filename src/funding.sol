// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {PriceConverter} from './priceConverter.sol';

error NotOwner();
error must_be_greater_than_zero();
contract Funding is PriceConverter {
    address public immutable i_owner;
    uint256 constant MINIMUM_USD = 2e18;
    mapping(address => uint256) public userBalance;
    address[] public funders;
    mapping(address => bool) public isFunder;

    
    // sepolia eth/usd price feed : 0x694AA1769357215DE4FAC081bf1f309aDC325306
    
    constructor() {
        i_owner=msg.sender;
    }

    modifier onlyOwner(){
if (msg.sender != i_owner) revert NotOwner();
        // if(msg.sender != i_owner) {revert NotOwner();}
        _;
    }

    function fund() public payable {
        require(msg.value >= MINIMUM_USD, "Not enough amount") ;
        userBalance[msg.sender] += msg.value;
        funders.push(msg.sender);
        isFunder[msg.sender] = true;
    }

    // Wrapper function to access price conversion
    function getPriceConversion(uint256 _ethAmount) public view returns(uint256) {
        return priceConvertion(_ethAmount);
    }

    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "contract balance is zero");
        for(uint256 i = 0; i < funders.length; i++) {
            userBalance[funders[i]] = 0;
        }
        payable(i_owner).transfer(address(this).balance);
    }

    
    function claimFunds() public {
        uint256 amount = userBalance[msg.sender];
        require(amount > 0, "No funds to claim");
        userBalance[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }

    function usersWithdraw(uint256 _amount) public {
        require(_amount > 0, "Amount must be greater than zero");
        require(userBalance[msg.sender] >= _amount, "Insufficient balance");
        userBalance[msg.sender] -= _amount;
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Transfer failed");
    }

    receive() external payable {
        fund();
     }

   
}