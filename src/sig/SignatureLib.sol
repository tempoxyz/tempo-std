// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

import {ISignatureVerifier} from "../interfaces/ISignatureVerifier.sol";
import {VM_ADDRESS, VmSign} from "../StdVm.sol";

/// @title Builders, encoders, and helpers for the TIP-1020 SignatureVerifier precompile.
/// @notice Produces the byte-packed signature blobs consumed by `0x5165...0000`.
/// @dev Wire formats (matching `crates/primitives/src/transaction/tt_signature.rs`):
///
///   - secp256k1: `r(32) || s(32) || v(1)`                        (65 bytes, no type prefix)
///   - P256:      `0x01 || r(32) || s(32) || pubX(32) || pubY(32) || preHash(1)`   (130 bytes)
///   - WebAuthn:  `0x02 || webauthnData || r(32) || s(32) || pubX(32) || pubY(32)` (>= 198 bytes)
///
/// Keychain prefixes (`0x03`, `0x04`) are intentionally NOT supported here: the
/// SignatureVerifier precompile rejects them. Use the AccountKeychain precompile
/// for keychain flows.
///
/// All ECDSA signatures are normalized to low-s form, matching the precompile's
/// canonical-form requirement.
library SignatureLib {
    /*//////////////////////////////////////////////////////////////
                                  CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Address of the TIP-1020 SignatureVerifier precompile.
    address internal constant SIGNATURE_VERIFIER_ADDRESS = 0x5165300000000000000000000000000000000000;

    /// @notice Type prefix for raw P256 signatures.
    uint8 internal constant TYPE_P256 = 0x01;
    /// @notice Type prefix for WebAuthn signatures.
    uint8 internal constant TYPE_WEBAUTHN = 0x02;

    /// @notice secp256k1 group order `n`.
    uint256 internal constant SECP256K1_N = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;
    /// @notice `floor(n/2)` for secp256k1 (low-s threshold).
    uint256 internal constant SECP256K1_N_HALF = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0;

    /// @notice NIST P-256 group order `n`.
    uint256 internal constant P256_N = 0xFFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551;
    /// @notice `floor(n/2)` for P-256 (low-s threshold).
    uint256 internal constant P256_N_HALF = 0x7FFFFFFF800000007FFFFFFFFFFFFFFFDE737D56D38BCF4279DCE5617E3192A8;

    /// @notice WebAuthn authenticatorData flag bits.
    uint8 internal constant WEBAUTHN_FLAG_UP = 0x01; // user present
    uint8 internal constant WEBAUTHN_FLAG_UV = 0x04; // user verified

    /*//////////////////////////////////////////////////////////////
                              LOW-S NORMALIZATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the low-s form for a secp256k1 signature `s` value.
    function normalizeSecpS(bytes32 s) internal pure returns (bytes32) {
        uint256 sVal = uint256(s);
        return sVal > SECP256K1_N_HALF ? bytes32(SECP256K1_N - sVal) : s;
    }

    /// @notice Returns the low-s form for a P-256 signature `s` value.
    function normalizeP256S(bytes32 s) internal pure returns (bytes32) {
        uint256 sVal = uint256(s);
        return sVal > P256_N_HALF ? bytes32(P256_N - sVal) : s;
    }

    /// @notice Flips `v` (27 -> 28 / 28 -> 27) when `s` had to be negated.
    function flipV(uint8 v) internal pure returns (uint8) {
        return v == 27 ? 28 : 27;
    }

    /*//////////////////////////////////////////////////////////////
                                   ENCODERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Encodes a secp256k1 signature in the precompile's wire format.
    /// @dev `r || s || v`, 65 bytes, no type prefix. `s` is normalized to low-s.
    function encodeSecp(bytes32 r, bytes32 s, uint8 v) internal pure returns (bytes memory) {
        bytes32 sNorm = normalizeSecpS(s);
        if (sNorm != s) v = flipV(v);
        return abi.encodePacked(r, sNorm, v);
    }

    /// @notice Encodes a P256 signature with `preHash = false`.
    function encodeP256(bytes32 r, bytes32 s, bytes32 pubX, bytes32 pubY) internal pure returns (bytes memory) {
        return encodeP256(r, s, pubX, pubY, false);
    }

    /// @notice Encodes a P256 signature in the precompile's wire format.
    /// @dev `0x01 || r || s || pubX || pubY || preHash`. `s` is normalized to low-s.
    /// @param preHash When true, the precompile sha256-hashes the input digest before P256
    ///                verification. Used for environments that pre-hash (e.g. Web Crypto).
    function encodeP256(bytes32 r, bytes32 s, bytes32 pubX, bytes32 pubY, bool preHash)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(TYPE_P256, r, normalizeP256S(s), pubX, pubY, preHash ? uint8(1) : uint8(0));
    }

    /// @notice Encodes a WebAuthn signature in the precompile's wire format.
    /// @dev `0x02 || webauthnData || r || s || pubX || pubY`. `s` is normalized to low-s.
    /// @param webauthnData The concatenation of `authenticatorData || clientDataJSON`.
    function encodeWebAuthn(bytes memory webauthnData, bytes32 r, bytes32 s, bytes32 pubX, bytes32 pubY)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(TYPE_WEBAUTHN, webauthnData, r, normalizeP256S(s), pubX, pubY);
    }

    /*//////////////////////////////////////////////////////////////
                            P256 ADDRESS DERIVATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Derives a Tempo P256/WebAuthn address from public key coordinates.
    /// @dev Matches `derive_p256_address` in the precompile: `keccak256(pubX || pubY)[12:]`.
    function p256Address(bytes32 pubX, bytes32 pubY) internal pure returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(pubX, pubY)))));
    }

    /*//////////////////////////////////////////////////////////////
                              WEBAUTHN HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Builds a minimal `authenticatorData || clientDataJSON` blob suitable for
    ///         the precompile's WebAuthn validator.
    /// @dev `authData = sha256(rpId) || flags(0x01: UP) || signCount(0x00000000)` (37 bytes).
    ///      `clientDataJSON = {"type":"webauthn.get","challenge":"<base64url(challenge)>",
    ///                         "origin":"<origin>"}`.
    /// @param challenge The 32-byte challenge (typically the tx hash).
    /// @param rpId      The relying party id (e.g. "localhost").
    /// @param origin    The origin string (e.g. "https://localhost").
    function buildWebAuthnData(bytes32 challenge, string memory rpId, string memory origin)
        internal
        pure
        returns (bytes memory)
    {
        bytes32 rpIdHash = sha256(bytes(rpId));
        bytes memory authData = abi.encodePacked(rpIdHash, WEBAUTHN_FLAG_UP, bytes4(0));
        string memory challengeB64 = base64UrlEncode(abi.encodePacked(challenge));
        bytes memory clientDataJSON = bytes.concat(
            bytes('{"type":"webauthn.get","challenge":"'),
            bytes(challengeB64),
            bytes('","origin":"'),
            bytes(origin),
            bytes('"}')
        );
        return bytes.concat(authData, clientDataJSON);
    }

    /// @notice Computes the P256 message hash signed by a WebAuthn assertion.
    /// @dev `sha256(authenticatorData || sha256(clientDataJSON))`.
    function webAuthnMessageHash(bytes memory webauthnData) internal pure returns (bytes32) {
        // First 37 bytes are authenticatorData (no extensions, since the precompile rejects ED).
        require(webauthnData.length >= 37, "SignatureLib: webauthnData too short");
        bytes memory authData = new bytes(37);
        bytes memory clientDataJSON = new bytes(webauthnData.length - 37);
        for (uint256 i = 0; i < 37; i++) {
            authData[i] = webauthnData[i];
        }
        for (uint256 i = 0; i < clientDataJSON.length; i++) {
            clientDataJSON[i] = webauthnData[37 + i];
        }
        return sha256(abi.encodePacked(authData, sha256(clientDataJSON)));
    }

    /// @notice Base64URL encodes `data` without padding (matches `URL_SAFE_NO_PAD`).
    function base64UrlEncode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";
        bytes memory table = bytes("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_");
        // No-pad output length: ceil(4n/3)
        uint256 outLen = (data.length * 4 + 2) / 3;
        bytes memory result = new bytes(outLen);
        uint256 j = 0;
        for (uint256 i = 0; i < data.length; i += 3) {
            uint256 a = uint8(data[i]);
            uint256 b = i + 1 < data.length ? uint8(data[i + 1]) : 0;
            uint256 c = i + 2 < data.length ? uint8(data[i + 2]) : 0;
            uint256 triple = (a << 16) | (b << 8) | c;
            result[j++] = table[(triple >> 18) & 0x3F];
            result[j++] = table[(triple >> 12) & 0x3F];
            if (i + 1 < data.length) result[j++] = table[(triple >> 6) & 0x3F];
            if (i + 2 < data.length) result[j++] = table[triple & 0x3F];
        }
        return string(result);
    }

    /*//////////////////////////////////////////////////////////////
                               TEST-MODE SIGNERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Signs `hash` with a secp256k1 key via Foundry cheatcodes and returns the
    ///         encoded 65-byte signature blob.
    function signSecp(uint256 privateKey, bytes32 hash) internal pure returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = VmSign(VM_ADDRESS).sign(privateKey, hash);
        return encodeSecp(r, s, v);
    }

    /// @notice Signs `hash` with a P256 key via Foundry cheatcodes and returns the
    ///         encoded P256 signature blob (`preHash = false`).
    function signP256(uint256 privateKey, bytes32 hash, bytes32 pubX, bytes32 pubY)
        internal
        pure
        returns (bytes memory)
    {
        (bytes32 r, bytes32 s) = VmSign(VM_ADDRESS).signP256(privateKey, hash);
        return encodeP256(r, s, pubX, pubY, false);
    }

    /// @notice Builds a default WebAuthn assertion for `challenge` (rpId="localhost",
    ///         origin="https://localhost") and signs it with a P256 key.
    function signWebAuthn(uint256 privateKey, bytes32 challenge, bytes32 pubX, bytes32 pubY)
        internal
        pure
        returns (bytes memory)
    {
        return signWebAuthn(privateKey, challenge, pubX, pubY, "localhost", "https://localhost");
    }

    /// @notice Builds a WebAuthn assertion for `challenge` and signs it with a P256 key.
    function signWebAuthn(
        uint256 privateKey,
        bytes32 challenge,
        bytes32 pubX,
        bytes32 pubY,
        string memory rpId,
        string memory origin
    ) internal pure returns (bytes memory) {
        bytes memory webauthnData = buildWebAuthnData(challenge, rpId, origin);
        bytes32 messageHash = webAuthnMessageHash(webauthnData);
        (bytes32 r, bytes32 s) = VmSign(VM_ADDRESS).signP256(privateKey, messageHash);
        return encodeWebAuthn(webauthnData, r, s, pubX, pubY);
    }

    /*//////////////////////////////////////////////////////////////
                              CALL CONVENIENCES
    //////////////////////////////////////////////////////////////*/

    /// @notice Calls `recover` on the SignatureVerifier precompile.
    function recover(bytes32 hash, bytes memory signature) internal view returns (address) {
        return ISignatureVerifier(SIGNATURE_VERIFIER_ADDRESS).recover(hash, signature);
    }

    /// @notice Calls `verify` on the SignatureVerifier precompile.
    function verify(address signer, bytes32 hash, bytes memory signature) internal view returns (bool) {
        return ISignatureVerifier(SIGNATURE_VERIFIER_ADDRESS).verify(signer, hash, signature);
    }
}
