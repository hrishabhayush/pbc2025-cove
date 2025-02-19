// // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {Cove} from "../src/Cove.sol";
import {CoveCoin} from "../src/CoveCoin.sol";

contract CoveScript is Script {
    Cove public cove;
    CoveCoin public coveAsset;

    function setUp() public {
        address admin = address(0x14dC79964da2C08b23698B3D3cc7Ca32193d9955);

        saddress[] memory passengers = new saddress[](suint256(1));
        passengers[suint256(0)] = saddress(0x456);

        saddress[] memory providers = new saddress[](suint256(1));
        providers[suint256(0)] = saddress(0x789);

        cove = new Cove(saddress(admin), passengers, providers, coveAsset);
    }

    function run() public {
        vm.startBroadcast();

        cove.createPolicy(suint256(1), suint256(1), suint256(1e16), suint256(1e20));
        cove.createPolicy(suint256(2), suint256(2), suint256(1e17), suint256(1e18));
        cove.createPolicy(suint256(3), suint256(1), suint256(1e19), suint256(1e20));
        cove.createPolicy(suint256(4), suint256(1), suint256(1e18), suint256(1e20));
        cove.createPolicy(suint256(5), suint256(1), suint256(1e19), suint256(1e20));
        cove.createPolicy(suint256(6), suint256(1), suint256(1e17), suint256(1e20));

        vm.stopBroadcast();
    }
}
