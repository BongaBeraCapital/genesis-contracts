// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/* Local Imports */
import {BeraMixin} from "../mixins/BeraMixin.sol";
import {SBPool} from "./SBPool.sol";
import {IBeraReserve} from "../../interfaces/IBeraReserve.sol";
import {IBeraStorage} from "../../interfaces/IBeraStorage.sol";
import {IKodiaqRouter} from "../../interfaces/IKodiaqRouter.sol";


contract SBController is BeraMixin {
    address[] pools;
    mapping(address => address) pairToPool;
    address kodiaqRouter;
    address kodiaqFactory;

    constructor(address _storageAddress) BeraMixin(_storageAddress) {
        version = 1;
    }

    function deployPool(
        uint256 leverageFactor,
        address kodiaqPair
    ) external onlyRegisteredContracts {
        SBPool newPool = new SBPool(kodiaqRouter, leverageFactor, kodiaqPair);
        pools.push(address(newPool));
        pairToPool[kodiaqPair] = address(newPool);

    }

    function getPool(address pairAddress) external view returns (SBPool) {
        return SBPool(pairToPool[pairAddress]);
    }
}
