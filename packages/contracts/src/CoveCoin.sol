// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import {ISRC20, SRC20} from "../src/SRC20.sol";

/*//////////////////////////////////////////////////////////////
//                      IViolinCoin Interface
//////////////////////////////////////////////////////////////*/

// ICoveCoin extends ISRC20 by adding the mint function.
interface ICoveCoin is ISRC20 {
    function mint(saddress to, suint256 amount) external;
}
/*//////////////////////////////////////////////////////////////
//                        ViolinCoin Contract
//////////////////////////////////////////////////////////////*/

contract CoveCoin is SRC20, ICoveCoin {
    address public owner;

    constructor(address _owner, string memory _name, string memory _symbol, uint8 _decimals)
        SRC20(_name, _symbol, _decimals)
    {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Must be owner");
        _;
    }

    /// @notice Mints new tokens to the specified address.
    function mint(saddress to, suint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /// @notice Returns the balance of msg.sender.
    function balanceOf() public view override(ISRC20, SRC20) returns (uint256) {
        return super.balanceOf();
    }

    /// @notice Transfers tokens to another address.
    function transfer(saddress to, suint256 amount) public override(ISRC20, SRC20) returns (bool) {
        return super.transfer(to, amount);
    }

    /// @notice Transfers tokens from one address to another.
    function transferFrom(saddress from, saddress to, suint256 amount) public override(ISRC20, SRC20) returns (bool) {
        return super.transferFrom(from, to, amount);
    }
}
