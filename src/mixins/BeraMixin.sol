pragma solidity 0.8.10;
/* SPDX-License-Identifier: MIT */

/* Internal Imports */
import {BeraStorageKeys} from "../storage/BeraStorageKeys.sol";

/* Interface Imports */
import {IBeraStorage} from "../../interfaces/IBeraStorage.sol";

/**
 * @title BeraMixin
 * @author 0xrebased @ Bonga Bera Capital: https://github.com/BongaBeraCapital
 * @notice A mixin that allows the child class to access eternal BeraStorage contracts
 */
abstract contract BeraMixin is BeraStorageKeys {
    //=================================================================================================================
    // State Variables
    //=================================================================================================================

    uint256 public version;
    IBeraStorage internal BeraStorage;

    //=================================================================================================================
    // Constructor
    //=================================================================================================================

    constructor(address storageContractAddress) {
        BeraStorage = IBeraStorage(storageContractAddress);
    }

    //=================================================================================================================
    // Errors
    //=================================================================================================================

    // error BeraStorageMixin__ContractNotFoundByAddressOrIsOutdated(address contractAddress);
    // error BeraStorageMixin__ContractNotFoundByNameOrIsOutdated(bytes32 contractName);
    // error BeraStorageMixin__UserIsNotGuardian(address user);

    //=================================================================================================================
    // Internal
    //=================================================================================================================

    function getContractAddress(string memory contractName) internal view returns (address) {
        address contractAddress = BeraStorage.getAddress(
            keccak256(abi.encodePacked(BeraStorageKeys.contracts.addressof, contractName))
        );
        if (contractAddress == address(0x0))
            revert("BeraStorageMixin__ContractNotFoundByNameOrIsOutdated(contractName);");
        return contractAddress;
    }

    function getContractName(address addr) internal view returns(string memory) {
        return BeraStorage.getString(
            keccak256(abi.encodePacked(BeraStorageKeys.contracts.nameof, addr))
        );
    }

    //=================================================================================================================
    // Modifiers
    //=================================================================================================================

    modifier onlyRegisteredContracts() {
        if (!BeraStorage.getBool(keccak256(abi.encodePacked(BeraStorageKeys.contracts.registered, msg.sender))))
            revert("BeraStorageMixin__ContractNotFoundByAddressOrIsOutdated(msg.sender);");
        _;
    }

    modifier onlyContract(string memory contractName, address contractAddress) {
        if (
            contractAddress !=
            BeraStorage.getAddress(keccak256(abi.encodePacked(BeraStorageKeys.contracts.nameof, contractName)))
        ) revert("BeraStorageMixin__ContractNotFoundByNameOrIsOutdated(contractName)");
        _;
    }

    modifier onlyFromStorageGuardian() {
        if (msg.sender != BeraStorage.getGuardian()) revert("BeraStorageMixin__UserIsNotGuardian(msg.sender)");
        _;
    }
}
