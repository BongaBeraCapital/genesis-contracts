/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;


/**
 * @title BeraTemplate
 * @author 0xrebased @ Bonga Bera Capital: https://github.com/BongaBeraCapital
 * @notice Welcome to the Bera Gang!
 */
contract BeraTemplate {
    uint256 x = 10;
    uint256 y = 7;

    function hello_world() public returns (uint256) {
        y +=1;
        return 6;
    }

    function view_test() public view returns (uint256) {
        return y;
    }
}
