// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "forge-std/Test.sol";
import "../src/funding.sol";
import {AggregatorV3Interface} from "lib/foundry-chainlink-toolkit/src/interfaces/feeds/AggregatorV3Interface.sol";

contract FundingTest is Test {
    Funding funding;
    address owner = address(0x123);
    address user1 = address(0x456);
    address user2 = address(0x789);
    uint256 initialPrice = 2000e18; // $2000 per ETH

    function setUp() public {
        vm.startPrank(owner);
        // Deploy Funding contract with mock price feed
        funding = new Funding();
        // Set initial price
        vm.mockCall(
            address(0x694AA1769357215DE4FAC081bf1f309aDC325306),
            abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
            abi.encode(0, int256(initialPrice), 0, block.timestamp, 0)
        );
        vm.stopPrank();
    }

    function test_OwnerSetCorrectly() public view {
        assertEq(funding.i_owner(), owner);
    }

    function test_FundWithValidAmount() public {
        uint256 amount = 2 ether; // Minimum required amount
        vm.deal(user1, amount);
        vm.prank(user1);
        funding.fund{value: amount}();

        assertEq(funding.userBalance(user1), amount);
        assertEq(funding.funders(0), user1);
    }

    function test_FundWithInvalidAmount() public {
        uint256 amount = 0.0009 ether; // Below minimum
        vm.deal(user1, amount);
        vm.prank(user1);
        vm.expectRevert("Not enough amount");
        funding.fund{value: amount}();
    }

    function test_WithdrawByOwner() public {
        // Fund first
        uint256 amount = 2 ether;
        vm.deal(user1, amount);
        vm.prank(user1);
        funding.fund{value: amount}();

        // Withdraw
        vm.prank(owner);
        funding.withdraw();

        assertEq(address(funding).balance, 0 ether);
        assertEq(owner.balance, amount);
    }

    function test_WithdrawByNonOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        funding.withdraw();
    }

    function test_UsersWithdrawValidAmount() public {
        // Fund first
        uint256 amount = 2 ether;
        vm.deal(user1, amount);
        vm.prank(user1);
        funding.fund{value: amount}();

        // Withdraw
        uint256 withdrawAmount = 1 ether;
        vm.prank(user1);
        funding.usersWithdraw(withdrawAmount);

        assertEq(funding.userBalance(user1), amount - withdrawAmount);
        assertEq(user1.balance, withdrawAmount);
    }

    function test_UsersWithdrawInvalidAmount() public {
        // Fund first
        uint256 amount = 2 ether;
        vm.deal(user1, amount);
        vm.prank(user1);
        funding.fund{value: amount}();

        // Attempt invalid withdraw
        vm.prank(user1);
        vm.expectRevert("Insufficient balance");
        funding.usersWithdraw(amount + 1 ether);
    }

    function test_UsersWithdrawZeroAmount() public {
        // Fund first
        uint256 amount = 2 ether;
        vm.deal(user1, amount);
        vm.prank(user1);
        funding.fund{value: amount}();

        // Attempt to withdraw zero amount
        vm.prank(user1);
        vm.expectRevert("Amount must be greater than zero");
        funding.usersWithdraw(0);
    }

    function test_WithdrawWithZeroBalance() public {
        // Attempt to withdraw with zero balance
        vm.prank(owner);
        vm.expectRevert("contract balance is zero");
        funding.withdraw();
    }

    function test_WithdrawUpdatesBalances() public {
        // Fund first
        uint256 amount = 2 ether;
        vm.deal(user1, amount);
        vm.prank(user1);
        funding.fund{value: amount}();

        // Withdraw
        vm.prank(owner);
        funding.withdraw();

        // Check that user balance is updated correctly
        assertEq(funding.userBalance(user1), 0 ether);
    }

    function test_WithdrawAllFunds() public {
        // Fund first
        uint256 amount = 2 ether;
        vm.deal(user1, amount);
        vm.prank(user1);
        funding.fund{value: amount}();

        // Withdraw all funds
        vm.prank(owner);
        funding.withdraw();

        // Check that the contract balance is zero
        assertEq(address(funding).balance, 0);
    }

    function test_UsersWithdrawExceedingBalance() public {
        // Fund
        uint256 amount = 2 ether;
        vm.deal(user1, amount);
        vm.prank(user1);
        funding.fund{value: amount}();

        // Attempt to withdraw more than the balance
        vm.prank(user1);
        vm.expectRevert("Insufficient balance");
        funding.usersWithdraw(amount + 1 ether);
    }

    function test_UsersWithdrawPartialAmount() public {
        uint256 amount = 2 ether;
        vm.deal(user1, amount);
        vm.prank(user1);
        funding.fund{value: amount}();

        // Withdraw a partial amount
        uint256 withdrawAmount = 1 ether;
        vm.prank(user1);
        funding.usersWithdraw(withdrawAmount);

        // Check that the user balance is updated correctly
        assertEq(funding.userBalance(user1), amount - withdrawAmount);
    }

    function test_ReceiveFallback() public {
        uint256 amount = 2 ether;
        vm.deal(user1, amount);
        vm.prank(user1);
        (bool success,) = address(funding).call{value: amount}("");
        require(success, "Transfer failed");

        assertEq(funding.userBalance(user1), amount);
        assertEq(funding.isFunder(user1), true);
    }

    function test_PriceConversion() public view {
        // Test conversion of 1 ETH to USD
        uint256 ethAmount = 1 ether;

        // Get the price from the mock feed (2000 with 8 decimals)
        (, int256 price,,,) = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306).latestRoundData();

        // Expected USD value = (ethAmount * price * 1e10) / 1e18
        // Scale price feed's 8 decimals to 18 decimals by multiplying by 1e10
        uint256 expectedUsd = (ethAmount * uint256(price) * 1e10) / 1e18;

        // Get conversion result from contract
        uint256 result = funding.getPriceConversion(ethAmount);

        // Verify conversion matches expected value
        assertEq(result, expectedUsd);
    }
}
