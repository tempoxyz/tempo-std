// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

/// @title Current Committee Precompile
/// @notice Exposes the effective committee selected by consensus for the current epoch.
/// @dev Deployed at `StdPrecompiles.CURRENT_COMMITTEE_ADDRESS` from T8.
interface ICurrentCommittee {
    /// @notice Thrown when a non-system caller attempts to update the committee.
    error Unauthorized();

    /// @notice Returns the current effective committee selected from the canonical DKG outcome.
    /// @return epoch Epoch for which the committee is effective.
    /// @return publicKeys Ordered Ed25519 public keys from the selected DKG outcome.
    function getCommitteeMembers() external view returns (uint64 epoch, bytes32[] memory publicKeys);

    /// @notice Replaces the current committee record.
    /// @dev System-only entrypoint used by protocol block processing.
    /// @param epoch Epoch for which the committee is effective.
    /// @param publicKeys Ordered Ed25519 public keys from the selected DKG outcome.
    function setCommitteeMembers(uint64 epoch, bytes32[] calldata publicKeys) external;
}
