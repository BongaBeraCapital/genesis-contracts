// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/* Local Imports */
import {BeraMixin} from "../mixins/BeraMixin.sol";
import {SBPoolWrapperBera} from "./SBPoolWrapperBera.sol";
import {IBeraReserve} from "../../interfaces/IBeraReserve.sol";
import {IBeraStorage} from "../../interfaces/IBeraStorage.sol";
import {IKodiaqRouter} from "../../interfaces/IKodiaqRouter.sol";


contract SBController is BeraMixin {
    SBPoolWrapperBera[] beraPools;
    address kodiaqRouter;
    address kodiaqFactory;

    constructor(address _storageAddress) BeraMixin(_storageAddress) {
        version = 1;
    }
 
    // function deployTokenPool(
    //     uint256 leverageFactor,
    //     address token,
    //     uint256 feePercentage
    // ) external onlyRegisteredContracts {
    //     pools.push(new SBPoolWrapper(address(BeraStorage), kodiaqRouter, kodiaqFactory, leverageFactor, token, feePercentage));
    // }

    function deployBeraPool(
        uint256 leverageFactor,
        address token,
        uint256 feePercentage
    ) external onlyRegisteredContracts {
        beraPools.push(new SBPoolWrapperBera(address(BeraStorage), kodiaqRouter, kodiaqFactory, leverageFactor, token, feePercentage));
    }
}
