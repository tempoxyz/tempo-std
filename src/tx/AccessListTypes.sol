// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @notice An entry in an EIP-2930 access list.
struct AccessListItem {
    address target;
    bytes32[] storageKeys;
}
