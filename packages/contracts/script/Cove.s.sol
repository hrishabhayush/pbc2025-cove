// // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {Cove} from "../src/Cove.sol";
import {CoveCoin} from "../src/CoveCoin.sol";

contract CoveScript is Script {
    Cove public cove;
    CoveCoin public coveAsset;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVKEY");

        vm.startBroadcast(deployerPrivateKey);

        saddress admin = saddress(0x123);
        saddress[] memory passengers = new saddress[](suint256(8));
        passengers[suint256(0)] = saddress(0x1);
        passengers[suint256(1)] = saddress(0x2);
        passengers[suint256(2)] = saddress(0x3);
        passengers[suint256(3)] = saddress(0x4);
        passengers[suint256(4)] = saddress(0x5);
        passengers[suint256(5)] = saddress(0x6);
        passengers[suint256(6)] = saddress(0x7);
        passengers[suint256(7)] = saddress(0x8);

        saddress[] memory providers = new saddress[](suint256(6));
        providers[suint256(0)] = saddress(0x11);
        providers[suint256(1)] = saddress(0x12);
        providers[suint256(2)] = saddress(0x13);
        providers[suint256(3)] = saddress(0x14);
        providers[suint256(4)] = saddress(0x15);
        providers[suint256(5)] = saddress(0x16);


        cove = new Cove(admin, passengers, providers, coveAsset);

        vm.stopBroadcast();
    }
}
