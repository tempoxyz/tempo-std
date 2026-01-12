// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {VmRlp} from "../StdVm.sol";

/// @title RLP encoding helpers for transaction builders.
library TxRlp {
    /// @notice Encodes a uint256 as minimal big-endian bytes (no leading zeros).
    /// @dev Zero is encoded as empty bytes per RLP spec.
    function encodeUint(uint256 value) internal pure returns (bytes memory) {
        if (value == 0) {
            return "";
        }

        // Count bytes needed
        uint256 temp = value;
        uint256 len = 0;
        while (temp > 0) {
            len++;
            temp >>= 8;
        }

        // Build result in big-endian order
        bytes memory result = new bytes(len);
        for (uint256 i = len; i > 0; i--) {
            // forge-lint: disable-next-line(unsafe-typecast)
            result[i - 1] = bytes1(uint8(value)); // Safe: extracting lowest byte
            value >>= 8;
        }
        return result;
    }

    /// @notice Encodes an address as 20 bytes.
    function encodeAddress(address a) internal pure returns (bytes memory) {
        return abi.encodePacked(a);
    }

    /// @notice Returns empty bytes for RLP "None" / empty string.
    function encodeNone() internal pure returns (bytes memory) {
        return "";
    }

    /// @notice Encodes a bytes32 as minimal bytes (leading zeros stripped).
    /// @dev Used for signature r and s values in RLP encoding.
    function encodeBytes32(bytes32 b) internal pure returns (bytes memory) {
        return encodeUint(uint256(b));
    }

    /// @notice Encodes a bytes32 as full 32 bytes (no stripping).
    /// @dev Used for storage keys in access lists.
    function encodeBytes32Full(bytes32 b) internal pure returns (bytes memory) {
        return abi.encodePacked(b);
    }

    /// @notice RLP encodes a list using the Vm cheatcode.
    function encodeList(VmRlp vm, bytes[] memory items) internal pure returns (bytes memory) {
        return vm.toRlp(items);
    }
}
