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

        address admin = address(0xa0Ee7A142d267C1f36714E4a8F75612F20a79720);

        saddress[] memory providers = new saddress[](suint256(6));
        providers[suint256(0)] = saddress(0x90F79bf6EB2c4f870365E785982E1f101E93b906);
        providers[suint256(1)] = saddress(0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65);
        providers[suint256(2)] = saddress(0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc);
        providers[suint256(3)] = saddress(0x976EA74026E726554dB657fA54763abd0C3a0aa9);
        providers[suint256(4)] = saddress(0x14dC79964da2C08b23698B3D3cc7Ca32193d9955);
        providers[suint256(5)] = saddress(0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f);

        saddress[] memory passengers = new saddress[](suint256(8));
        passengers[suint256(0)] = saddress(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        passengers[suint256(1)] = saddress(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
        passengers[suint256(2)] = saddress(0x05A80d5FC2C4a87E88A8b455DAD98cd448d7AD87);
        passengers[suint256(3)] = saddress(0x2c7c4D021dDB8d9BF37E03CB1c107619dAE97B71);
        passengers[suint256(4)] = saddress(0xBE03C2948f2383996C3CF0b68d7d9A71a354c5e4);
        passengers[suint256(5)] = saddress(0x6bf4E6Bd789Fe11DEF9d0E680211a877f7E5b300);
        passengers[suint256(6)] = saddress(0xbb02fa0B3fFfe28851C8f56C792f73b5EfFC940e);
        passengers[suint256(7)] = saddress(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC);

        cove = new Cove(saddress(admin), passengers, providers, coveAsset);

        vm.stopBroadcast();
    }
}
