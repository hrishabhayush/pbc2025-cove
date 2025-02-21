// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {Cove} from "../src/Cove.sol";
import {CoveCoin} from "../src/CoveCoin.sol";

contract CoveTest is Test {
    //     /*//////////////////////////////////////////////////////////////
    //                             CONTRACT STORAGE
    //     //////////////////////////////////////////////////////////////*/
    Cove public cove;
    CoveCoin coveAsset;

    /*//////////////////////////////////////////////////////////////
                            ADDRESSES
    //////////////////////////////////////////////////////////////*/
    address constant ADMIN = address(0x111);
    address constant PROVIDER = address(0x222);
    address constant PASSENGER = address(0x333);

    suint256 POLICY_ID = suint256(1);
    suint256 FLIGHT_ID = suint256(100);

    /*//////////////////////////////////////////////////////////////
                            SETUP
    //////////////////////////////////////////////////////////////*/
    function setUp() public {
        address[] memory passengers = new address[](1);
        passengers[0] = PASSENGER;
        address[] memory providers = new address[](1);
        providers[0] = PROVIDER;

        coveAsset = new CoveCoin(address(this), "Cove Coin", "COVE", 18);

        cove = new Cove(saddress(ADMIN), passengers, providers, coveAsset);

        // Fund provider with coverage
        coveAsset.mint(saddress(PROVIDER), suint256(1e18));
        coveAsset.mint(saddress(PASSENGER), suint256(1e18));
    }

    /*//////////////////////////////////////////////////////////////
                            HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function setupPolicyPurchase() internal {
        // Provider creates policy
        vm.startPrank(PROVIDER);
        cove.createPolicy(suint256(POLICY_ID), suint256(FLIGHT_ID), suint256(1 ether), suint256(10 ether));
        vm.stopPrank();

        // Passenger buys policy
        vm.startPrank(PASSENGER);
        coveAsset.approve(saddress(address(cove)), suint256(1 ether));
        cove.buyPolicy(suint256(FLIGHT_ID));
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                            TEST CASES
    //////////////////////////////////////////////////////////////*/
    function test_PolicyPurchaseFlow() public {
        setupPolicyPurchase();

        // Verify policy state
        (,,, address buyer,, bool isPurchased) = cove.getPolicy(uint256(POLICY_ID));
        assertEq(buyer, PASSENGER);
        assertEq(isPurchased, true);
    }

    //     function test_FlightCancelledPayout() public {
    //         setupPolicyPurchase();  // Use helper instead of test function

    //         vm.startPrank(ADMIN);
    //         cove.resolvePolicy(suint256(FLIGHT_ID), sbool(true));
    //         vm.stopPrank();

    //         vm.startPrank(PASSENGER);
    //         cove.claimPayout(suint256(POLICY_ID));
    //         vm.stopPrank();

    //         (bool success, uint256 balance) = coveAsset.safeBalanceOf(saddress(PASSENGER));
    //         assertTrue(success);
    //         assertEq(balance, 100 ether - 1 ether + 10 ether);
    //     }

    //     function test_FlightOnTimeCoverage() public {
    //         setupPolicyPurchase();  // Use helper instead of test function

    //         vm.startPrank(ADMIN);
    //         cove.resolvePolicy(suint256(FLIGHT_ID), sbool(false));
    //         vm.stopPrank();

    //         vm.startPrank(PROVIDER);
    //         cove.claimCoverageBack(suint256(POLICY_ID));
    //         vm.stopPrank();

    //         (bool success, uint256 balance) = coveAsset.safeBalanceOf(saddress(PROVIDER));
    //         assertTrue(success);
    //         assertEq(balance, 1000 ether - 10 ether + 1 ether);
    //     }
}
