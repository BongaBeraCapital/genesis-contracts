pragma solidity 0.8.10;
// SPDX-License-Identifier: AGPL-3.0-only

/* Package Imports */
import {ERC20} from "bera-solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "bera-solmate/utils/SafeTransferLib.sol";

contract sBERA is ERC20("Staked BERA", "sBERA", 18) {
    address private immutable validatorAuthority;

    constructor(address _validatorAuthority) {
        validatorAuthority = _validatorAuthority;
    }

    function mint(address user, uint256 amount) external {
        require(msg.sender == validatorAuthority, "sBERA: Only Validator");
        _mint(user, amount);
    }

    function burn(address user, uint256 amount) external {
        require(msg.sender == validatorAuthority, "sBERA: Only Validator");
        _burn(user, amount);
    }
}
