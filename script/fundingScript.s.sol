// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import {Script, console} from "forge-std/Script.sol";
import {Funding} from "../src/funding.sol";

contract FundingScript is Script {
    Funding public funding;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        funding = new Funding();

        vm.stopBroadcast();
    }
}
