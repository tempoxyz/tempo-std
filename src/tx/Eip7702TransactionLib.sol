// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

import {VmRlp} from "../StdVm.sol";
import {TxRlp} from "./TxRlp.sol";
import {AccessListItem} from "./AccessListTypes.sol";

/// @notice An EIP-7702 authorization tuple.
struct Eip7702Authorization {
    uint256 chainId;
    address codeAddress;
    uint64 nonce;
    uint8 yParity;
    bytes32 r;
    bytes32 s;
}

/// @notice An EIP-7702 (type 4) Ethereum transaction.
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
    Eip7702Authorization[] authorizationList;
}

/// @title Builder and RLP encoder for EIP-7702 transactions (type 0x04).
library Eip7702TransactionLib {
    using Eip7702TransactionLib for Eip7702Transaction;

    /// @notice EIP-7702 transaction type prefix.
    uint8 internal constant TX_TYPE = 0x04;

    /// @notice EIP-7702 authorization magic for signing.
    uint8 internal constant AUTH_MAGIC = 0x05;

    /// @notice Creates a new EIP-7702 transaction with default values.
    function create() internal view returns (Eip7702Transaction memory tx_) {
        tx_.chainId = uint64(block.chainid);
        tx_.gasLimit = 21000;
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

    /// @notice Sets the recipient address.
    function withTo(Eip7702Transaction memory self, address to) internal pure returns (Eip7702Transaction memory) {
        self.to = to;
        return self;
    }

    /// @notice Sets the value to send.
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
    function withAuthorizationList(Eip7702Transaction memory self, Eip7702Authorization[] memory authorizationList)
        internal
        pure
        returns (Eip7702Transaction memory)
    {
        self.authorizationList = authorizationList;
        return self;
    }

    /// @notice RLP encodes the unsigned transaction with type prefix 0x04.
    /// @dev Format: 0x04 || RLP([chainId, nonce, maxPriorityFeePerGas, maxFeePerGas, gasLimit, to, value, data, accessList, authorizationList])
    function encode(Eip7702Transaction memory self, VmRlp) internal pure returns (bytes memory) {
        bytes[] memory fields = new bytes[](10);

        fields[0] = TxRlp.encodeString(TxRlp.encodeUint(self.chainId));
        fields[1] = TxRlp.encodeString(TxRlp.encodeUint(self.nonce));
        fields[2] = TxRlp.encodeString(TxRlp.encodeUint(self.maxPriorityFeePerGas));
        fields[3] = TxRlp.encodeString(TxRlp.encodeUint(self.maxFeePerGas));
        fields[4] = TxRlp.encodeString(TxRlp.encodeUint(self.gasLimit));
        fields[5] = TxRlp.encodeString(self.to == address(0) ? TxRlp.encodeNone() : TxRlp.encodeAddress(self.to));
        fields[6] = TxRlp.encodeString(TxRlp.encodeUint(self.value));
        fields[7] = TxRlp.encodeString(self.data);
        fields[8] = _encodeAccessList(self.accessList);
        fields[9] = _encodeAuthorizationList(self.authorizationList);

        bytes memory rlpPayload = TxRlp.encodeRawList(fields);
        return abi.encodePacked(TX_TYPE, rlpPayload);
    }

    /// @notice RLP encodes the signed transaction with type prefix 0x04.
    /// @dev Format: 0x04 || RLP([chainId, nonce, maxPriorityFeePerGas, maxFeePerGas, gasLimit, to, value, data, accessList, authorizationList, yParity, r, s])
    function encodeWithSignature(Eip7702Transaction memory self, VmRlp, uint8 v, bytes32 r, bytes32 s)
        internal
        pure
        returns (bytes memory)
    {
        bytes[] memory fields = new bytes[](13);

        fields[0] = TxRlp.encodeString(TxRlp.encodeUint(self.chainId));
        fields[1] = TxRlp.encodeString(TxRlp.encodeUint(self.nonce));
        fields[2] = TxRlp.encodeString(TxRlp.encodeUint(self.maxPriorityFeePerGas));
        fields[3] = TxRlp.encodeString(TxRlp.encodeUint(self.maxFeePerGas));
        fields[4] = TxRlp.encodeString(TxRlp.encodeUint(self.gasLimit));
        fields[5] = TxRlp.encodeString(self.to == address(0) ? TxRlp.encodeNone() : TxRlp.encodeAddress(self.to));
        fields[6] = TxRlp.encodeString(TxRlp.encodeUint(self.value));
        fields[7] = TxRlp.encodeString(self.data);
        fields[8] = _encodeAccessList(self.accessList);
        fields[9] = _encodeAuthorizationList(self.authorizationList);

        uint8 yParity = v >= 27 ? v - 27 : v;
        fields[10] = TxRlp.encodeString(TxRlp.encodeUint(yParity));
        fields[11] = TxRlp.encodeString(TxRlp.encodeBytes32(r));
        fields[12] = TxRlp.encodeString(TxRlp.encodeBytes32(s));

        bytes memory rlpPayload = TxRlp.encodeRawList(fields);
        return abi.encodePacked(TX_TYPE, rlpPayload);
    }

    /// @notice Computes the authorization hash for signing.
    /// @dev Hash: keccak256(0x05 || RLP([chainId, codeAddress, nonce]))
    function computeAuthorizationHash(uint256 chainId, address codeAddress, uint64 authNonce)
        internal
        pure
        returns (bytes32)
    {
        bytes[] memory fields = new bytes[](3);
        fields[0] = TxRlp.encodeString(TxRlp.encodeUint(chainId));
        fields[1] = TxRlp.encodeString(TxRlp.encodeAddress(codeAddress));
        fields[2] = TxRlp.encodeString(TxRlp.encodeUint(authNonce));

        bytes memory rlpPayload = TxRlp.encodeRawList(fields);
        return keccak256(abi.encodePacked(AUTH_MAGIC, rlpPayload));
    }

    /// @notice Encodes the access list as an RLP list.
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
            itemFields[1] = keysList;
            encodedItems[i] = TxRlp.encodeRawList(itemFields);
        }
        return TxRlp.encodeRawList(encodedItems);
    }

    /// @notice Encodes the authorization list as an RLP list.
    function _encodeAuthorizationList(Eip7702Authorization[] memory list) private pure returns (bytes memory) {
        bytes[] memory encodedAuths = new bytes[](list.length);
        for (uint256 i = 0; i < list.length; i++) {
            bytes[] memory authFields = new bytes[](6);
            authFields[0] = TxRlp.encodeString(TxRlp.encodeUint(list[i].chainId));
            authFields[1] = TxRlp.encodeString(TxRlp.encodeAddress(list[i].codeAddress));
            authFields[2] = TxRlp.encodeString(TxRlp.encodeUint(list[i].nonce));
            authFields[3] = TxRlp.encodeString(TxRlp.encodeUint(list[i].yParity));
            authFields[4] = TxRlp.encodeString(TxRlp.encodeBytes32(list[i].r));
            authFields[5] = TxRlp.encodeString(TxRlp.encodeBytes32(list[i].s));
            encodedAuths[i] = TxRlp.encodeRawList(authFields);
        }
        return TxRlp.encodeRawList(encodedAuths);
    }
}
