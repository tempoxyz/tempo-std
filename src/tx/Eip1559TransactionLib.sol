// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {VmRlp} from "../StdVm.sol";
import {TxRlp} from "./TxRlp.sol";
import {AccessListItem} from "./AccessListTypes.sol";

/// @notice An EIP-1559 (type 2) transaction.
struct Eip1559Transaction {
    uint64 chainId;
    uint64 nonce;
    uint256 maxPriorityFeePerGas;
    uint256 maxFeePerGas;
    uint64 gasLimit;
    address to;
    uint256 value;
    bytes data;
    AccessListItem[] accessList;
}

/// @title Builder and RLP encoder for EIP-1559 transactions.
library Eip1559TransactionLib {
    using Eip1559TransactionLib for Eip1559Transaction;

    /// @notice EIP-1559 transaction type prefix.
    uint8 internal constant TX_TYPE = 0x02;

    /// @notice Creates a new EIP-1559 transaction with default values.
    function create() internal pure returns (Eip1559Transaction memory tx_) {
        tx_.gasLimit = 21000;
    }

    /// @notice Sets the chain ID.
    function withChainId(Eip1559Transaction memory self, uint64 chainId)
        internal
        pure
        returns (Eip1559Transaction memory)
    {
        self.chainId = chainId;
        return self;
    }

    /// @notice Sets the nonce.
    function withNonce(Eip1559Transaction memory self, uint64 nonce) internal pure returns (Eip1559Transaction memory) {
        self.nonce = nonce;
        return self;
    }

    /// @notice Sets the max priority fee per gas.
    function withMaxPriorityFeePerGas(Eip1559Transaction memory self, uint256 fee)
        internal
        pure
        returns (Eip1559Transaction memory)
    {
        self.maxPriorityFeePerGas = fee;
        return self;
    }

    /// @notice Sets the max fee per gas.
    function withMaxFeePerGas(Eip1559Transaction memory self, uint256 fee)
        internal
        pure
        returns (Eip1559Transaction memory)
    {
        self.maxFeePerGas = fee;
        return self;
    }

    /// @notice Sets the gas limit.
    function withGasLimit(Eip1559Transaction memory self, uint64 gasLimit)
        internal
        pure
        returns (Eip1559Transaction memory)
    {
        self.gasLimit = gasLimit;
        return self;
    }

    /// @notice Sets the recipient address.
    function withTo(Eip1559Transaction memory self, address to) internal pure returns (Eip1559Transaction memory) {
        self.to = to;
        return self;
    }

    /// @notice Sets the value to transfer.
    function withValue(Eip1559Transaction memory self, uint256 value)
        internal
        pure
        returns (Eip1559Transaction memory)
    {
        self.value = value;
        return self;
    }

    /// @notice Sets the call data.
    function withData(Eip1559Transaction memory self, bytes memory data)
        internal
        pure
        returns (Eip1559Transaction memory)
    {
        self.data = data;
        return self;
    }

    /// @notice Sets the access list.
    function withAccessList(Eip1559Transaction memory self, AccessListItem[] memory accessList)
        internal
        pure
        returns (Eip1559Transaction memory)
    {
        self.accessList = accessList;
        return self;
    }

    /// @notice RLP encodes the unsigned transaction with type prefix.
    /// @dev Format: 0x02 || RLP([chainId, nonce, maxPriorityFeePerGas, maxFeePerGas, gasLimit, to, value, data, accessList])
    function encode(Eip1559Transaction memory self, VmRlp vm) internal pure returns (bytes memory) {
        bytes[] memory fields = new bytes[](9);
        fields[0] = TxRlp.encodeUint(self.chainId);
        fields[1] = TxRlp.encodeUint(self.nonce);
        fields[2] = TxRlp.encodeUint(self.maxPriorityFeePerGas);
        fields[3] = TxRlp.encodeUint(self.maxFeePerGas);
        fields[4] = TxRlp.encodeUint(self.gasLimit);
        fields[5] = TxRlp.encodeAddress(self.to);
        fields[6] = TxRlp.encodeUint(self.value);
        fields[7] = self.data;
        fields[8] = encodeAccessList(vm, self.accessList);

        bytes memory rlpPayload = TxRlp.encodeList(vm, fields);
        return abi.encodePacked(TX_TYPE, rlpPayload);
    }

    /// @notice RLP encodes the signed transaction with type prefix.
    /// @dev Format: 0x02 || RLP([chainId, nonce, maxPriorityFeePerGas, maxFeePerGas, gasLimit, to, value, data, accessList, yParity, r, s])
    function encodeWithSignature(Eip1559Transaction memory self, VmRlp vm, uint8 yParity, bytes32 r, bytes32 s)
        internal
        pure
        returns (bytes memory)
    {
        bytes[] memory fields = new bytes[](12);
        fields[0] = TxRlp.encodeUint(self.chainId);
        fields[1] = TxRlp.encodeUint(self.nonce);
        fields[2] = TxRlp.encodeUint(self.maxPriorityFeePerGas);
        fields[3] = TxRlp.encodeUint(self.maxFeePerGas);
        fields[4] = TxRlp.encodeUint(self.gasLimit);
        fields[5] = TxRlp.encodeAddress(self.to);
        fields[6] = TxRlp.encodeUint(self.value);
        fields[7] = self.data;
        fields[8] = encodeAccessList(vm, self.accessList);
        fields[9] = TxRlp.encodeUint(yParity);
        fields[10] = TxRlp.encodeBytes32(r);
        fields[11] = TxRlp.encodeBytes32(s);

        bytes memory rlpPayload = TxRlp.encodeList(vm, fields);
        return abi.encodePacked(TX_TYPE, rlpPayload);
    }

    /// @notice Encodes an access list as RLP.
    /// @dev Each item is encoded as [address, [storageKey1, storageKey2, ...]].
    function encodeAccessList(VmRlp vm, AccessListItem[] memory list) internal pure returns (bytes memory) {
        bytes[] memory encodedItems = new bytes[](list.length);

        for (uint256 i = 0; i < list.length; i++) {
            AccessListItem memory item = list[i];

            // Encode storage keys as a list
            bytes[] memory encodedKeys = new bytes[](item.storageKeys.length);
            for (uint256 j = 0; j < item.storageKeys.length; j++) {
                encodedKeys[j] = TxRlp.encodeBytes32Full(item.storageKeys[j]);
            }
            bytes memory keysList = TxRlp.encodeList(vm, encodedKeys);

            // Encode [address, [keys...]]
            bytes[] memory tuple = new bytes[](2);
            tuple[0] = TxRlp.encodeAddress(item.target);
            tuple[1] = keysList;
            encodedItems[i] = TxRlp.encodeList(vm, tuple);
        }

        return TxRlp.encodeList(vm, encodedItems);
    }
}
