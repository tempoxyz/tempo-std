// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {VmRlp} from "../StdVm.sol";
import {TxRlp} from "./TxRlp.sol";
import {AccessListItem} from "./AccessListTypes.sol";

/// @notice Unsigned EIP-7702 authorization tuple.
struct Authorization {
    uint64 chainId;
    address authority;
    uint64 nonce;
}

/// @notice Signed EIP-7702 authorization tuple.
struct SignedAuthorization {
    uint64 chainId;
    address authority;
    uint64 nonce;
    uint8 yParity;
    bytes32 r;
    bytes32 s;
}

/// @notice EIP-7702 transaction (type 0x04).
struct Eip7702Transaction {
    uint64 chainId;
    uint64 nonce;
    uint256 maxPriorityFeePerGas;
    uint256 maxFeePerGas;
    uint64 gasLimit;
    address to;
    uint256 value;
    bytes data;
    AccessListItem[] accessList;
    SignedAuthorization[] authorizationList;
}

/// @title Library for encoding unsigned authorizations.
library AuthorizationLib {
    /// @notice RLP encodes an unsigned authorization for signing.
    /// @dev Signing hash is `keccak256(0x05 || encode(auth))`.
    /// @param self The authorization to encode.
    /// @param vm The Vm RLP interface.
    /// @return The RLP-encoded authorization (no type prefix).
    function encode(Authorization memory self, VmRlp vm) internal pure returns (bytes memory) {
        bytes[] memory items = new bytes[](3);
        items[0] = TxRlp.encodeUint(self.chainId);
        items[1] = TxRlp.encodeAddress(self.authority);
        items[2] = TxRlp.encodeUint(self.nonce);
        return TxRlp.encodeList(vm, items);
    }
}

/// @title Library for building and RLP-encoding EIP-7702 transactions.
library Eip7702TransactionLib {
    /// @notice EIP-7702 transaction type prefix.
    bytes1 internal constant TYPE_PREFIX = 0x04;

    /// @notice Creates a new EIP-7702 transaction with default values.
    function create() internal pure returns (Eip7702Transaction memory t) {
        t.gasLimit = 21000;
    }

    /// @notice Sets the chain ID.
    function withChainId(Eip7702Transaction memory self, uint64 chainId)
        internal
        pure
        returns (Eip7702Transaction memory)
    {
        self.chainId = chainId;
        return self;
    }

    /// @notice Sets the nonce.
    function withNonce(Eip7702Transaction memory self, uint64 nonce) internal pure returns (Eip7702Transaction memory) {
        self.nonce = nonce;
        return self;
    }

    /// @notice Sets the max priority fee per gas.
    function withMaxPriorityFeePerGas(Eip7702Transaction memory self, uint256 fee)
        internal
        pure
        returns (Eip7702Transaction memory)
    {
        self.maxPriorityFeePerGas = fee;
        return self;
    }

    /// @notice Sets the max fee per gas.
    function withMaxFeePerGas(Eip7702Transaction memory self, uint256 fee)
        internal
        pure
        returns (Eip7702Transaction memory)
    {
        self.maxFeePerGas = fee;
        return self;
    }

    /// @notice Sets the gas limit.
    function withGasLimit(Eip7702Transaction memory self, uint64 gasLimit)
        internal
        pure
        returns (Eip7702Transaction memory)
    {
        self.gasLimit = gasLimit;
        return self;
    }

    /// @notice Sets the destination address.
    function withTo(Eip7702Transaction memory self, address to) internal pure returns (Eip7702Transaction memory) {
        self.to = to;
        return self;
    }

    /// @notice Sets the value in wei.
    function withValue(Eip7702Transaction memory self, uint256 value)
        internal
        pure
        returns (Eip7702Transaction memory)
    {
        self.value = value;
        return self;
    }

    /// @notice Sets the calldata.
    function withData(Eip7702Transaction memory self, bytes memory data)
        internal
        pure
        returns (Eip7702Transaction memory)
    {
        self.data = data;
        return self;
    }

    /// @notice Sets the access list.
    function withAccessList(Eip7702Transaction memory self, AccessListItem[] memory accessList)
        internal
        pure
        returns (Eip7702Transaction memory)
    {
        self.accessList = accessList;
        return self;
    }

    /// @notice Sets the authorization list.
    function withAuthorizationList(Eip7702Transaction memory self, SignedAuthorization[] memory authorizationList)
        internal
        pure
        returns (Eip7702Transaction memory)
    {
        self.authorizationList = authorizationList;
        return self;
    }

    /// @notice RLP encodes the unsigned transaction with type prefix.
    /// @param self The transaction to encode.
    /// @param vm The Vm RLP interface.
    /// @return The encoded transaction: `0x04 || RLP([fields...])`.
    function encode(Eip7702Transaction memory self, VmRlp vm) internal pure returns (bytes memory) {
        bytes[] memory items = new bytes[](10);
        items[0] = TxRlp.encodeUint(self.chainId);
        items[1] = TxRlp.encodeUint(self.nonce);
        items[2] = TxRlp.encodeUint(self.maxPriorityFeePerGas);
        items[3] = TxRlp.encodeUint(self.maxFeePerGas);
        items[4] = TxRlp.encodeUint(self.gasLimit);
        items[5] = TxRlp.encodeAddress(self.to);
        items[6] = TxRlp.encodeUint(self.value);
        items[7] = self.data;
        items[8] = encodeAccessList(vm, self.accessList);
        items[9] = encodeAuthorizationList(vm, self.authorizationList);

        return abi.encodePacked(TYPE_PREFIX, TxRlp.encodeList(vm, items));
    }

    /// @notice RLP encodes the signed transaction with type prefix.
    /// @param self The transaction to encode.
    /// @param vm The Vm RLP interface.
    /// @param yParity The signature y-parity (0 or 1).
    /// @param r The signature r value.
    /// @param s The signature s value.
    /// @return The encoded transaction: `0x04 || RLP([fields..., yParity, r, s])`.
    function encodeWithSignature(Eip7702Transaction memory self, VmRlp vm, uint8 yParity, bytes32 r, bytes32 s)
        internal
        pure
        returns (bytes memory)
    {
        bytes[] memory items = new bytes[](13);
        items[0] = TxRlp.encodeUint(self.chainId);
        items[1] = TxRlp.encodeUint(self.nonce);
        items[2] = TxRlp.encodeUint(self.maxPriorityFeePerGas);
        items[3] = TxRlp.encodeUint(self.maxFeePerGas);
        items[4] = TxRlp.encodeUint(self.gasLimit);
        items[5] = TxRlp.encodeAddress(self.to);
        items[6] = TxRlp.encodeUint(self.value);
        items[7] = self.data;
        items[8] = encodeAccessList(vm, self.accessList);
        items[9] = encodeAuthorizationList(vm, self.authorizationList);
        items[10] = TxRlp.encodeUint(yParity);
        items[11] = TxRlp.encodeBytes32(r);
        items[12] = TxRlp.encodeBytes32(s);

        return abi.encodePacked(TYPE_PREFIX, TxRlp.encodeList(vm, items));
    }

    /// @notice Encodes an access list as RLP.
    function encodeAccessList(VmRlp vm, AccessListItem[] memory list) private pure returns (bytes memory) {
        bytes[] memory encodedItems = new bytes[](list.length);
        for (uint256 i = 0; i < list.length; i++) {
            bytes[] memory keys = new bytes[](list[i].storageKeys.length);
            for (uint256 j = 0; j < list[i].storageKeys.length; j++) {
                keys[j] = TxRlp.encodeBytes32Full(list[i].storageKeys[j]);
            }

            bytes[] memory item = new bytes[](2);
            item[0] = TxRlp.encodeAddress(list[i].target);
            item[1] = TxRlp.encodeList(vm, keys);
            encodedItems[i] = TxRlp.encodeList(vm, item);
        }
        return TxRlp.encodeList(vm, encodedItems);
    }

    /// @notice Encodes an authorization list as RLP.
    function encodeAuthorizationList(VmRlp vm, SignedAuthorization[] memory list) private pure returns (bytes memory) {
        bytes[] memory encodedItems = new bytes[](list.length);
        for (uint256 i = 0; i < list.length; i++) {
            bytes[] memory item = new bytes[](6);
            item[0] = TxRlp.encodeUint(list[i].chainId);
            item[1] = TxRlp.encodeAddress(list[i].authority);
            item[2] = TxRlp.encodeUint(list[i].nonce);
            item[3] = TxRlp.encodeUint(list[i].yParity);
            item[4] = TxRlp.encodeBytes32(list[i].r);
            item[5] = TxRlp.encodeBytes32(list[i].s);
            encodedItems[i] = TxRlp.encodeList(vm, item);
        }
        return TxRlp.encodeList(vm, encodedItems);
    }
}
