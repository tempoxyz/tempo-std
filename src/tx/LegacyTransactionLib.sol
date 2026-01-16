// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

import {VmRlp} from "../StdVm.sol";
import {TxRlp} from "./TxRlp.sol";

/// @notice A legacy (type 0) Ethereum transaction.
struct LegacyTransaction {
    uint64 nonce;
    uint256 gasPrice;
    uint64 gasLimit;
    address to;
    uint256 value;
    bytes data;
}

/// @title Builder and RLP encoder for legacy Ethereum transactions.
library LegacyTransactionLib {
    using LegacyTransactionLib for LegacyTransaction;

    /// @notice Creates a new legacy transaction with default values.
    /// @dev Default gasLimit is 21000 (simple transfer).
    function create() internal pure returns (LegacyTransaction memory) {
        return LegacyTransaction({nonce: 0, gasPrice: 0, gasLimit: 21000, to: address(0), value: 0, data: ""});
    }

    /// @notice Sets the nonce.
    function withNonce(LegacyTransaction memory self, uint64 nonce) internal pure returns (LegacyTransaction memory) {
        self.nonce = nonce;
        return self;
    }

    /// @notice Sets the gas price.
    function withGasPrice(LegacyTransaction memory self, uint256 gasPrice)
        internal
        pure
        returns (LegacyTransaction memory)
    {
        self.gasPrice = gasPrice;
        return self;
    }

    /// @notice Sets the gas limit.
    function withGasLimit(LegacyTransaction memory self, uint64 gasLimit)
        internal
        pure
        returns (LegacyTransaction memory)
    {
        self.gasLimit = gasLimit;
        return self;
    }

    /// @notice Sets the recipient address.
    function withTo(LegacyTransaction memory self, address to) internal pure returns (LegacyTransaction memory) {
        self.to = to;
        return self;
    }

    /// @notice Sets the value to send.
    function withValue(LegacyTransaction memory self, uint256 value) internal pure returns (LegacyTransaction memory) {
        self.value = value;
        return self;
    }

    /// @notice Sets the calldata.
    function withData(LegacyTransaction memory self, bytes memory data)
        internal
        pure
        returns (LegacyTransaction memory)
    {
        self.data = data;
        return self;
    }

    /// @notice RLP encodes the unsigned transaction (6 fields).
    /// @dev Legacy transactions have no type prefix.
    function encode(LegacyTransaction memory self, VmRlp vm) internal pure returns (bytes memory) {
        bytes[] memory items = new bytes[](6);
        items[0] = TxRlp.encodeUint(self.nonce);
        items[1] = TxRlp.encodeUint(self.gasPrice);
        items[2] = TxRlp.encodeUint(self.gasLimit);
        items[3] = self.to == address(0) ? TxRlp.encodeNone() : TxRlp.encodeAddress(self.to);
        items[4] = TxRlp.encodeUint(self.value);
        items[5] = self.data;

        return TxRlp.encodeList(vm, items);
    }

    /// @notice RLP encodes the signed transaction (9 fields).
    /// @dev Legacy transactions have no type prefix.
    function encodeWithSignature(LegacyTransaction memory self, VmRlp vm, uint8 v, bytes32 r, bytes32 s)
        internal
        pure
        returns (bytes memory)
    {
        bytes[] memory items = new bytes[](9);
        items[0] = TxRlp.encodeUint(self.nonce);
        items[1] = TxRlp.encodeUint(self.gasPrice);
        items[2] = TxRlp.encodeUint(self.gasLimit);
        items[3] = self.to == address(0) ? TxRlp.encodeNone() : TxRlp.encodeAddress(self.to);
        items[4] = TxRlp.encodeUint(self.value);
        items[5] = self.data;
        items[6] = TxRlp.encodeUint(v);
        items[7] = TxRlp.encodeBytes32(r);
        items[8] = TxRlp.encodeBytes32(s);

        return TxRlp.encodeList(vm, items);
    }
}
