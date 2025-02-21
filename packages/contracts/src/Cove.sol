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

    /* 
     * Providers are allowed to set the premium fee for policy. 
     */
    function updatePremium(suint256 policyId, suint256 flightId, suint256 newPremium) external onlyProvider {
        Policy storage policy = policies[policyId];

        require(policy.provider == saddress(msg.sender), "Not your policy");
        require(!policy.isPurchased, "Policy already purchased");

        uint256 index = 0;
        for (uint256 i = 0; suint(i) < flightPolicies[flightId].length; i++) {
            if (flightPolicies[flightId][suint256(i)] == policyId) {
                index = i;
                break;
            }
        }

        for (uint256 i = index; suint(i + 1) < flightPolicies[flightId].length; i++) {
            flightPolicies[flightId][suint256(i)] = flightPolicies[flightId][suint256(i + 1)];
            flightPolicies[flightId].pop();
            _binaryInsertionSort(policies, flightPolicies[flightId], newPremium);
        }
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
        flightPolicies[flightId].push(policyId);
        suint256 pos = _binaryInsertionSort(globalPolicies, flightPolicies[flightId], premium);
        flightPolicies[flightId].push(suint256(0));
        for (uint256 i = uint256(flightPolicies[flightId].length) - 1; suint256(i) >= pos; i--) {
            flightPolicies[suint256(i + 1)] = flightPolicies[suint256(i)];
        }
        flightPolicies[pos] = flightPolicies[policyId];
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

    /*
     * Sorts the flightPolicies array in descending order and inserts the policy to preserve that
     * descending order.
     */
    function _binaryInsertionSort(
        mapping(suint256 => Policy) storage globalPolicies,
        suint256[] storage list,
        suint256 premium
    ) internal view returns (suint256) {
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

    // This needs to be off-chain
    /*
     * Binary search to find the cheapest policy that is available in the flightPolicies. 
     */
    function _binarySearchCheapestPolicy(suint256 flightId) private view returns (suint256) {
        suint256 left;
        suint256 right = flightPolicies[flightId].length - suint256(1);
        suint256 cheapestId = flightPolicies[flightId][left];
        suint256 lowestPremium = policies[cheapestId].premium;

        while (left <= right) {
            suint256 mid = left + (right - left) / suint256(2);
            suint256 currentPolicyId = flightPolicies[flightId][mid];
            Policy storage currentPolicy = policies[currentPolicyId];

            if (!currentPolicy.isPurchased && sbool(currentPolicy.premium < lowestPremium)) {
                cheapestId = currentPolicyId;
                lowestPremium = currentPolicy.premium;
            }

            if (currentPolicy.premium < lowestPremium) {
                right = mid - suint256(1);
            } else {
                left = mid + suint256(1);
            }
        }

        return cheapestId;
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
