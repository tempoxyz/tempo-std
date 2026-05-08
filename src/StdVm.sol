// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

// The standard Foundry Vm cheatcode address.
// `address(uint160(uint256(keccak256("hevm cheat code"))))`.
address constant VM_ADDRESS = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;

/// @title Minimal Vm interface for signing cheatcodes.
/// @dev Used by SignatureLib to produce test signatures.
interface VmSign {
    /// @notice Signs `digest` with secp256k1 private key `privateKey`.
    function sign(uint256 privateKey, bytes32 digest) external pure returns (uint8 v, bytes32 r, bytes32 s);

    /// @notice Signs `digest` with NIST-P256 private key `privateKey`.
    function signP256(uint256 privateKey, bytes32 digest) external pure returns (bytes32 r, bytes32 s);

    /// @notice Derives the secp256k1 address from `privateKey`.
    function addr(uint256 privateKey) external pure returns (address keyAddr);
}

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
