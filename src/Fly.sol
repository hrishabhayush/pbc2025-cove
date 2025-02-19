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

    // Maintain a policy id counter
    suint256 nextPolicyId;

    /*
     * Flight insurance policy provided by an insurer/provider. 
     */
    struct Policy {
        suint256 premium;
        suint256 coverage;
        saddress provider;
        saddress buyer;
        sbool isActive;
        sbool isPurchased;
    }

    // With a mapping ensure whether an address is passenger or not
    mapping(saddress => sbool) isPassenger;
    // With a mapping ensure whether an address is provider or not
    mapping(saddress => sbool) isProvider;

    // Mapping unique policy id to the respective policy
    mapping(suint256 => Policy) policies;

    // Map flightId to each corresponding policy with the same flightId
    mapping(suint256 => suint256[]) flightPolicies;

    // Map each provider to their created policies
    mapping(saddress => suint256[]) providerPolicies;
    
    // Map each passenger to their purchased policies
    mapping(saddress => suint256[]) passengerPolicies; 

    // To check if each flight id resolved
    mapping(suint256 => sbool) flightResolutions;

    /*
     * Modifier to allow function call by only passenger. 
     */
    modifier onlyPassenger() {
        require(isPassenger[saddress(msg.sender)], "Not a passenger");
        _;
    }

    /*
     * Modifier to allow access by the admin. 
     */
    modifier onlyAdmin() {
        require(saddress(msg.sender) == adminAddress, "You are not the admin");
        _;
    }

    /* 
     * Modifier to allow function calls by only provider/insurer. 
     */
    modifier onlyProvider() {
        require(isProvider[saddress(msg.sender)], "Not a provider");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(
        saddress _adminAddress, 
        saddress[] memory _passengers, 
        saddress[] memory _providers, 
        SRC20 _flyAsset) {
        adminAddress = _adminAddress;
        for (uint256 i = 0; suint256(i) < _passengers.length; i++) {
            isPassenger[_passengers[suint256(i)]] = sbool(true);
        }

        for (uint256 i = 0; suint256(i) < _providers.length; i++) {
            isProvider[_providers[suint256(i)]] = sbool(true);
        }

        flyAsset = _flyAsset;
    }

    /*//////////////////////////////////////////////////////////////
                            PROVIDER
    //////////////////////////////////////////////////////////////*/
    /*
     * Provider creates a policy.
     */
    function createPolicy(suint256 policyId,
        suint256 flightId,
        suint256 premium,
        suint256 coverage
    ) external onlyProvider {
        Policy memory policy = Policy(
            premium, 
            coverage, 
            saddress(msg.sender),
            saddress(0),
            sbool(false),
            sbool(false)
        );

        policies[policyId] = policy;

        _addToFlightPolicies(policies, flightId, policyId, premium);        
    }
    
    /* 
     * Providers are allowed to set the premium fee for policy. 
     */
    function updatePremium(suint256 policyId, suint256 flightId, suint256 newPremium) external onlyProvider {
        Policy storage policy = policies[policyId];

        require(policy.provider == saddress(msg.sender), "Not your policy");
        require(!policy.isPurchased, "Policy already purchased");
        
        uint index = 0;
        for (uint i = 0; suint(i) < flightPolicies[flightId].length; i++) {
            if (flightPolicies[flightId][suint256(i)] == policyId) {
                index = i;
                break;
            }
        }

        for (uint i = index; suint(i + 1) < flightPolicies[flightId].length; i++) {
            flightPolicies[flightId][suint256(i)] = flightPolicies[flightId][suint256(i+1)];
            flightPolicies[flightId].pop();
            _binaryInsertionSort(policies, flightPolicies[flightId], newPremium);
        }
    }
    
    /*//////////////////////////////////////////////////////////////
                            PASSENGER
    //////////////////////////////////////////////////////////////*/
    // function getCheapestPolicy(suint256 flightId) private view returns(suint256) {
    //     suint256[] storage policies = flightPolicies[flightId];
    //     require(policies.length > suint256(0), "No policies available");
        
    //     suint256 cheapestId = policies[suint256(0)];
    //     suint256 lowestPremium = policies[cheapestId].premium;

    //     for (uint256 i = 1; suint256(i) < policies.length; i++) {
    //         Policy storage current = policies[policies[suint256(i)]];
    //         if (sbool(current.premium < lowestPremium) && !current.isPurchased) {
    //             cheapestId = policies[suint256(i)];
    //             lowestPremium = current.premium;
    //         }
    //     }
    //     return cheapestId;
    // }
    
    // function buyPolicy(suint256 flightId) external onlyPassenger nonReentrant {
    //     suint256 policyId = getCheapestPolicy(flightId);

    //     Policy storage policy = policies[policyId];
    //     require(policy.isActive, "Policy is not active");
    //     require(!policy.isPurchased, "Policy is already purchased");

    //     // Transfer premium from passenger to contract
    //     flyAsset.transferFrom(saddress(msg.sender), saddress(address(this)), policy.premium);
        
    //     // Mark policy as purchased
    //     policy.isPurchased = sbool(true);
    //     passengerPolicies[saddress(msg.sender)].push(policyId);
    //     _removeFromFlightPolicies(flightId, policyId);
    // }

    /*
     * Helper functions
     */
    function _addToFlightPolicies (
        mapping (suint256 => Policy) storage globalPolicies,
        suint256 flightId, 
        suint256 policyId, 
        suint256 premium
        ) internal {
        flightPolicies[flightId].push(policyId);
        suint256 pos = _binaryInsertionSort(globalPolicies, flightPolicies[flightId], premium);
        flightPolicies[flightId].push(suint256(0));
        for (uint256 i = uint256(flightPolicies[flightId].length) - 1; suint256(i) >= pos; i--) {
            flightPolicies[suint256(i+1)] = flightPolicies[suint256(i)];
        }
        flightPolicies[pos] = flightPolicies[policyId];
    }

    /*
     * Removes .
     */
    // function _removeFromFlightPolicies(suint256 flightId, suint256 policyId) internal {
    //     // Get the policies corresponding to a flightId
    //     suint256[] storage policies = flightPolicies[flightId];
    //     for (uint256 i = 0; suint256(i) < policies.length; i++) {
    //         if (policies[suint256(i)] == policyId) {
    //             policies[suint256(i)] = policies[suint256(policies.length - suint256(1))];
    //             policies.pop();
    //             break;
    //         }
    //     }
    //     _sortFlightPolicies(flightId);
    // }

    /*
     * Sorts the flightPolicies array in descending order.
     */
    function _binaryInsertionSort(
        mapping (suint256 => Policy) storage globalPolicies, 
        suint256[] storage list, 
        suint256 premium
        ) internal view returns(suint256) {
        suint256 left = list.length - suint256(1);
        suint256 right;
        
        while (globalPolicies[left].premium > globalPolicies[right].premium) {
            suint256 mid = right + (left - right) / suint256(2);

            if (globalPolicies[mid].premium < premium) {
                right = mid;
            } else {
                left = mid + suint256(1);
            }
        }
        return left;
    }

    /*
     * Check if the first quantity is lesser than the second quantity
     */ 
    function _isLessExpensive(suint256 a, suint256 b) internal view returns (sbool) {
        return sbool(policies[a].premium < policies[b].premium);
    }
}