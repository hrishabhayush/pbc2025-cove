// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import {SRC20} from "./SRC20.sol";

/*//////////////////////////////////////////////////////////////
//                        CoveCoin Contract
//////////////////////////////////////////////////////////////*/

contract CoveCoin is SRC20 {
    constructor(address admin) SRC20("Cove Coin", "COVE") {
        if (admin == address(0)) revert ERC20InvalidReceiver(admin);
    }
}
