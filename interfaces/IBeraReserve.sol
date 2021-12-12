pragma solidity 0.8.10;

// SPDX-License-Identifier: GPL-3.0-only
import "solmate/tokens/ERC20.sol";

interface IBeraReserve {
    function depositBera() external payable;
    function withdrawBera(uint256 _amount) external;
    function depositToken(ERC20 token, uint256 _amount) external;
    function balanceOfToken(ERC20 token) external view returns (uint256);
    function withdrawToken(ERC20 token, address to, uint256 amount) external;
    function burnToken(ERC20 token, uint256 _amount) external;
}