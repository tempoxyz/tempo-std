// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

import {Test} from "forge-std/Test.sol";
import {SignatureLib} from "../src/sig/SignatureLib.sol";

contract SignatureLibTest is Test {
    function test_flipV_standardConventions() public pure {
        // Standard Ethereum 27/28 parity convention
        assertEq(SignatureLib.flipV(27), 28, "27 should flip to 28");
        assertEq(SignatureLib.flipV(28), 27, "28 should flip to 27");

        // Raw 0/1 parity convention
        assertEq(SignatureLib.flipV(0), 1, "0 should flip to 1");
        assertEq(SignatureLib.flipV(1), 0, "1 should flip to 0");

        // Unrecognized values should remain untouched
        assertEq(SignatureLib.flipV(4), 4, "Unrecognized v should not mutate");
        assertEq(SignatureLib.flipV(37), 37, "EIP-155 style v should not coerce to 27");
    }

    function test_encodeSecp_flipsVOnHighS() public pure {
        bytes32 r = bytes32(uint256(0x1234));
        // s greater than SECP256K1_N_HALF
        bytes32 highS = bytes32(SignatureLib.SECP256K1_N_HALF + 1);

        // Case 1: v = 27 should become 28
        bytes memory encoded27 = SignatureLib.encodeSecp(r, highS, 27);
        assertEq(uint8(encoded27[64]), 28, "v=27 should flip to 28 when high-s is negated");

        // Case 2: v = 0 should become 1
        bytes memory encoded0 = SignatureLib.encodeSecp(r, highS, 0);
        assertEq(uint8(encoded0[64]), 1, "v=0 should flip to 1 when high-s is negated");
    }

    function test_encodeSecp_preservesVOnLowS() public pure {
        bytes32 r = bytes32(uint256(0x1234));
        // s already in canonical low-s form
        bytes32 lowS = bytes32(SignatureLib.SECP256K1_N_HALF - 1);

        bytes memory encoded27 = SignatureLib.encodeSecp(r, lowS, 27);
        assertEq(uint8(encoded27[64]), 27, "v=27 should remain unchanged for canonical low-s");

        bytes memory encoded0 = SignatureLib.encodeSecp(r, lowS, 0);
        assertEq(uint8(encoded0[64]), 0, "v=0 should remain unchanged for canonical low-s");
    }
}