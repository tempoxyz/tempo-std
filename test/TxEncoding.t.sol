// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

import {TxRlp} from "../src/tx/TxRlp.sol";
import {VmRlp, VM_ADDRESS} from "../src/StdVm.sol";
import {Eip1559Transaction, Eip1559TransactionLib} from "../src/tx/Eip1559TransactionLib.sol";
import {Eip7702Transaction, Eip7702Authorization, Eip7702TransactionLib} from "../src/tx/Eip7702TransactionLib.sol";

/// @notice Tests for the transaction RLP encoders.
/// @dev Expected values for the EIP-1559 and EIP-7702 cases are produced by an
///      independent reference encoder (viem `serializeTransaction`), so these
///      lock the byte-for-byte wire format, not just self-consistency.
contract TxEncodingTest {
    using Eip1559TransactionLib for Eip1559Transaction;
    using Eip7702TransactionLib for Eip7702Transaction;

    VmRlp internal constant VM = VmRlp(VM_ADDRESS);

    function _eq(bytes memory a, bytes memory b) private pure returns (bool) {
        return keccak256(a) == keccak256(b);
    }

    /*//////////////////////////////////////////////////////////////
                              TxRlp PRIMITIVES
    //////////////////////////////////////////////////////////////*/

    function testEncodeUintMinimal() public pure {
        require(TxRlp.encodeUint(0).length == 0, "0 -> empty");
        require(_eq(TxRlp.encodeUint(0x7f), hex"7f"), "127");
        require(_eq(TxRlp.encodeUint(0x80), hex"80"), "128");
        require(_eq(TxRlp.encodeUint(0x0102), hex"0102"), "no leading zeros");
        require(
            _eq(
                TxRlp.encodeUint(type(uint256).max),
                hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
            ),
            "max"
        );
    }

    function testEncodeStringCanonical() public pure {
        // Single byte < 0x80 is its own encoding.
        require(_eq(TxRlp.encodeString(hex"7f"), hex"7f"), "0x7f");
        // Single byte >= 0x80 gets a 0x81 prefix.
        require(_eq(TxRlp.encodeString(hex"80"), hex"8180"), "0x80");
        // Single zero byte is a 1-byte string, not empty.
        require(_eq(TxRlp.encodeString(hex"00"), hex"00"), "0x00");
        // Empty string -> 0x80.
        require(_eq(TxRlp.encodeString(""), hex"80"), "empty");
        // "dog" -> 0x83 || "dog".
        require(_eq(TxRlp.encodeString(hex"646f67"), hex"83646f67"), "dog");
    }

    function testEncodeStringLongForm() public pure {
        // 56 bytes crosses the 55-byte short-string boundary: 0xb7+1 (0xb8), len (0x38), payload.
        bytes memory payload = new bytes(56);
        for (uint256 i = 0; i < 56; i++) {
            payload[i] = 0x61; // 'a'
        }
        bytes memory got = TxRlp.encodeString(payload);
        require(got.length == 58, "prefix + len + 56");
        require(uint8(got[0]) == 0xb8 && uint8(got[1]) == 0x38, "long-string header");
    }

    function testEncodeRawList() public pure {
        // ["cat", "dog"] -> 0xc8 || 0x83cat || 0x83dog.
        bytes[] memory items = new bytes[](2);
        items[0] = TxRlp.encodeString(hex"636174"); // cat
        items[1] = TxRlp.encodeString(hex"646f67"); // dog
        require(_eq(TxRlp.encodeRawList(items), hex"c88363617483646f67"), "cat,dog list");

        // Empty list -> 0xc0.
        bytes[] memory empty = new bytes[](0);
        require(_eq(TxRlp.encodeRawList(empty), hex"c0"), "empty list");
    }

    /*//////////////////////////////////////////////////////////////
                       EIP-1559 (cross-checked vs viem)
    //////////////////////////////////////////////////////////////*/

    function testEip1559SignedMatchesReference() public pure {
        Eip1559Transaction memory t;
        t.chainId = 4217;
        t.nonce = 7;
        t.maxPriorityFeePerGas = 1_000_000_000;
        t.maxFeePerGas = 20_000_000_000;
        t.gasLimit = 21000;
        t.to = 0x1111111111111111111111111111111111111111;
        t.value = 1 ether;
        t.data = "";

        // v = 28 -> yParity 1
        bytes memory got = t.encodeWithSignature(
            VM,
            28,
            0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef,
            0x0fedcba9876543210fedcba9876543210fedcba9876543210fedcba987654321
        );

        bytes memory expected =
            hex"02f87582107907843b9aca008504a817c800825208941111111111111111111111111111111111111111880de0b6b3a764000080c001a01234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdefa00fedcba9876543210fedcba9876543210fedcba9876543210fedcba987654321";
        require(_eq(got, expected), "eip1559 signed mismatch");
    }

    /*//////////////////////////////////////////////////////////////
                       EIP-7702 (cross-checked vs viem)
    //////////////////////////////////////////////////////////////*/

    function testEip7702SignedMatchesReference() public pure {
        Eip7702Transaction memory t;
        t.chainId = 4217;
        t.nonce = 3;
        t.maxPriorityFeePerGas = 2_000_000_000;
        t.maxFeePerGas = 30_000_000_000;
        t.gasLimit = 100000;
        t.to = 0x2222222222222222222222222222222222222222;
        t.value = 500;
        t.data = hex"deadbeef";

        Eip7702Authorization[] memory auths = new Eip7702Authorization[](1);
        auths[0] = Eip7702Authorization({
            chainId: 4217,
            codeAddress: 0x3333333333333333333333333333333333333333,
            nonce: 9,
            yParity: 0,
            r: bytes32(uint256(0xaa)), // leading zeros -> must be stripped
            s: bytes32(uint256(0xbb))
        });
        t.authorizationList = auths;

        // v = 27 -> yParity 0
        bytes memory got = t.encodeWithSignature(
            VM,
            27,
            0xabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcd,
            0x0123012301230123012301230123012301230123012301230123012301230123
        );

        bytes memory expected =
            hex"04f8948210790384773594008506fc23ac00830186a09422222222222222222222222222222222222222228201f484deadbeefc0dfde821079943333333333333333333333333333333333333333098081aa81bb80a0abcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcda00123012301230123012301230123012301230123012301230123012301230123";
        require(_eq(got, expected), "eip7702 signed mismatch");
    }
}
