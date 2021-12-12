// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.10;

library ArrayLib {
    function sum(uint256[] calldata arr) internal pure returns (uint256) {
        uint256 i;
        uint256 _sum = 0;

        for (i = 0; i < arr.length; i++) _sum += arr[i];
        return _sum;
    }
}
