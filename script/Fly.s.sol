// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;

// import {Script, console} from "lib/forge-std/src/Script.sol";
// import {Fly} from "../src/Fly.sol";

// contract FlyScript is Script {
//     Fly public fly;

//     function setUp() public {
//         saddress admin = saddress(0x14dC79964da2C08b23698B3D3cc7Ca32193d9955);

//         saddress[] memory passengers = new address[](1);
//         passengers[suint256(0)] = saddress(0x456);

//         saddress[] memory providers = new address[](1);
//         providers[suint256(0)] = saddress(0x789);

//         suint256 constant WAD = 1e18;

//         fly = new Fly(adminAddress, passengers, providers, );
//     }

//     function run() public {
//         vm.startBroadcast();

//         vm.stopBroadcast();
//     }
// }
