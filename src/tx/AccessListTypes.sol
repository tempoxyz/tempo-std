// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

/// @notice An entry in an EIP-2930 access list.
struct AccessListItem {
    address target;
    bytes32[] storageKeys;
}
