// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

import {SignatureLib} from "../src/sig/SignatureLib.sol";
import {VM_ADDRESS, VmSign} from "../src/StdVm.sol";

/// @notice Regression tests for `SignatureLib.encodeSecp` / `flipV` parity handling.
///
/// `encodeSecp` accepts `v` in either convention: `27/28` (EIP-155 style, returned by
/// Foundry's `vm.sign`) or `0/1` (y-parity style, returned by alloy signers). When `s`
/// is in high form and must be negated, `flipV` must flip the recovery parity while
/// preserving the caller's convention. These tests lock in that behavior for both
/// conventions, in both low-s and high-s form.
contract SignatureLibFlipVTest {
    uint256 internal constant PK = 0xA11CE;

    using SignatureLib for bytes32;

    struct Sig {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /// Finds a digest whose signature has the requested v (27 or 28).
    function _signWithV(uint8 target) internal pure returns (bytes32 digest, Sig memory sig) {
        digest = bytes32(uint256(1));
        while (true) {
            (sig.v, sig.r, sig.s) = VmSign(VM_ADDRESS).sign(PK, digest);
            if (sig.v == target) break;
            digest = keccak256(abi.encodePacked(digest));
        }
    }

    function _decode(bytes memory blob) private pure returns (bytes32 sNorm, uint8 vBlob) {
        assembly {
            sNorm := mload(add(blob, 64))
            vBlob := byte(0, mload(add(blob, 96)))
        }
    }

    /// ecrecover only accepts 27/28; map a parity-convention v for the check.
    function _vEff(uint8 v) private pure returns (uint8) {
        return v >= 27 ? v : v + 27;
    }

    /// @notice Low-s signatures pass `v` through unchanged in both conventions.
    function test_encodeSecp_lowS_passthrough() public pure {
        (bytes32 digest, Sig memory sig) = _signWithV(27);
        address signer = VmSign(VM_ADDRESS).addr(PK);

        bytes memory blob27 = SignatureLib.encodeSecp(sig.r, sig.s, 27);
        (, uint8 v27) = _decode(blob27);
        require(v27 == 27, "27 passthrough");
        require(ecrecover(digest, v27, sig.r, sig.s) == signer, "27 recovers");

        bytes memory blob0 = SignatureLib.encodeSecp(sig.r, sig.s, 0);
        (, uint8 v0) = _decode(blob0);
        require(v0 == 0, "0 passthrough");
        require(ecrecover(digest, _vEff(v0), sig.r, sig.s) == signer, "0 recovers");
    }

    /// @notice High-s with EIP-155 convention: flipV(27)=28 / flipV(28)=27 (existing behavior).
    function test_encodeSecp_highS_eip155Convention() public pure {
        (bytes32 digest, Sig memory sig) = _signWithV(27);
        address signer = VmSign(VM_ADDRESS).addr(PK);
        bytes32 sHigh = bytes32(SignatureLib.SECP256K1_N - uint256(sig.s));

        bytes memory blob = SignatureLib.encodeSecp(sig.r, sHigh, 28);
        (bytes32 sNorm, uint8 vBlob) = _decode(blob);
        require(sNorm == sig.s, "s normalized");
        require(vBlob == 27, "flipV(28) = 27");
        require(ecrecover(digest, vBlob, sig.r, sNorm) == signer, "recovers signer");
    }

    /// @notice High-s with y-parity convention v=0: negating s must flip parity 0 -> 1.
    /// On the pre-fix `flipV`, v=0 mapped to 27 (parity 0) and the blob recovered a
    /// different address than the signer.
    function test_encodeSecp_highS_parityConvention_v0() public pure {
        (bytes32 digest, Sig memory sig) = _signWithV(28);
        address signer = VmSign(VM_ADDRESS).addr(PK);
        // (v=28, s_low) == (parity 0, s_high): same signature, parity convention.
        bytes32 sHigh = bytes32(SignatureLib.SECP256K1_N - uint256(sig.s));

        bytes memory blob = SignatureLib.encodeSecp(sig.r, sHigh, 0);
        (bytes32 sNorm, uint8 vBlob) = _decode(blob);
        require(sNorm == sig.s, "s normalized");
        // Parity must be flipped to 1 (either as 1 or 28) for the low-s form.
        require(vBlob == 1 || vBlob == 28, "parity flipped to 1");
        require(ecrecover(digest, _vEff(vBlob), sig.r, sNorm) == signer, "recovers signer");
    }

    /// @notice High-s with y-parity convention v=1: negating s must flip parity 1 -> 0.
    function test_encodeSecp_highS_parityConvention_v1() public pure {
        (bytes32 digest, Sig memory sig) = _signWithV(27);
        address signer = VmSign(VM_ADDRESS).addr(PK);
        // (v=27, s_low) == (parity 1, s_high).
        bytes32 sHigh = bytes32(SignatureLib.SECP256K1_N - uint256(sig.s));

        bytes memory blob = SignatureLib.encodeSecp(sig.r, sHigh, 1);
        (bytes32 sNorm, uint8 vBlob) = _decode(blob);
        require(sNorm == sig.s, "s normalized");
        require(vBlob == 0 || vBlob == 27, "parity flipped to 0");
        require(ecrecover(digest, _vEff(vBlob), sig.r, sNorm) == signer, "recovers signer");
    }
}
