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

    /// @notice RLP encodes a raw string (bytes) with proper RLP prefix.
    /// @dev For a string of length n:
    ///      - If n == 1 and byte < 0x80: no prefix (single byte is itself)
    ///      - If n <= 55: prefix is (0x80 + n)
    ///      - If n > 55: prefix is (0xb7 + length of n in bytes) followed by n in big-endian
    function encodeString(bytes memory str) internal pure returns (bytes memory) {
        uint256 len = str.length;

        if (len == 1 && uint8(str[0]) < 0x80) {
            return str;
        } else if (len <= 55) {
            // forge-lint: disable-next-line(unsafe-typecast)
            return abi.encodePacked(bytes1(uint8(0x80 + len)), str); // Safe: len <= 55, so 0x80 + len <= 0xb7
        } else {
            bytes memory lenBytes = encodeLength(len);
            return abi.encodePacked(bytes1(uint8(0xb7 + lenBytes.length)), lenBytes, str);
        }
    }

    /// @notice Concatenates already RLP-encoded items and wraps them as an RLP list.
    /// @dev This is used for nested lists where inner items are already RLP-encoded.
    ///      The function concatenates all items, then adds the appropriate list prefix.
    /// @param encodedItems Array of already RLP-encoded items.
    /// @return The RLP-encoded list containing all items.
    function encodeRawList(bytes[] memory encodedItems) internal pure returns (bytes memory) {
        uint256 totalLen = 0;
        for (uint256 i = 0; i < encodedItems.length; i++) {
            totalLen += encodedItems[i].length;
        }

        bytes memory payload = new bytes(totalLen);
        uint256 offset = 0;
        for (uint256 i = 0; i < encodedItems.length; i++) {
            bytes memory item = encodedItems[i];
            for (uint256 j = 0; j < item.length; j++) {
                payload[offset++] = item[j];
            }
        }

        return prependListPrefix(payload);
    }

    /// @notice Prepends the RLP list prefix to a payload.
    /// @dev For a list with payload length n:
    ///      - If n <= 55: prefix is (0xc0 + n)
    ///      - If n > 55: prefix is (0xf7 + length of n in bytes) followed by n in big-endian
    function prependListPrefix(bytes memory payload) internal pure returns (bytes memory) {
        uint256 len = payload.length;
        if (len <= 55) {
            // forge-lint: disable-next-line(unsafe-typecast)
            return abi.encodePacked(bytes1(uint8(0xc0 + len)), payload); // Safe: len <= 55, so 0xc0 + len <= 0xf7
        } else {
            bytes memory lenBytes = encodeLength(len);
            return abi.encodePacked(bytes1(uint8(0xf7 + lenBytes.length)), lenBytes, payload);
        }
    }

    /// @notice Encodes a length as minimal big-endian bytes.
    function encodeLength(uint256 len) internal pure returns (bytes memory) {
        if (len == 0) {
            return "";
        }

        uint256 temp = len;
        uint256 numBytes = 0;
        while (temp > 0) {
            numBytes++;
            temp >>= 8;
        }

        bytes memory result = new bytes(numBytes);
        for (uint256 i = numBytes; i > 0; i--) {
            // forge-lint: disable-next-line(unsafe-typecast)
            result[i - 1] = bytes1(uint8(len)); // Safe: extracting lowest byte
            len >>= 8;
        }
        return result;
    }
}
