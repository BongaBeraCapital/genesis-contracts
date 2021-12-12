/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;
/* Internal Imports */
import {BeraStorageKeys} from "./BeraStorageKeys.sol";

/* Interface Imports */
import {IBeraStorage} from "../../interfaces/IBeraStorage.sol";

/**
 * @title BeraStorage
 * @author 0xrebased @ Bonga Bera Capital: https://github.com/BongaBeraCapital
 * @notice A generalized eternal storage contract
 */
contract BeraStorage is BeraStorageKeys, IBeraStorage {
    //=================================================================================================================
    // Storage Maps
    //=================================================================================================================

    mapping(bytes32 => string) private stringStorage;
    mapping(bytes32 => bytes) private bytesStorage;
    mapping(bytes32 => uint256) private uintStorage;
    mapping(bytes32 => int256) private intStorage;
    mapping(bytes32 => address) private addressStorage;
    mapping(bytes32 => bool) private booleanStorage;
    mapping(bytes32 => bytes32) private bytes32Storage;

    //=================================================================================================================
    // State Variables
    //=================================================================================================================

    address storageGuardian;
    address newStorageGuardian;

    //=================================================================================================================
    // Constructor
    //=================================================================================================================

    constructor() {
        storageGuardian = msg.sender;
    }

    //=================================================================================================================
    // Events
    //=================================================================================================================

    event GuardianChanged(address oldStorageGuardian, address newStorageGuardian);

    //=================================================================================================================
    // Modifiers
    //=================================================================================================================

    modifier onlyRegisteredContracts() {
        if (
            !(booleanStorage[keccak256(abi.encodePacked(BeraStorageKeys.contracts.registered, msg.sender))] ||
                tx.origin == storageGuardian)
        ) revert("BeraStorage__ContractNotRegistered(msg.sender);");
        _;
    }

    //=================================================================================================================
    // External Functions
    //=================================================================================================================

    function getGuardian() external view override returns (address) {
        return storageGuardian;
    }

    function sendGuardianInvitation(address _newAddress) external override {
        if (msg.sender != storageGuardian) revert("BeraStorage__NotStorageGuardian(msg.sender);");
        newStorageGuardian = _newAddress;
    }

    function acceptGuardianInvitation() external override {
        if (msg.sender != newStorageGuardian) revert("BeraStorage__NoGuardianInvitation(msg.sender);");
        address oldGuardian = storageGuardian;
        storageGuardian = newStorageGuardian;
        delete newStorageGuardian;
        emit GuardianChanged(oldGuardian, storageGuardian);
    }

    //=================================================================================================================
    // Accessors
    //=================================================================================================================

    /// @param _key The key for the record
    function getAddress(bytes32 _key) external view override returns (address r) {
        return addressStorage[_key];
    }

    /// @param _key The key for the record
    function getUint(bytes32 _key) external view override returns (uint256 r) {
        return uintStorage[_key];
    }

    /// @param _key The key for the record
    function getString(bytes32 _key) external view override returns (string memory) {
        return stringStorage[_key];
    }

    /// @param _key The key for the record
    function getBytes(bytes32 _key) external view override returns (bytes memory) {
        return bytesStorage[_key];
    }

    /// @param _key The key for the record
    function getBool(bytes32 _key) external view override returns (bool r) {
        return booleanStorage[_key];
    }

    /// @param _key The key for the record
    function getInt(bytes32 _key) external view override returns (int256 r) {
        return intStorage[_key];
    }

    /// @param _key The key for the record
    function getBytes32(bytes32 _key) external view override returns (bytes32 r) {
        return bytes32Storage[_key];
    }

    //=================================================================================================================
    // Mutators
    //=================================================================================================================

    /// @param _key The key for the record
    function setAddress(bytes32 _key, address _value) external override onlyRegisteredContracts {
        addressStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setUint(bytes32 _key, uint256 _value) external override onlyRegisteredContracts {
        uintStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setString(bytes32 _key, string calldata _value) external override onlyRegisteredContracts {
        stringStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setBytes(bytes32 _key, bytes calldata _value) external override onlyRegisteredContracts {
        bytesStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setBool(bytes32 _key, bool _value) external override onlyRegisteredContracts {
        booleanStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setInt(bytes32 _key, int256 _value) external override onlyRegisteredContracts {
        intStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setBytes32(bytes32 _key, bytes32 _value) external override onlyRegisteredContracts {
        bytes32Storage[_key] = _value;
    }

    //=================================================================================================================
    // Deletion
    //=================================================================================================================

    /// @param _key The key for the record
    function deleteAddress(bytes32 _key) external override onlyRegisteredContracts {
        delete addressStorage[_key];
    }

    /// @param _key The key for the record
    function deleteUint(bytes32 _key) external override onlyRegisteredContracts {
        delete uintStorage[_key];
    }

    /// @param _key The key for the record
    function deleteString(bytes32 _key) external override onlyRegisteredContracts {
        delete stringStorage[_key];
    }

    /// @param _key The key for the record
    function deleteBytes(bytes32 _key) external override onlyRegisteredContracts {
        delete bytesStorage[_key];
    }

    /// @param _key The key for the record
    function deleteBool(bytes32 _key) external override onlyRegisteredContracts {
        delete booleanStorage[_key];
    }

    /// @param _key The key for the record
    function deleteInt(bytes32 _key) external override onlyRegisteredContracts {
        delete intStorage[_key];
    }

    /// @param _key The key for the record
    function deleteBytes32(bytes32 _key) external override onlyRegisteredContracts {
        delete bytes32Storage[_key];
    }

    //=================================================================================================================
    // Arithmetic
    //=================================================================================================================

    /// @param _key The key for the record
    /// @param _amount An amount to add to the record's value
    function addUint(bytes32 _key, uint256 _amount) external override onlyRegisteredContracts {
        uintStorage[_key] = uintStorage[_key] + _amount;
    }

    /// @param _key The key for the record
    /// @param _amount An amount to subtract from the record's value
    function subUint(bytes32 _key, uint256 _amount) external override onlyRegisteredContracts {
        uintStorage[_key] = uintStorage[_key] - _amount;
    }
}
