// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.10;
/* Package Imports */
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {SafeTransferLib} from "bera-solmate/utils/SafeTransferLib.sol";

contract BeraValidatorDelegation {
    IERC20 immutable sBERA;

    // Events
    event Cosmos__DelegateTo(address validator, uint256 amount);
    event Cosmos__UndelegateFrom(address validator, uint256 amount);

    constructor(address _sBERA) {
        sBERA = IERC20(_sBERA);
    }

    function delegateTo(address validator, uint256 amount) external {
        // Minting sBERA to the user occurs in the Cosmos Code.
        emit Cosmos__DelegateTo(validator, amount);
    }

    function undelegateFrom(address validator, uint256 amount) external {
        // Burning sBERA from the user occurs in the Cosmos Code.
        emit Cosmos__UndelegateFrom(validator, amount);
    }
}
