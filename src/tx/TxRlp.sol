// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

import {VmRlp} from "../StdVm.sol";

/// @title RLP encoding helpers for transaction builders.
/// @dev Local copy for test use - does not depend on tempo-std VmRlp
library TxRlp {
    /// @notice Encodes a uint256 as minimal big-endian bytes (no leading zeros).
    /// @dev Zero is encoded as empty bytes per RLP spec.
    function encodeUint(uint256 value) internal pure returns (bytes memory) {
        if (value == 0) {
            return "";
        }

        uint256 temp = value;
        uint256 len = 0;
        while (temp > 0) {
            len++;
            temp >>= 8;
        }

        bytes memory result = new bytes(len);
        for (uint256 i = len; i > 0; i--) {
            // Intentional truncation: extracting lowest byte
            // forge-lint: disable-next-line(unsafe-typecast)
            result[i - 1] = bytes1(uint8(value));
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
    function encodeBytes32(bytes32 b) internal pure returns (bytes memory) {
        return encodeUint(uint256(b));
    }

    /// @notice Encodes a bytes32 as full 32 bytes (no stripping).
    function encodeBytes32Full(bytes32 b) internal pure returns (bytes memory) {
        return abi.encodePacked(b);
    }

    /// @notice RLP encodes a list using the Vm cheatcode.
    function encodeList(VmRlp vm, bytes[] memory items) internal pure returns (bytes memory) {
        return vm.toRlp(items);
    }

    /// @notice RLP encodes a raw string (bytes) with proper RLP prefix.
    function encodeString(bytes memory str) internal pure returns (bytes memory) {
        uint256 len = str.length;

        if (len == 1 && uint8(str[0]) < 0x80) {
            return str;
        } else if (len <= 55) {
            return abi.encodePacked(bytes1(uint8((0x80 + len) & 0xff)), str);
        } else {
            bytes memory lenBytes = encodeLength(len);
            return abi.encodePacked(bytes1(uint8((0xb7 + lenBytes.length) & 0xff)), lenBytes, str);
        }
    }

    /// @notice Concatenates already RLP-encoded items and wraps them as an RLP list.
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
    function prependListPrefix(bytes memory payload) internal pure returns (bytes memory) {
        uint256 len = payload.length;
        if (len <= 55) {
            return abi.encodePacked(bytes1(uint8((0xc0 + len) & 0xff)), payload);
        } else {
            bytes memory lenBytes = encodeLength(len);
            return abi.encodePacked(bytes1(uint8((0xf7 + lenBytes.length) & 0xff)), lenBytes, payload);
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
            // Intentional truncation: extracting lowest byte
            // forge-lint: disable-next-line(unsafe-typecast)
            result[i - 1] = bytes1(uint8(len));
            len >>= 8;
        }
        return result;
    }
}
