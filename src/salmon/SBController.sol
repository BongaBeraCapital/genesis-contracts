pragma solidity 0.8.10;
// SPDX-License-Identifier: GPL-3.0-only

/* Local Imports */
import {BeraMixin} from "../mixins/BeraMixin.sol";
import {SBPool} from "./SBPool.sol";
import {IBeraReserve} from "../../interfaces/IBeraReserve.sol";
import {IBeraStorage} from "../../interfaces/IBeraStorage.sol";
import {IKodiaqRouter} from "../../interfaces/IKodiaqRouter.sol";

/* Package Imports */
import {FixedPointMathLib} from "solmate/utils/FixedPointMathlib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract SBController is BeraMixin {
    address kodiaqRouter;
    address kodiaqFactory;
    address beraReserve;
    mapping(address => uint256) borrowedAmount;
    SBPool[] pools;

    constructor(address _storageAddress) BeraMixin(_storageAddress) {
        version = 1;
    }

    function deployPool(
        uint256 leverageFactor,
        address token,
        uint256 feePercentage
    ) external onlyRegisteredContracts {
        pools.push(new SBPool(address(BeraStorage), kodiaqRouter, kodiaqFactory, leverageFactor, token, feePercentage));
    }
}
