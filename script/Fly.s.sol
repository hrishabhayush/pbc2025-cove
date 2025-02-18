// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {Fly} from "../src/Fly.sol";

contract FlyScript is Script {
    Fly public fly;

    function setUp() public {
        fly = new Fly();
    }

    function run() public {
        vm.startBroadcast();

        vm.stopBroadcast();
    }
}
