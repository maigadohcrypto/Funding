// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "forge-std/Test.sol";
import "../src/funding.sol";
import {AggregatorV3Interface} from "lib/foundry-chainlink-toolkit/src/interfaces/feeds/AggregatorV3Interface.sol";

contract FundingGasTest is Test {
    Funding funding;
    address owner = address(0x123);
    address user1 = address(0x456);
    uint256 initialPrice = 2000e18;

    function setUp() public {
        vm.startPrank(owner);
        funding = new Funding();
        // Set up mock price feed
        vm.mockCall(
            address(0x694AA1769357215DE4FAC081bf1f309aDC325306),
            abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
            abi.encode(0, int256(initialPrice), 0, block.timestamp, 0)
        );
        vm.stopPrank();
    }

    function test_Gas_Fund() public {
        uint256 amount = 2 ether;
        vm.deal(user1, amount);

        vm.prank(user1);
        uint256 gasBefore = gasleft();
        funding.fund{value: amount}();
        uint256 gasUsed = gasBefore - gasleft();

        emit log_named_uint("Gas used for fund()", gasUsed);
    }

    function test_Gas_Withdraw() public {
        uint256 amount = 2 ether;
        vm.deal(user1, amount);
        vm.prank(user1);
        funding.fund{value: amount}();

        vm.prank(owner);
        uint256 gasBefore = gasleft();
        funding.withdraw();
        uint256 gasUsed = gasBefore - gasleft();

        emit log_named_uint("Gas used for withdraw()", gasUsed);
    }

    function test_Gas_UsersWithdraw() public {
        uint256 amount = 2 ether;
        vm.deal(user1, amount);
        vm.prank(user1);
        funding.fund{value: amount}();

        uint256 withdrawAmount = 1 ether;
        vm.prank(user1);
        uint256 gasBefore = gasleft();
        funding.usersWithdraw(withdrawAmount);
        uint256 gasUsed = gasBefore - gasleft();

        emit log_named_uint("Gas used for usersWithdraw()", gasUsed);
    }

    function test_Gas_PriceConversion() public {
        uint256 ethAmount = 1 ether;

        uint256 gasBefore = gasleft();
        funding.getPriceConversion(ethAmount);
        uint256 gasUsed = gasBefore - gasleft();

        emit log_named_uint("Gas used for getPriceConversion()", gasUsed);
    }

    function test_Gas_Fund_MultipleUsers() public {
        uint256 amount = 2 ether;
        address[10] memory users;

        // Fund with 10 unique users
        for (uint256 i = 0; i < 10; i++) {
            users[i] = address(uint160(0x100 + i));
            vm.deal(users[i], amount);
            vm.prank(users[i]);
            funding.fund{value: amount}();
        }

        // Measure gas for 11th unique user
        address newUser = address(uint160(0x200));
        vm.deal(newUser, amount);

        uint256 gasBefore = gasleft();
        vm.prank(newUser);
        funding.fund{value: amount}();
        uint256 gasUsed = gasBefore - gasleft();

        emit log_named_uint("Gas used for fund() with 10 existing users", gasUsed);

        // Test claimFunds() gas usage
        vm.prank(users[0]);
        gasBefore = gasleft();
        funding.claimFunds();
        gasUsed = gasBefore - gasleft();
        emit log_named_uint("Gas used for claimFunds()", gasUsed);
    }
}
