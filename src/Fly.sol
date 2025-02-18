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
        suint256 flightPrice;
    } 

    saddress[] passengers;
    saddress[] providers;
    mapping(saddress => Policy) policies; // Each passenger what policy they hold

    // Corresponding to each flight we maintain a boolean, that tells us whether 
    // all the policies corresponding to that flight has been resolved
    mapping(suint256 => sbool) flightStatus;

    modifier onlyPassenger() {
        sbool isPassenger;
        for (uint i = 0; suint(i) < passengers.length; i++) {
            if (saddress(msg.sender)==passengers[i]) {
                isPassenger = sbool(true);
                break;
            }
            require(isPassenger, "You're not one of the passengers");
            _;
        }
    }

    modifier onlyAdmin() {
        require(saddress(msg.sender)==adminAddress, "You are not the admin");
        _;
    }

    modifier onlyProviders() {
        sbool isProvider;
        for (uint i = 0; suint(i) < providers.length; i++) {
            if (saddress(msg.sender)==providers[i]) {
                isProvider = sbool(true);
                break;
            }
            require(isProvider, "You're not one of the providers");
            _;
        }
    }

    constructor(saddress _adminAddress, saddress[] memory _passengers, saddress[] memory _providers) {
        adminAddress = _adminAddress;
        passengers = _passengers;
        _providers = _providers;
    }

    function setPremium(suint256 id, suint256 fee, sbool status) external onlyPassenger {
        policies[saddress(msg.sender)].flightId = id;
        policies[saddress(msg.sender)].insurancePremium = fee;
    }
 }
