// SPDX-License-Identifier: MIT License
pragma solidity ^0.8.13;

import "lib/solmate/src/utils/ReentrancyGuard.sol";
import {CoveCoin} from "./CoveCoin.sol";

contract Cove is ReentrancyGuard {
    // Add some stypes here

    CoveCoin public coveAsset;

    saddress adminAddress;

    // Fixed point arithmetic unit
    suint256 wad;

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
        CoveCoin _coveAsset
    ) {
        adminAddress = _adminAddress;
        for (uint256 i = 0; suint256(i) < _passengers.length; i++) {
            isPassenger[_passengers[suint256(i)]] = sbool(true);
        }

        for (uint256 i = 0; suint256(i) < _providers.length; i++) {
            isProvider[_providers[suint256(i)]] = sbool(true);
        }

        coveAsset = _coveAsset;
    }

    /*//////////////////////////////////////////////////////////////
                            PROVIDER
    //////////////////////////////////////////////////////////////*/
    /*
     * Provider creates a policy.
     */
    function createPolicy(suint256 policyId, suint256 flightId, suint256 premium, suint256 coverage)
        external
        onlyProvider
    {
        Policy memory policy = Policy(premium, coverage, saddress(msg.sender), saddress(0), sbool(true), sbool(false));

        policies[policyId] = policy;

        coveAsset.transferFrom(saddress(msg.sender), saddress(this), coverage); // Store this in the contract

        _addToFlightPolicies(policies, flightId, policyId, premium);
    }

    /*//////////////////////////////////////////////////////////////
                            PASSENGER
    //////////////////////////////////////////////////////////////*/
    function getCheapestPolicy(suint256 flightId) private view returns (suint256) {
        require(flightPolicies[flightId].length > suint256(0), "No policies available for this flight");

        suint256 cheapestId = _binarySearchCheapestPolicy(flightId);
        return cheapestId;
    }

    function buyPolicy(suint256 flightId) external onlyPassenger nonReentrant {
        suint256 policyId = getCheapestPolicy(flightId);

        Policy storage policy = policies[policyId];
        require(policy.isActive, "Policy is not active");
        require(!policy.isPurchased, "Policy is already purchased");

        policy.buyer = saddress(msg.sender); // Need to update the buyer

        // Transfer premium from passenger to contract
        coveAsset.transferFrom(saddress(msg.sender), saddress(address(this)), policy.premium);

        // Mark policy as purchased
        policy.isPurchased = sbool(true);
        passengerPolicies[saddress(msg.sender)].push(policyId);
        _removeFromFlightPolicies(flightId, policyId);
    }

    /*//////////////////////////////////////////////////////////////
                            RESOLUTION
    //////////////////////////////////////////////////////////////*/
    /*
     * Admin resolves the policies for all the flights with the flightId
     */
    function resolvePolicy(suint256 flightId, sbool flightCancelled) external onlyAdmin {
        flightResolutions[flightId] = flightCancelled;
    }

    /*
     * Passengers can claim payout if the flight is cancelled
     */
    function claimPayout(suint256 policyId) external nonReentrant onlyPassenger {
        Policy storage policy = policies[policyId];
        require(policy.isPurchased, "Policy not purchased");
        require(flightResolutions[policyId] == sbool(true), "No payout available");

        // Coverage transferred from provider to passenger
        coveAsset.transferFrom(policy.provider, policy.buyer, policy.coverage);

        // Policy will be inactive after payout
        policy.isActive = sbool(false);
    }

    /*
     * Providers can claim back their coverage if the flight is on time
     */
    function claimCoverageBack(suint256 policyId) external nonReentrant onlyProvider {
        Policy storage policy = policies[policyId];
        require(policy.isPurchased, "Policy not purchased");
        require(flightResolutions[policyId] == sbool(false), "Flight was cancelled");

        // Coverage transferred back to provider
        coveAsset.transferFrom(saddress(this), policy.provider, policy.coverage);

        // Policy will be inactive after coverage is returned
        policy.isActive = sbool(false);
    }

    /*
     * Add the flight policy in sorted order in the flightPolicies array. 
     */
    function _addToFlightPolicies(
        mapping(suint256 => Policy) storage globalPolicies,
        suint256 flightId,
        suint256 policyId,
        suint256 premium
    ) internal {
        // Initialize array if empty
        if (flightPolicies[flightId].length == suint256(0)) {
            flightPolicies[flightId].push(policyId);
            return;
        }

        uint256 insertIndex = _findInsertPosition(globalPolicies, flightPolicies[flightId], premium);
        flightPolicies[flightId].push(suint256(0));

        // Shift elements to the right
        for (suint256 i = flightPolicies[flightId].length - suint256(1); i > suint256(insertIndex); i--) {
            flightPolicies[flightId][suint256(i)] = flightPolicies[flightId][i - suint256(1)];
        }
        
        // Insert new policy at correct position
        flightPolicies[flightId][suint256(insertIndex)] = policyId;    
    }

    /*
     * Finds the insert position for a policy as soon as it is created. 
     */
    function _findInsertPosition(
        mapping(suint256 => Policy) storage globalPolicies,
        suint256[] storage list,
        suint256 newPremium
    ) private view returns (uint256) {
        uint256 left = 0;
        uint256 right = uint256(list.length);

        while (left < right) {
            uint256 mid = left + (right - left) / 2;
            suint256 midPremium = globalPolicies[list[suint256(mid)]].premium;

            if (midPremium < newPremium) {
                right = mid;
            } else {
                left = mid + 1;
            }
        }
        return left;
    }
    /*
     * Removes a flightPolicy from the flightPolicies.
     */
    function _removeFromFlightPolicies(suint256 flightId, suint256 policyId) internal {
        // Get the policies corresponding to a flightId
        uint256 index = 0;
        for (uint256 i = 0; suint256(i) < flightPolicies[flightId].length; i++) {
            if (flightPolicies[flightId][suint256(i)] == policyId) {
                index = i;
                break;
            }
        }

        // Remove the policy from the flightPolicies array
        for (uint256 i = index; suint256(i) < flightPolicies[flightId].length - suint256(1); i++) {
            flightPolicies[flightId][suint256(i)] = flightPolicies[flightId][suint256(i + 1)];
        }
        flightPolicies[flightId].pop();
    }

    // This needs to be off-chain
    /*
     * Binary search to find the cheapest policy that is available in the flightPolicies. 
     */
    // function _binarySearchCheapestPolicy(suint256 flightId) private view returns (suint256) {
    //     suint256[] storage policyList = flightPolicies[flightId];
    //     require(policyList.length > suint256(0), "No policies available for this flight");

    //     uint256 left;
    //     uint256 right = uint256(policyList.length) - 1;
    //     suint256 cheapestAvailable = policyList[suint256(right)];
    //     bool found = false;

    //     while (left <= right) {
    //         uint256 mid = left + (right - left) / 2;
    //         suint256 midPolicyId = policyList[suint256(mid)];
    //         Policy storage currentPolicy = policies[midPolicyId];

    //         if (!currentPolicy.isPurchased && currentPolicy.isActive) {
               
    //             // Move left to find earlier (cheaper) available policies
    //             cheapestAvailable = midPolicyId;
    //             found = true;
    //             right = mid - 1;
    //         } else {
    //             left = mid + 1;
    //         }
    //     }
    //     require(found, "No available policies");
    //     return cheapestAvailable;
    // }
    function _binarySearchCheapestPolicy(suint256 flightId) private view returns (suint256) {
        suint256[] storage policyList = flightPolicies[flightId];
        require(policyList.length > suint256(0), "No policies available for this flight");

        // Search from the end (cheapest) towards start
        for (suint256 i = policyList.length; i > suint256(0); i--) {
            suint256 policyId = policyList[i - suint256(1)];
            Policy storage policy = policies[policyId];
            
            if (policy.isActive && !policy.isPurchased) {
                return policyId;
            }
        }
        
        revert("No available policies");
    }

    function getPolicy(uint256 policyId)
        external
        view
        returns (uint256 premium, uint256 coverage, address provider, address buyer, bool isActive, bool isPurchased)
    {
        Policy storage policy = policies[suint256(policyId)];
        return (
            uint256(policy.premium),
            uint256(policy.coverage),
            address(policy.provider),
            address(policy.buyer),
            bool(policy.isActive),
            bool(policy.isPurchased)
        );
    }
}
