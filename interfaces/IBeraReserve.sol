pragma solidity 0.8.10;

// SPDX-License-Identifier: GPL-3.0-only
import "bera-solmate/tokens/ERC20.sol";

interface IBeraReserve {
    function depositBera() external payable;
    function withdrawBera(uint256 _amount) external;
    function depositToken(address token, uint256 _amount) external;
    function balanceOfToken(address token) external view returns (uint256);
    function withdrawToken(address token, address to, uint256 amount) external;
}