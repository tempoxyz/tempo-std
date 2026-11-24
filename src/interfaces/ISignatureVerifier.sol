// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

/// @title ISignatureVerifier
/// @notice Interface for the TIP-1020 Signature Verification Precompile
/// @dev Deployed at 0x5165300000000000000000000000000000000000
interface ISignatureVerifier {
    /// @notice Thrown when the signature bytes are not in the expected encoding format
    error InvalidFormat();
    /// @notice Thrown when the signature verification fails
    error InvalidSignature();

    /// @notice Recovers the signer of a Tempo signature (secp256k1, P256, WebAuthn).
    /// @param hash The message hash that was signed
    /// @param signature The encoded signature (see Tempo Transaction spec for formats)
    /// @return signer Address of the signer if valid, reverts otherwise
    /// @dev Only says which key signed: a migrated account's retired root key still recovers to
    /// its address (TIP-1113). Use `verify` to check whether an account approves a hash.
    function recover(bytes32 hash, bytes calldata signature) external view returns (address signer);

    /// @notice Checks whether account approves hash: the one check to use for any account
    /// and signature type. It follows the account's current state, so it stays correct when
    /// the account migrates or changes owners (TIP-1168). By signature type:
    /// - primitive: recovers to account, and account has no configuration commitment
    /// - keychain: same as `verifyKeychainAdmin`
    /// - configurable account: same as `verifyConfigurableAccount`
    /// @param account The account expected to approve
    /// @param hash The message hash that was signed
    /// @param signature A primitive, keychain or configurable account signature
    /// @dev Before T15, only checks that a primitive signature recovers to account.
    /// @return True if account approves hash. Reverts on malformed or invalid signatures.
    function verify(address account, bytes32 hash, bytes calldata signature) external view returns (bool);

    /// @notice Verifies whether a keychain signature was produced by an active key (TIP-1049, T6).
    /// @param account The expected embedded root account
    /// @param hash The message hash that was signed
    /// @param signature The encoded keychain signature
    /// @dev Does not compare the inner signature type against the stored key type.
    /// @dev Selector-gated to the T6 hardfork; reverts as an unknown selector before T6.
    /// @return True if the keychain access key is active on account.
    function verifyKeychain(address account, bytes32 hash, bytes calldata signature) external view returns (bool);

    /// @notice Verifies whether a keychain signature was produced by a root or active admin key (TIP-1049, T6).
    /// @param account The expected embedded root account
    /// @param hash The message hash that was signed
    /// @param signature The encoded keychain signature
    /// @dev Does not compare the inner signature type against the stored key type.
    /// @dev Selector-gated to the T6 hardfork; reverts as an unknown selector before T6.
    /// @return True if the recovered key is account or an active admin key on account.
    function verifyKeychainAdmin(address account, bytes32 hash, bytes calldata signature) external view returns (bool);

    /// @notice Verifies a configurable account signature against current account state (TIP-1107, T14).
    /// @param account The configurable account expected to approve
    /// @param hash The message hash that was signed
    /// @param signature The encoded configurable account signature
    /// @dev Selector-gated to the T14 hardfork; reverts as an unknown selector before T14.
    /// @return True if the owner quorum approves hash for account under its current configuration,
    /// false for an account or configuration mismatch. Reverts for malformed or invalid approvals.
    function verifyConfigurableAccount(address account, bytes32 hash, bytes calldata signature)
        external
        view
        returns (bool);
}
