/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/* Package Imports */
import {u60x18, u60x18_t} from "@bonga-bera-capital/bera-utils/contracts/Math.sol";
import {TypeSwaps} from "@bonga-bera-capital/bera-utils/contracts/TypeSwaps.sol";

/**
 * @title BeraTemplate
 * @author 0xrebased @ Bonga Bera Capital: https://github.com/BongaBeraCapital
 * @notice Welcome to the Bera Gang!
 */
contract BeraTemplate {
    using TypeSwaps for uint256;
    using TypeSwaps for u60x18_t;
    using u60x18 for u60x18_t;
}
