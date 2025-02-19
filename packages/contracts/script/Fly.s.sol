// // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/src/Script.sol";
import {Fly} from "../src/Fly.sol";
import {SRC20} from "../src/SRC20.sol";

contract FlyScript is Script {
    Fly public fly;
    SRC20 public flyAsset;

    function setUp() public {
        Fly public fly;
        address admin = address(0x14dC79964da2C08b23698B3D3cc7Ca32193d9955);

        address[] memory passengers = new address[](1);
        passengers[0] = address(0x456);

        address[] memory providers = new address[](1);
        providers[0] = address(0x789);

        // Deploy the SRC20 token contract
        flyAsset = new SRC20("Cove Token", "COVE", 18);

        // Deploy the Fly contract
        fly = new Fly(admin, passengers, providers, flyAsset);
    }

    function run() public {
        vm.startBroadcast();

        fly.createPolicy(suint256(1), suint256(1), suint256(1e16), suint256(1e20));
        fly.createPolicy(suint256(2), suint256(2), suint256(1e17), suint256(1e18));
        fly.createPolicy(suint256(3), suint256(1), suint256(1e19), suint256(1e20));
        fly.createPolicy(suint256(4), suint256(1), suint256(1e18), suint256(1e20));
        fly.createPolicy(suint256(5), suint256(1), suint256(1e19), suint256(1e20));
        fly.createPolicy(suint256(6), suint256(1), suint256(1e17), suint256(1e20));

        vm.stopBroadcast();
    }
}
