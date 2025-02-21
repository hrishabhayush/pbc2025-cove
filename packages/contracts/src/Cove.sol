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
        suint256 flightId;
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
     * Provider creates a policy and then updates the global policies and the flight policies. 
     */
    function createPolicy(suint256 policyId, suint256 flightId, suint256 premium, suint256 coverage)
        external
        onlyProvider
    {
        Policy memory policy = Policy(flightId, premium, coverage, saddress(msg.sender), saddress(0), sbool(true), sbool(false));

        policies[policyId] = policy;

        _addToFlightPolicies(policies, flightId, policyId, premium);
    
        coveAsset.transferFrom(saddress(msg.sender), saddress(this), coverage); // Store this in the contract
    }

    /*//////////////////////////////////////////////////////////////
                            PASSENGER
    //////////////////////////////////////////////////////////////*/

    function buyPolicy(suint256 flightId) external onlyPassenger nonReentrant {
        require(flightPolicies[flightId].length > suint256(0), "No policies available for this flight");

        suint256 policyId = flightPolicies[flightId][flightPolicies[flightId].length - suint256(1)];

        flightPolicies[flightId].pop();

        Policy storage policy = policies[policyId];

        require(policy.isActive, "Policy is not active");
        require(!policy.isPurchased, "Policy is already purchased");

        // Transfer premium from passenger to contract
        coveAsset.transferFrom(saddress(msg.sender), saddress(address(this)), policy.premium);

        policy.buyer = saddress(msg.sender); // Need to update the buyer

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
        flightPolicies[flightId].push(policyId);

        // Now quick sort the elements
        quickSort(flightPolicies[flightId], suint256(0), flightPolicies[flightId].length);
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

            if (midPremium > newPremium) {
                left = mid + 1;
            } else {
                right = mid;
            }
        }
        return left;
    }
    /*
     * Removes a flightPolicy from the flightPolicies.
     */
    function _removeFromFlightPolicies(suint256 flightId, suint256 policyId) internal {
        // Get the policies corresponding to a flightId
        suint256[] storage policyList  = flightPolicies[flightId];
        suint256 length = policyList.length;

        for (uint256 i = 0; suint256(i) < length; i++) {
            if (policyList[suint256(i)] == policyId) {
                if (suint256(i) < length - suint256(1)) {
                    policyList[suint256(i)] = policyList[length - suint256(1)];
                }
                policyList.pop();
                return;
            }
        }
    }
    
    /*
     * Gets a policy corresponding to a policyId
     */
    function getPolicy(uint256 policyId)
        external
        view
        returns (uint256 premium, uint256 coverage, address provider, address buyer, bool isActive, bool isPurchased)
    {
        Policy storage policyList = policies[suint256(policyId)];
        return (
            uint256(policyList.premium),
            uint256(policyList.coverage),
            address(policyList.provider),
            address(policyList.buyer),
            bool(policyList.isActive),
            bool(policyList.isPurchased)
        );
    }

    function quickSort(suint256[] storage arr, suint256 left, suint256 right) internal {
        if (left >= right) return;

        suint256 pivotIndex = left + (right - left) / suint256(2);
        suint256 pivotId = arr[pivotIndex];
        suint256 pivotPremium = policies[pivotId].premium;

        suint256 i = left;
        suint256 j = right;

        while (i <= j) {
            while (policies[arr[i]].premium > pivotPremium) {
                i++;
            }
            while (policies[arr[j]].premium < pivotPremium) {
                j--;
            }

            if (i <= j) {
                (arr[i], arr[j]) = (arr[j], arr[i]);
                i++;
                if (j > suint256(0)) j--;
            }
        }

        quickSort(arr, left, j);
        quickSort(arr, i, right);
    }
}
