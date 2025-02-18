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
        suint256 policyId;
        suint256 flightId;
        suint256 premium;
        suint256 coverage;
        saddress provider;
        sbool isActive;
        sbool isPurchased;
    }

    // With a mapping ensure whether an address is passenger or not
    mapping(saddress => sbool) isPassenger;
    // With a mapping ensure whether an address is provider or not
    mapping(saddress => sbool) isProvider;

    // Mapping each policy id to their policies
    mapping(suint256 => Policy) allPolicies;

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
    function createPolicy(suint256 flightId,
        suint256 premium,
        suint256 coverage
    ) external onlyProvider {
        nextPolicyId += suint(1);

        allPolicies[nextPolicyId] = Policy(
            nextPolicyId, 
            flightId,
            premium,
            coverage,
            saddress(msg.sender),
            sbool(true),
            sbool(false)
        );

        providerPolicies[saddress(msg.sender)].push(nextPolicyId);
        _addToFlightPolicies(flightId, nextPolicyId);

    }
    /* 
     * Providers are allowed to set the premium fee for policy. 
     */
    function updatePremium(suint256 policyId, suint256 newPremium) external onlyProvider {
        Policy storage policy = allPolicies[policyId];
        require(policy.provider == saddress(msg.sender), "Not your policy");
        require(!policy.isPurchased, "Policy already purchased");
        
        policy.premium = newPremium;
        _sortFlightPolicies(policy.flightId);
    }
    
    /*//////////////////////////////////////////////////////////////
                            PASSENGER
    //////////////////////////////////////////////////////////////*/
    function getCheapestPolicy(suint256 flightId) private view returns(suint256) {
        suint256[] storage policies = flightPolicies[flightId];
        require(policies.length > suint256(0), "No policies available");
        
        suint256 cheapestId = policies[suint256(0)];
        suint256 lowestPremium = allPolicies[cheapestId].premium;

        for (uint256 i = 1; suint256(i) < policies.length; i++) {
            Policy storage current = allPolicies[policies[suint256(i)]];
            if (sbool(current.premium < lowestPremium) && !current.isPurchased) {
                cheapestId = policies[suint256(i)];
                lowestPremium = current.premium;
            }
        }
        return cheapestId;
    }
    
    function buyPolicy(suint256 flightId) external onlyPassenger nonReentrant {
        suint256 policyId = getCheapestPolicy(flightId);

        Policy storage policy = allPolicies[policyId];
        require(policy.isActive, "Policy is not active");
        require(!policy.isPurchased, "Policy is already purchased");

        // Transfer premium from passenger to contract
        flyAsset.transferFrom(saddress(msg.sender), saddress(address(this)), policy.premium);
        
        // Mark policy as purchased
        policy.isPurchased = sbool(true);
        passengerPolicies[saddress(msg.sender)].push(policyId);
        _removeFromFlightPolicies(flightId, policyId);
    }

    /*
     * Helper functions
     */
    function _addToFlightPolicies(suint256 flightId, suint256 policyId) internal {
        flightPolicies[flightId].push(policyId);
        _sortFlightPolicies(flightId);
    }

    function _removeFromFlightPolicies(suint256 flightId, suint256 policyId) internal {
        suint256[] storage policies = flightPolicies[flightId];
        for (uint256 i = 0; suint256(i) < policies.length; i++) {
            if (policies[suint256(i)] == policyId) {
                policies[suint256(i)] = policies[suint256(policies.length - suint256(1))];
                policies.pop();
                break;
            }
        }
        _sortFlightPolicies(flightId);
    }

    function _sortFlightPolicies(suint256 flightId) internal {
        suint256[] storage policies = flightPolicies[flightId];
        for (uint256 i = 1; suint256(i) < policies.length; i++) {
            uint256 j = i;
            while (sbool(j > 0) && _isLessExpensive(policies[suint256(j)], policies[suint256(j-1)])) {
                (policies[suint256(j-1)], policies[suint256(j)]) = (policies[suint256(j)], policies[suint256(j-1)]);
                j--;
            }
        }
    }

    function _isLessExpensive(suint256 a, suint256 b) internal view returns (sbool) {
        return sbool(allPolicies[a].premium < allPolicies[b].premium);
    }
}
