pragma solidity >=0.8.0;
// SPDX-License-Identifier: AGPL-3.0-only

import {ERC20} from "bera-solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "bera-solmate/utils/SafeTransferLib.sol";

/// @notice Minimalist and modern Wrapped Bera implementation.
/// @author Inspired by WBERA9 (https://github.com/dapphub/ds-WBERA/blob/master/src/WBERA9.sol)
contract wBERA is ERC20("Wrapped Bera", "wBERA", 18) {
    using SafeTransferLib for address;

    //=================================================================================================================
    // Events
    //=================================================================================================================

    event Deposit(address indexed from, uint256 amount);
    event Withdrawal(address indexed to, uint256 amount);

    //=================================================================================================================
    // Functions
    //=================================================================================================================

    function deposit() public payable {
        _mint(msg.sender, msg.value);

        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        _burn(msg.sender, amount);

        msg.sender.safeTransferBERA(amount);

        emit Withdrawal(msg.sender, amount);
    }

    receive() external payable {
        deposit();
    }
}
