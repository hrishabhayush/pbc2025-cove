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

    struct Policy {
        saddress passenger;
        suint256 flightId;
        suint256 insurancePremium;
        suint256 payout;
        sbool insuranceStatus;
    } 

    mapping(suint256 => Policy) policies;
    mapping(saddress => suint256) insurerBalances;
    mapping(suint256 => sbool) flightStatus;

    
    constructor(Policy policy) {

    }



    constructor() {

    }
}
