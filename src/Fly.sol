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

    /*
     * Flight insurance policy
     */
    struct Policy {
        suint256 flightId;
        suint256 insurancePremium;
        sbool insuranceStatus;
        suint256 flightPrice;
    }

    
    saddress[] passengers;
    // Providers are insurers that will be insuring the passengers
    saddress[] providers;
    
    // Mapping for each passenger and provider to the policy they hold
    mapping(saddress => Policy) policyHolder;

    // Policies that are confirmed by the user and they have already bought
    Policy[] policiesConfirmed;

    // Policies that are yet to be bought the passengers
    Policy[] policyToDisplay;

    // Corresponding to each flight we maintain a boolean, that tells us whether
    // all the policies corresponding to that flight has been resolved
    mapping(suint256 => sbool) flightStatus;

    /*
     * Modifier to allow function calls by only passengers. 
     */ 
    modifier onlyPassengers() {
        sbool isPassenger;
        for (uint256 i = 0; suint(i) < passengers.length; i++) {
            if (saddress(msg.sender) == passengers[suint256(i)]) {
                isPassenger = sbool(true);
                break;
            }
            require(isPassenger, "You're not one of the passengers");
            _;
        }
    }

    /*
     * Modifier to allow access by the admin. 
     */ 
    modifier onlyAdmin() {
        require(saddress(msg.sender) == adminAddress, "You are not the admin");
        _;
    }

    /* 
     * Modifier to allow function calls by only providers/insurers. 
     */
    modifier onlyProviders() {
        sbool isProvider;
        for (uint256 i = 0; suint(i) < providers.length; i++) {
            if (saddress(msg.sender) == providers[suint256(i)]) {
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

    /* 
     * Providers are allowed to set the premium fee for policy. 
     */
    function setPremium(suint256 id, suint256 fee) external onlyProviders {
        policyHolder[saddress(msg.sender)].flightId = id;
        policyHolder[saddress(msg.sender)].insurancePremium = fee;
        policyToDisplay.push(policyHolder[saddress(msg.sender)]);
    }

    /*
     * Only passengers are allowed to buy the policy. 
     */
    function buyPolicy(suint256 flightId) external payable onlyPassengers nonReentrant {
        require(
            suint256(msg.value) == policyHolder[saddress(msg.sender)].insurancePremium, "Insurance premium fee mismatch"
        );
        policyHolder[saddress(msg.sender)].flightId = flightId;
        policyHolder[saddress(msg.sender)].insuranceStatus = sbool(true);
        policiesConfirmed.push(policyHolder[saddress(msg.sender)]);
    }

    /*
     * The policy with th least premium fee is listed to the passengers. 
     */
    function listPolicy() external onlyPassengers returns(Policy memory policy) {
        if (policyToDisplay.length > suint256(0)) {
            
            suint256 leastPremium = policyToDisplay[suint256(0)].insurancePremium;
            suint256 index;
            policy = policyToDisplay[suint256(0)];
            for (uint i = 1; suint256(i) < policyToDisplay.length; i++) {
                if (policyToDisplay[suint256(i)].insurancePremium <= leastPremium) {
                    leastPremium = policyToDisplay[suint256(i)].insurancePremium;
                    policy = policyToDisplay[suint256(i)];
                    index = suint(i);
                }
            }
            
            Policy memory temp = policyToDisplay[policyToDisplay.length - suint(1)];
            temp = policyToDisplay[suint256(index)];
            policyToDisplay[suint256(index)] = temp;
            policyToDisplay.pop();

        } else {
            revert("No policies to display");
        }
    } 
}
