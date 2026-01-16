// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

import {VmRlp} from "../StdVm.sol";
import {TxRlp} from "./TxRlp.sol";
import {AccessListItem} from "./AccessListTypes.sol";

/// @notice An EIP-1559 (type 2) Ethereum transaction.
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

/// @title Builder and RLP encoder for EIP-1559 transactions (type 0x02).
library Eip1559TransactionLib {
    using Eip1559TransactionLib for Eip1559Transaction;

    /// @notice EIP-1559 transaction type prefix.
    uint8 internal constant TX_TYPE = 0x02;

    /// @notice Creates a new EIP-1559 transaction with default values.
    function create() internal view returns (Eip1559Transaction memory tx_) {
        tx_.chainId = uint64(block.chainid);
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

    /// @notice Sets the value to send.
    function withValue(Eip1559Transaction memory self, uint256 value)
        internal
        pure
        returns (Eip1559Transaction memory)
    {
        self.value = value;
        return self;
    }

    /// @notice Sets the calldata.
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

    /// @notice RLP encodes the unsigned transaction with type prefix 0x02.
    /// @dev Format: 0x02 || RLP([chainId, nonce, maxPriorityFeePerGas, maxFeePerGas, gasLimit, to, value, data, accessList])
    function encode(Eip1559Transaction memory self, VmRlp) internal pure returns (bytes memory) {
        bytes[] memory fields = new bytes[](9);

        fields[0] = TxRlp.encodeString(TxRlp.encodeUint(self.chainId));
        fields[1] = TxRlp.encodeString(TxRlp.encodeUint(self.nonce));
        fields[2] = TxRlp.encodeString(TxRlp.encodeUint(self.maxPriorityFeePerGas));
        fields[3] = TxRlp.encodeString(TxRlp.encodeUint(self.maxFeePerGas));
        fields[4] = TxRlp.encodeString(TxRlp.encodeUint(self.gasLimit));
        fields[5] = TxRlp.encodeString(self.to == address(0) ? TxRlp.encodeNone() : TxRlp.encodeAddress(self.to));
        fields[6] = TxRlp.encodeString(TxRlp.encodeUint(self.value));
        fields[7] = TxRlp.encodeString(self.data);
        fields[8] = _encodeAccessList(self.accessList);

        bytes memory rlpPayload = TxRlp.encodeRawList(fields);
        return abi.encodePacked(TX_TYPE, rlpPayload);
    }

    /// @notice RLP encodes the signed transaction with type prefix 0x02.
    /// @dev Format: 0x02 || RLP([chainId, nonce, maxPriorityFeePerGas, maxFeePerGas, gasLimit, to, value, data, accessList, yParity, r, s])
    function encodeWithSignature(Eip1559Transaction memory self, VmRlp, uint8 v, bytes32 r, bytes32 s)
        internal
        pure
        returns (bytes memory)
    {
        bytes[] memory fields = new bytes[](12);

        fields[0] = TxRlp.encodeString(TxRlp.encodeUint(self.chainId));
        fields[1] = TxRlp.encodeString(TxRlp.encodeUint(self.nonce));
        fields[2] = TxRlp.encodeString(TxRlp.encodeUint(self.maxPriorityFeePerGas));
        fields[3] = TxRlp.encodeString(TxRlp.encodeUint(self.maxFeePerGas));
        fields[4] = TxRlp.encodeString(TxRlp.encodeUint(self.gasLimit));
        fields[5] = TxRlp.encodeString(self.to == address(0) ? TxRlp.encodeNone() : TxRlp.encodeAddress(self.to));
        fields[6] = TxRlp.encodeString(TxRlp.encodeUint(self.value));
        fields[7] = TxRlp.encodeString(self.data);
        fields[8] = _encodeAccessList(self.accessList);

        // yParity: 0 or 1 (v - 27)
        uint8 yParity = v >= 27 ? v - 27 : v;
        fields[9] = TxRlp.encodeString(TxRlp.encodeUint(yParity));
        fields[10] = TxRlp.encodeString(TxRlp.encodeBytes32(r));
        fields[11] = TxRlp.encodeString(TxRlp.encodeBytes32(s));

        bytes memory rlpPayload = TxRlp.encodeRawList(fields);
        return abi.encodePacked(TX_TYPE, rlpPayload);
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
}
