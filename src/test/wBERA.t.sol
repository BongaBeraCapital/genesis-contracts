pragma solidity 0.8.4;
// SPDX-License-Identifier: GPL-3.0-only
import "../tokens/wBERA.sol";
import "ds-test/test.sol";


contract wBERATest is DSTest {
    wBERA wbera;
    function setUp() public {
        wbera = new wBERA();
    }

    function testWrapUnwrap(uint256 input) public {
        uint256 temp = payable(this).balance;
        if (input > 10 ** 60)
            return
        assertEq(wbera.balanceOf(address(this)), 0);
        wbera.deposit{value : input}();
        assertEq(wbera.balanceOf(address(this)), input);
        assertEq(payable(this).balance, temp - input);
        wbera.withdraw(input);
        assertEq(wbera.balanceOf(address(this)), 0);
        assertEq(payable(this).balance, temp);
    }

    receive() payable external {}
}