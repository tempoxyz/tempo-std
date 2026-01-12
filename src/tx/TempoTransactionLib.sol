// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {VmRlp} from "../StdVm.sol";
import {TxRlp} from "./TxRlp.sol";
import {AccessListItem} from "./AccessListTypes.sol";

/// @notice A single call in a Tempo transaction batch.
struct TempoCall {
    address to;
    uint256 value;
    bytes data;
}

/// @notice A signed authorization for Tempo transactions.
struct TempoAuthorization {
    uint256 chainId;
    address authority;
    uint64 nonce;
    uint8 yParity;
    bytes32 r;
    bytes32 s;
}

/// @notice A Tempo transaction (type 0x76).
struct TempoTransaction {
    uint64 chainId;
    uint256 maxPriorityFeePerGas;
    uint256 maxFeePerGas;
    uint64 gasLimit;
    TempoCall[] calls;
    AccessListItem[] accessList;
    uint256 nonceKey;
    uint64 nonce;
    bool hasValidBefore;
    uint64 validBefore;
    bool hasValidAfter;
    uint64 validAfter;
    bool hasFeeToken;
    address feeToken;
    bool hasFeePayerSignature;
    bytes feePayerSignature;
    TempoAuthorization[] authorizationList;
    bool hasKeyAuthorization;
    bytes keyAuthorization;
}

/// @title Builder and RLP encoder for Tempo transactions (type 0x76).
library TempoTransactionLib {
    /// @notice Creates a new Tempo transaction with default values.
    function create() internal pure returns (TempoTransaction memory tx_) {
        tx_.gasLimit = 21000;
    }

    /// @notice Sets the chain ID.
    function withChainId(TempoTransaction memory self, uint64 chainId) internal pure returns (TempoTransaction memory) {
        self.chainId = chainId;
        return self;
    }

    /// @notice Sets the max priority fee per gas.
    function withMaxPriorityFeePerGas(TempoTransaction memory self, uint256 fee)
        internal
        pure
        returns (TempoTransaction memory)
    {
        self.maxPriorityFeePerGas = fee;
        return self;
    }

    /// @notice Sets the max fee per gas.
    function withMaxFeePerGas(TempoTransaction memory self, uint256 fee)
        internal
        pure
        returns (TempoTransaction memory)
    {
        self.maxFeePerGas = fee;
        return self;
    }

    /// @notice Sets the gas limit.
    function withGasLimit(TempoTransaction memory self, uint64 gasLimit)
        internal
        pure
        returns (TempoTransaction memory)
    {
        self.gasLimit = gasLimit;
        return self;
    }

    /// @notice Sets the calls array.
    function withCalls(TempoTransaction memory self, TempoCall[] memory calls)
        internal
        pure
        returns (TempoTransaction memory)
    {
        self.calls = calls;
        return self;
    }

    /// @notice Convenience method to set a single call.
    function withCall(TempoTransaction memory self, address to, uint256 value, bytes memory data)
        internal
        pure
        returns (TempoTransaction memory)
    {
        TempoCall[] memory calls = new TempoCall[](1);
        calls[0] = TempoCall({to: to, value: value, data: data});
        self.calls = calls;
        return self;
    }

    /// @notice Sets the access list.
    function withAccessList(TempoTransaction memory self, AccessListItem[] memory accessList)
        internal
        pure
        returns (TempoTransaction memory)
    {
        self.accessList = accessList;
        return self;
    }

    /// @notice Sets the 2D nonce key.
    function withNonceKey(TempoTransaction memory self, uint256 nonceKey)
        internal
        pure
        returns (TempoTransaction memory)
    {
        self.nonceKey = nonceKey;
        return self;
    }

    /// @notice Sets the nonce.
    function withNonce(TempoTransaction memory self, uint64 nonce) internal pure returns (TempoTransaction memory) {
        self.nonce = nonce;
        return self;
    }

    /// @notice Sets the validBefore timestamp.
    function withValidBefore(TempoTransaction memory self, uint64 timestamp)
        internal
        pure
        returns (TempoTransaction memory)
    {
        self.hasValidBefore = true;
        self.validBefore = timestamp;
        return self;
    }

    /// @notice Sets the validAfter timestamp.
    function withValidAfter(TempoTransaction memory self, uint64 timestamp)
        internal
        pure
        returns (TempoTransaction memory)
    {
        self.hasValidAfter = true;
        self.validAfter = timestamp;
        return self;
    }

    /// @notice Sets the fee token address.
    function withFeeToken(TempoTransaction memory self, address token) internal pure returns (TempoTransaction memory) {
        self.hasFeeToken = true;
        self.feeToken = token;
        return self;
    }

    /// @notice Sets the fee payer signature.
    function withFeePayerSignature(TempoTransaction memory self, bytes memory signature)
        internal
        pure
        returns (TempoTransaction memory)
    {
        self.hasFeePayerSignature = true;
        self.feePayerSignature = signature;
        return self;
    }

    /// @notice Sets the authorization list.
    function withAuthorizationList(TempoTransaction memory self, TempoAuthorization[] memory authorizationList)
        internal
        pure
        returns (TempoTransaction memory)
    {
        self.authorizationList = authorizationList;
        return self;
    }

    /// @notice Sets the key authorization.
    function withKeyAuthorization(TempoTransaction memory self, bytes memory keyAuthorization)
        internal
        pure
        returns (TempoTransaction memory)
    {
        self.hasKeyAuthorization = true;
        self.keyAuthorization = keyAuthorization;
        return self;
    }

    /// @notice RLP encodes the unsigned transaction with type prefix 0x76.
    function encode(TempoTransaction memory self, VmRlp vm) internal pure returns (bytes memory) {
        bytes[] memory fields = new bytes[](14);

        fields[0] = TxRlp.encodeUint(self.chainId);
        fields[1] = TxRlp.encodeUint(self.maxPriorityFeePerGas);
        fields[2] = TxRlp.encodeUint(self.maxFeePerGas);
        fields[3] = TxRlp.encodeUint(self.gasLimit);
        fields[4] = encodeCalls(vm, self.calls);
        fields[5] = encodeAccessList(vm, self.accessList);
        fields[6] = TxRlp.encodeUint(self.nonceKey);
        fields[7] = TxRlp.encodeUint(self.nonce);
        fields[8] = self.hasValidBefore ? TxRlp.encodeUint(self.validBefore) : TxRlp.encodeNone();
        fields[9] = self.hasValidAfter ? TxRlp.encodeUint(self.validAfter) : TxRlp.encodeNone();
        fields[10] = self.hasFeeToken ? TxRlp.encodeAddress(self.feeToken) : TxRlp.encodeNone();
        fields[11] = self.hasFeePayerSignature ? self.feePayerSignature : TxRlp.encodeNone();
        fields[12] = encodeAuthorizationList(vm, self.authorizationList);
        fields[13] = self.hasKeyAuthorization ? self.keyAuthorization : TxRlp.encodeNone();

        bytes memory rlpPayload = TxRlp.encodeList(vm, fields);
        return abi.encodePacked(bytes1(0x76), rlpPayload);
    }

    /// @notice RLP encodes the signed transaction with type prefix 0x76.
    function encodeWithSignature(TempoTransaction memory self, VmRlp vm, uint8 v, bytes32 r, bytes32 s)
        internal
        pure
        returns (bytes memory)
    {
        bytes[] memory fields = new bytes[](17);

        fields[0] = TxRlp.encodeUint(self.chainId);
        fields[1] = TxRlp.encodeUint(self.maxPriorityFeePerGas);
        fields[2] = TxRlp.encodeUint(self.maxFeePerGas);
        fields[3] = TxRlp.encodeUint(self.gasLimit);
        fields[4] = encodeCalls(vm, self.calls);
        fields[5] = encodeAccessList(vm, self.accessList);
        fields[6] = TxRlp.encodeUint(self.nonceKey);
        fields[7] = TxRlp.encodeUint(self.nonce);
        fields[8] = self.hasValidBefore ? TxRlp.encodeUint(self.validBefore) : TxRlp.encodeNone();
        fields[9] = self.hasValidAfter ? TxRlp.encodeUint(self.validAfter) : TxRlp.encodeNone();
        fields[10] = self.hasFeeToken ? TxRlp.encodeAddress(self.feeToken) : TxRlp.encodeNone();
        fields[11] = self.hasFeePayerSignature ? self.feePayerSignature : TxRlp.encodeNone();
        fields[12] = encodeAuthorizationList(vm, self.authorizationList);
        fields[13] = self.hasKeyAuthorization ? self.keyAuthorization : TxRlp.encodeNone();
        fields[14] = TxRlp.encodeUint(v);
        fields[15] = TxRlp.encodeBytes32(r);
        fields[16] = TxRlp.encodeBytes32(s);

        bytes memory rlpPayload = TxRlp.encodeList(vm, fields);
        return abi.encodePacked(bytes1(0x76), rlpPayload);
    }

    /// @notice Encodes the calls array as an RLP list.
    function encodeCalls(VmRlp vm, TempoCall[] memory calls) internal pure returns (bytes memory) {
        bytes[] memory encodedCalls = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            bytes[] memory callFields = new bytes[](3);
            callFields[0] = TxRlp.encodeAddress(calls[i].to);
            callFields[1] = TxRlp.encodeUint(calls[i].value);
            callFields[2] = calls[i].data;
            encodedCalls[i] = TxRlp.encodeList(vm, callFields);
        }
        return TxRlp.encodeList(vm, encodedCalls);
    }

    /// @notice Encodes the access list as an RLP list.
    function encodeAccessList(VmRlp vm, AccessListItem[] memory list) internal pure returns (bytes memory) {
        bytes[] memory encodedItems = new bytes[](list.length);
        for (uint256 i = 0; i < list.length; i++) {
            bytes[] memory keys = new bytes[](list[i].storageKeys.length);
            for (uint256 j = 0; j < list[i].storageKeys.length; j++) {
                keys[j] = TxRlp.encodeBytes32Full(list[i].storageKeys[j]);
            }
            bytes[] memory itemFields = new bytes[](2);
            itemFields[0] = TxRlp.encodeAddress(list[i].target);
            itemFields[1] = TxRlp.encodeList(vm, keys);
            encodedItems[i] = TxRlp.encodeList(vm, itemFields);
        }
        return TxRlp.encodeList(vm, encodedItems);
    }

    /// @notice Encodes the authorization list as an RLP list.
    function encodeAuthorizationList(VmRlp vm, TempoAuthorization[] memory list) internal pure returns (bytes memory) {
        bytes[] memory encodedAuths = new bytes[](list.length);
        for (uint256 i = 0; i < list.length; i++) {
            bytes[] memory authFields = new bytes[](6);
            authFields[0] = TxRlp.encodeUint(list[i].chainId);
            authFields[1] = TxRlp.encodeAddress(list[i].authority);
            authFields[2] = TxRlp.encodeUint(list[i].nonce);
            authFields[3] = TxRlp.encodeUint(list[i].yParity);
            authFields[4] = TxRlp.encodeBytes32(list[i].r);
            authFields[5] = TxRlp.encodeBytes32(list[i].s);
            encodedAuths[i] = TxRlp.encodeList(vm, authFields);
        }
        return TxRlp.encodeList(vm, encodedAuths);
    }
}
