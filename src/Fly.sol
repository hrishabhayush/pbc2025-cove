// SPDX-License-Identifier: MIT License
pragma solidity ^0.8.13;

import "lib/solmate/src/utils/ReentrancyGuard.sol";

import "./SRC20.sol";

contract Fly is ReentrancyGuard {
    
    // Add some stypes here

    SRC20 public flyAsset;

    saddress adminAddress;

    // Fixed point arithmetic unit
    suint256 wad;

    saddress provider;

    struct Policy {
        suint256 flightId;
        suint256 insurancePremium;
        sbool insuranceStatus;
    } 

    saddress[] passengers;
    saddress[] providers;
    mapping(saddress => Policy) policies; // Each passenger what policy they hold

    // Corresponding to each flight we maintain a boolean, that tells us whether 
    // all the policies corresponding to that flight has been resolved
    mapping(suint256 => sbool) flightStatus;

    modifier onlyPassengers() {
        uint i = 0;
        while (suint256(i) < passengers.length) {
            require(saddress(msg.sender)==passengers[suint256(i)], "You're not one of the passengers");
            _;
        }
    }
}
