// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

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
/// @dev Encoding follows the Tempo spec where signed transactions have 15 fields:
///      14 transaction fields + 1 signature field (65-byte secp256k1: r || s || v)
library TempoTransactionLib {
    /// @notice Tempo transaction type prefix.
    uint8 internal constant TX_TYPE = 0x76;

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
    /// @dev Format: 0x76 || RLP([chainId, maxPriorityFeePerGas, maxFeePerGas, gasLimit, calls, accessList,
    ///              nonceKey, nonce, validBefore, validAfter, feeToken, feePayerSignature, authorizationList, keyAuthorization])
    ///      Note: keyAuthorization is truly optional (no bytes if not present)
    function encode(TempoTransaction memory self, VmRlp) internal pure returns (bytes memory) {
        // 13 mandatory fields + 1 optional keyAuthorization
        uint256 fieldCount = self.hasKeyAuthorization ? 14 : 13;
        bytes[] memory fields = new bytes[](fieldCount);

        // Scalar fields: encode value then wrap with RLP string prefix
        fields[0] = TxRlp.encodeString(TxRlp.encodeUint(self.chainId));
        fields[1] = TxRlp.encodeString(TxRlp.encodeUint(self.maxPriorityFeePerGas));
        fields[2] = TxRlp.encodeString(TxRlp.encodeUint(self.maxFeePerGas));
        fields[3] = TxRlp.encodeString(TxRlp.encodeUint(self.gasLimit));

        // Nested lists: already fully RLP encoded, pass directly
        fields[4] = _encodeCalls(self.calls);
        fields[5] = _encodeAccessList(self.accessList);

        // More scalar fields
        fields[6] = TxRlp.encodeString(TxRlp.encodeUint(self.nonceKey));
        fields[7] = TxRlp.encodeString(TxRlp.encodeUint(self.nonce));
        fields[8] = TxRlp.encodeString(self.hasValidBefore ? TxRlp.encodeUint(self.validBefore) : TxRlp.encodeNone());
        fields[9] = TxRlp.encodeString(self.hasValidAfter ? TxRlp.encodeUint(self.validAfter) : TxRlp.encodeNone());
        fields[10] = TxRlp.encodeString(self.hasFeeToken ? TxRlp.encodeAddress(self.feeToken) : TxRlp.encodeNone());

        // Fee payer signature: encoded as RLP list [v, r, s] if present, else 0x80
        fields[11] = self.hasFeePayerSignature
            ? _encodeFeePayerSignature(self.feePayerSignature)
            : TxRlp.encodeString(TxRlp.encodeNone());

        // Authorization list (always present, can be empty)
        fields[12] = _encodeAuthorizationList(self.authorizationList);

        // Key authorization is truly optional (no bytes if not present)
        if (self.hasKeyAuthorization) {
            fields[13] = TxRlp.encodeString(self.keyAuthorization);
        }

        bytes memory rlpPayload = TxRlp.encodeRawList(fields);
        return abi.encodePacked(TX_TYPE, rlpPayload);
    }

    /// @notice RLP encodes the signed transaction with type prefix 0x76.
    /// @dev Format: 0x76 || RLP([...14 fields, signature_bytes])
    ///      The signature is a 65-byte secp256k1 signature: r (32) || s (32) || v (1)
    /// @param v The recovery parameter (27 or 28 from vm.sign). Will be stored as-is in the signature bytes.
    function encodeWithSignature(TempoTransaction memory self, VmRlp, uint8 v, bytes32 r, bytes32 s)
        internal
        pure
        returns (bytes memory)
    {
        // 13 or 14 tx fields + 1 signature field
        uint256 fieldCount = self.hasKeyAuthorization ? 15 : 14;
        bytes[] memory fields = new bytes[](fieldCount);

        // Encode all transaction fields (same as unsigned)
        fields[0] = TxRlp.encodeString(TxRlp.encodeUint(self.chainId));
        fields[1] = TxRlp.encodeString(TxRlp.encodeUint(self.maxPriorityFeePerGas));
        fields[2] = TxRlp.encodeString(TxRlp.encodeUint(self.maxFeePerGas));
        fields[3] = TxRlp.encodeString(TxRlp.encodeUint(self.gasLimit));
        fields[4] = _encodeCalls(self.calls);
        fields[5] = _encodeAccessList(self.accessList);
        fields[6] = TxRlp.encodeString(TxRlp.encodeUint(self.nonceKey));
        fields[7] = TxRlp.encodeString(TxRlp.encodeUint(self.nonce));
        fields[8] = TxRlp.encodeString(self.hasValidBefore ? TxRlp.encodeUint(self.validBefore) : TxRlp.encodeNone());
        fields[9] = TxRlp.encodeString(self.hasValidAfter ? TxRlp.encodeUint(self.validAfter) : TxRlp.encodeNone());
        fields[10] = TxRlp.encodeString(self.hasFeeToken ? TxRlp.encodeAddress(self.feeToken) : TxRlp.encodeNone());
        fields[11] = self.hasFeePayerSignature
            ? _encodeFeePayerSignature(self.feePayerSignature)
            : TxRlp.encodeString(TxRlp.encodeNone());
        fields[12] = _encodeAuthorizationList(self.authorizationList);

        uint256 sigFieldIdx;
        if (self.hasKeyAuthorization) {
            fields[13] = TxRlp.encodeString(self.keyAuthorization);
            sigFieldIdx = 14;
        } else {
            sigFieldIdx = 13;
        }

        // Signature field: 65 bytes (r || s || v) encoded as RLP bytes string
        // Note: For secp256k1, the format is r (32 bytes) || s (32 bytes) || v (1 byte)
        bytes memory sigBytes = abi.encodePacked(r, s, v);
        fields[sigFieldIdx] = TxRlp.encodeString(sigBytes);

        bytes memory rlpPayload = TxRlp.encodeRawList(fields);
        return abi.encodePacked(TX_TYPE, rlpPayload);
    }

    /// @notice Encodes the calls array as an RLP list.
    /// @dev Each call is encoded as [to, value, data].
    ///      For CREATE calls (to == address(0)), `to` is encoded as empty string (0x80)
    ///      to match Rust's TxKind::Create encoding.
    function _encodeCalls(TempoCall[] memory calls) private pure returns (bytes memory) {
        bytes[] memory encodedCalls = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            bytes[] memory callFields = new bytes[](3);
            // CREATE is encoded as empty string, CALL is encoded as 20-byte address
            if (calls[i].to == address(0)) {
                callFields[0] = TxRlp.encodeString(TxRlp.encodeNone()); // CREATE: empty string
            } else {
                callFields[0] = TxRlp.encodeString(TxRlp.encodeAddress(calls[i].to));
            }
            callFields[1] = TxRlp.encodeString(TxRlp.encodeUint(calls[i].value));
            callFields[2] = TxRlp.encodeString(calls[i].data);
            encodedCalls[i] = TxRlp.encodeRawList(callFields);
        }
        return TxRlp.encodeRawList(encodedCalls);
    }

    /// @notice Encodes the access list as an RLP list.
    /// @dev Each item is encoded as [address, [storageKey1, storageKey2, ...]].
    function _encodeAccessList(AccessListItem[] memory list) private pure returns (bytes memory) {
        bytes[] memory encodedItems = new bytes[](list.length);
        for (uint256 i = 0; i < list.length; i++) {
            bytes[] memory keys = new bytes[](list[i].storageKeys.length);
            for (uint256 j = 0; j < list[i].storageKeys.length; j++) {
                keys[j] = TxRlp.encodeString(TxRlp.encodeBytes32Full(list[i].storageKeys[j]));
            }
            bytes memory keysList = TxRlp.encodeRawList(keys);

            bytes[] memory itemFields = new bytes[](2);
            itemFields[0] = TxRlp.encodeString(TxRlp.encodeAddress(list[i].target));
            itemFields[1] = keysList; // Already a fully encoded list
            encodedItems[i] = TxRlp.encodeRawList(itemFields);
        }
        return TxRlp.encodeRawList(encodedItems);
    }

    /// @notice Encodes the authorization list as an RLP list.
    function _encodeAuthorizationList(TempoAuthorization[] memory list) private pure returns (bytes memory) {
        bytes[] memory encodedAuths = new bytes[](list.length);
        for (uint256 i = 0; i < list.length; i++) {
            bytes[] memory authFields = new bytes[](6);
            authFields[0] = TxRlp.encodeString(TxRlp.encodeUint(list[i].chainId));
            authFields[1] = TxRlp.encodeString(TxRlp.encodeAddress(list[i].authority));
            authFields[2] = TxRlp.encodeString(TxRlp.encodeUint(list[i].nonce));
            authFields[3] = TxRlp.encodeString(TxRlp.encodeUint(list[i].yParity));
            authFields[4] = TxRlp.encodeString(TxRlp.encodeBytes32(list[i].r));
            authFields[5] = TxRlp.encodeString(TxRlp.encodeBytes32(list[i].s));
            encodedAuths[i] = TxRlp.encodeRawList(authFields);
        }
        return TxRlp.encodeRawList(encodedAuths);
    }

    /// @notice Encodes fee payer signature as RLP list [v, r, s]
    function _encodeFeePayerSignature(bytes memory sig) private pure returns (bytes memory) {
        require(sig.length == 65, "Invalid fee payer signature length");

        // Parse signature: first 32 bytes = r, next 32 = s, last byte = v
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Encode as RLP list [r, s, v] matching Rust's write_rlp_vrs order
        bytes[] memory sigFields = new bytes[](3);
        sigFields[0] = TxRlp.encodeString(TxRlp.encodeBytes32(r));
        sigFields[1] = TxRlp.encodeString(TxRlp.encodeBytes32(s));
        sigFields[2] = TxRlp.encodeString(TxRlp.encodeUint(v));
        return TxRlp.encodeRawList(sigFields);
    }

    // ============ Legacy function signatures for backwards compatibility ============

    /// @notice Encodes the calls array as an RLP list (legacy signature).
    function encodeCalls(VmRlp, TempoCall[] memory calls) internal pure returns (bytes memory) {
        return _encodeCalls(calls);
    }

    /// @notice Encodes the access list as an RLP list (legacy signature).
    function encodeAccessList(VmRlp, AccessListItem[] memory list) internal pure returns (bytes memory) {
        return _encodeAccessList(list);
    }

    /// @notice Encodes the authorization list as an RLP list (legacy signature).
    function encodeAuthorizationList(VmRlp, TempoAuthorization[] memory list) internal pure returns (bytes memory) {
        return _encodeAuthorizationList(list);
    }
}
