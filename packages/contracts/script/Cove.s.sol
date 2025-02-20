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
        saddress[] memory passengers = new saddress[](suint256(1));
        passengers[suint256(0)] = saddress(0x456);
        saddress[] memory providers = new saddress[](suint256(1));
        providers[suint256(0)] = saddress(0x789);

        cove = new Cove(admin, passengers, providers, coveAsset);

        vm.stopBroadcast();
    }
}
