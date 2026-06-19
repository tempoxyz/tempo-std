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
    function recover(bytes32 hash, bytes calldata signature) external view returns (address signer);

    /// @notice Verifies a signer against a Tempo signature (secp256k1, P256, WebAuthn).
    /// @param signer The input address verified against the recovered signer
    /// @param hash The message hash that was signed
    /// @param signature The encoded signature (see Tempo Transaction spec for formats)
    /// @return True if the input address signed, false otherwise. Reverts on invalid signatures.
    function verify(address signer, bytes32 hash, bytes calldata signature) external view returns (bool);

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
    function verifyKeychainAdmin(address account, bytes32 hash, bytes calldata signature)
        external
        view
        returns (bool);
}
