pragma solidity 0.8.10;
// SPDX-License-Identifier: GPL-3.0-only

/* Local Imports */
import {BeraMixin} from "../mixins/BeraMixin.sol";
import {IBeraReserve} from "../../interfaces/IBeraReserve.sol";
import {IBeraStorage} from "../../interfaces/IBeraStorage.sol";

/* Package Imports */
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract BeraReserve is BeraMixin, IBeraReserve {
    using SafeTransferLib for ERC20;
    using SafeTransferLib for address;

    event BeraDeposited(address indexed by, uint256 amount, uint256 time);
    event BeraWithdrawn(address indexed by, uint256 amount, uint256 time);
    event TokenDeposited(address indexed by, address indexed tokenAddress, uint256 amount, uint256 time);
    event TokenWithdrawn(address indexed by, address indexed tokenAddress, uint256 amount, uint256 time);
    event TokenBurned(address indexed by, address indexed tokenAddress, uint256 amount, uint256 time);
    event TokenTransfer(
        address indexed by,
        bytes32 indexed to,
        address indexed tokenAddress,
        uint256 amount,
        uint256 time
    );

    constructor(address _storageAddress) BeraMixin(_storageAddress) {
        version = 1;
    }

    function balanceOfToken(address token) external view override returns (uint256) {
        return ERC20(token).balanceOf(address(this));
    }

    function depositBera() external payable override {
        require(msg.value > 0, "No valid amount of BERA given to deposit");
        emit BeraDeposited(msg.sender, msg.value, block.timestamp);
    }

    function depositToken(address token, uint256 amount) external override {
        require(amount > 0, "No valid amount of tokens given to deposit");
        require(ERC20(token).transferFrom(msg.sender, address(this), amount), "Token transfer was not successful");
        emit TokenDeposited(msg.sender, address(token), amount, block.timestamp);
    }

    function withdrawBera(uint256 amount) external override onlyRegisteredContracts {
        require(amount > 0, "No valid amount of BERA given to withdraw");
        (msg.sender).safeTransferETH(amount);
        emit BeraWithdrawn(msg.sender, amount, block.timestamp);
    }

    function withdrawToken(
        address token,
        address to,
        uint256 amount
    ) external override onlyRegisteredContracts {
        require(amount > 0, "No valid amount of tokens given to transfer");
        ERC20(token).safeTransfer(to, amount);
        emit TokenWithdrawn(msg.sender, address(token), amount, block.timestamp);
    }

    function burnToken(address token, uint256 amount) external override onlyRegisteredContracts {
        ERC20 tokenContract = ERC20(token);
        // Burn the tokens
        // tokenContract.burn(amount);
        emit TokenBurned(msg.sender, address(token), amount, block.timestamp);
    }
}
