// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

/// @title Minimal Vm interface for RLP encoding.
interface VmRlp {
    /// @notice RLP encodes a list of byte strings into an RLP list payload.
    function toRlp(bytes[] calldata data) external pure returns (bytes memory);
}

/// @title Minimal Vm interface for transaction execution.
interface VmExecuteTransaction {
    /// @notice Executes an RLP-encoded transaction with full EVM semantics.
    /// @dev Decodes using TempoTxEnvelope::decode() which auto-detects tx type.
    /// @param rawTx The RLP-encoded transaction bytes.
    /// @return The execution output bytes.
    function executeTransaction(bytes calldata rawTx) external returns (bytes memory);
}
