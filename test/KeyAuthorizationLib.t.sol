// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

import {IAccountKeychain} from "../src/interfaces/IAccountKeychain.sol";
import {SignatureLib} from "../src/sig/SignatureLib.sol";
import {KeyAuthorization, KeyAuthorizationLib} from "../src/tx/KeyAuthorizationLib.sol";
import {TempoTransaction, TempoTransactionLib} from "../src/tx/TempoTransactionLib.sol";
import {VM_ADDRESS, VmRlp} from "../src/StdVm.sol";

contract KeyAuthorizationLibTest {
    using KeyAuthorizationLib for KeyAuthorization;
    using TempoTransactionLib for TempoTransaction;

    address internal constant KEY = 0x1111111111111111111111111111111111111111;
    address internal constant TOKEN = 0x2222222222222222222222222222222222222222;
    address internal constant TARGET = 0x3333333333333333333333333333333333333333;
    address internal constant RECIPIENT = 0x4444444444444444444444444444444444444444;
    address internal constant ACCOUNT = 0x6666666666666666666666666666666666666666;

    function testUnrestrictedEncodingMatchesRustWireFormat() public pure {
        KeyAuthorization memory authorization =
            KeyAuthorizationLib.create(1, IAccountKeychain.SignatureType.Secp256k1, KEY);

        _assertBytesEq(authorization.encode(), hex"d70180941111111111111111111111111111111111111111");
        require(
            authorization.signingHash() == 0x6e9d4193694eea8c4d2ddcc0b400df9a3f21773d4cf4afccbd8082af6dda18c0,
            "signing hash"
        );
    }

    function testOptionalPlaceholdersAndZeroWitness() public pure {
        KeyAuthorization memory authorization =
            KeyAuthorizationLib.create(1, IAccountKeychain.SignatureType.Secp256k1, KEY).withWitness(bytes32(0));

        _assertBytesEq(
            authorization.encode(),
            hex"f83b0180941111111111111111111111111111111111111111808080a00000000000000000000000000000000000000000000000000000000000000000"
        );
        require(
            authorization.signingHash()
                != KeyAuthorizationLib.create(1, IAccountKeychain.SignatureType.Secp256k1, KEY).signingHash(),
            "zero witness must be present"
        );
    }

    function testFullEncodingMatchesRustWireFormat() public pure {
        IAccountKeychain.TokenLimit[] memory limits = new IAccountKeychain.TokenLimit[](1);
        limits[0] = IAccountKeychain.TokenLimit({token: TOKEN, amount: 42, period: 3600});

        address[] memory recipients = new address[](1);
        recipients[0] = RECIPIENT;
        IAccountKeychain.SelectorRule[] memory rules = new IAccountKeychain.SelectorRule[](1);
        rules[0] = IAccountKeychain.SelectorRule({selector: 0xaabbccdd, recipients: recipients});
        IAccountKeychain.CallScope[] memory scopes = new IAccountKeychain.CallScope[](1);
        scopes[0] = IAccountKeychain.CallScope({target: TARGET, selectorRules: rules});

        KeyAuthorization memory authorization = KeyAuthorizationLib.create(
                4217, IAccountKeychain.SignatureType.P256, KEY
            )
            .withExpiry(1000)
            .withLimits(limits)
            .withAllowedCalls(scopes)
            .withWitness(bytes32(uint256(0x5555555555555555555555555555555555555555555555555555555555555555)))
            .asAdmin(ACCOUNT);

        _assertBytesEq(
            authorization.encode(),
            hex"f8a2821079019411111111111111111111111111111111111111118203e8dad99422222222222222222222222222222222222222222a820e10f3f2943333333333333333333333333333333333333333dcdb84aabbccddd5944444444444444444444444444444444444444444a0555555555555555555555555555555555555555555555555555555555555555501946666666666666666666666666666666666666666"
        );
    }

    function testFromRestrictionsPreservesLegacySemantics() public pure {
        IAccountKeychain.TokenLimit[] memory limits = new IAccountKeychain.TokenLimit[](0);
        IAccountKeychain.CallScope[] memory scopes = new IAccountKeychain.CallScope[](0);
        IAccountKeychain.KeyRestrictions memory restrictions = IAccountKeychain.KeyRestrictions({
            expiry: type(uint64).max, enforceLimits: true, limits: limits, allowAnyCalls: false, allowedCalls: scopes
        });

        KeyAuthorization memory authorization =
            KeyAuthorizationLib.fromRestrictions(1, IAccountKeychain.SignatureType.WebAuthn, KEY, restrictions);

        require(!authorization.hasExpiry, "never expiry");
        require(authorization.hasLimits && authorization.limits.length == 0, "deny spending");
        require(authorization.hasAllowedCalls && authorization.allowedCalls.length == 0, "deny calls");
    }

    function testSignedEncodingMatchesRustWireFormat() public pure {
        KeyAuthorization memory authorization =
            KeyAuthorizationLib.create(1, IAccountKeychain.SignatureType.Secp256k1, KEY);
        bytes memory signature = new bytes(65);
        for (uint256 i = 0; i < signature.length; i++) {
            signature[i] = 0x77;
        }

        _assertBytesEq(
            authorization.encodeSigned(signature),
            hex"f85bd70180941111111111111111111111111111111111111111b8417777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777"
        );
    }

    function testSignUsesAuthorizationHash() public pure {
        uint256 privateKey = 1;
        KeyAuthorization memory authorization =
            KeyAuthorizationLib.create(1, IAccountKeychain.SignatureType.Secp256k1, KEY);
        bytes memory signature = SignatureLib.signSecp(privateKey, authorization.signingHash());

        _assertBytesEq(authorization.sign(privateKey), authorization.encodeSigned(signature));
    }

    function testTempoTransactionEmbedsAuthorizationAsList() public pure {
        KeyAuthorization memory authorization =
            KeyAuthorizationLib.create(1, IAccountKeychain.SignatureType.Secp256k1, KEY);
        bytes memory signature = new bytes(65);
        for (uint256 i = 0; i < signature.length; i++) {
            signature[i] = 0x77;
        }

        TempoTransaction memory transaction =
            TempoTransactionLib.create().withChainId(1).withKeyAuthorization(authorization.encodeSigned(signature));

        _assertBytesEq(
            transaction.encode(VmRlp(VM_ADDRESS)),
            hex"76f86c018080825208c0c0808080808080c0f85bd70180941111111111111111111111111111111111111111b8417777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777"
        );
        require(
            transaction.signingHash(VmRlp(VM_ADDRESS))
                == 0x9c6f2f300d986c98bb34792411870c85ed79afcfa46daa551eab286a7ac99bcb,
            "transaction signing hash"
        );
        require(
            transaction.feePayerSignatureHash(VmRlp(VM_ADDRESS), 0x2222222222222222222222222222222222222222)
                == 0x2c5c348bb691e46c0cf0e180896ca9ebb244d56b3d9b91c31b9e1500ed8218ad,
            "fee payer signing hash"
        );
        _assertBytesEq(
            transaction.encodeWithSignature(
                VmRlp(VM_ADDRESS),
                27,
                0x8888888888888888888888888888888888888888888888888888888888888888,
                0x9999999999999999999999999999999999999999999999999999999999999999
            ),
            hex"76f8af018080825208c0c0808080808080c0f85bd70180941111111111111111111111111111111111111111b8417777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777b841888888888888888888888888888888888888888888888888888888888888888899999999999999999999999999999999999999999999999999999999999999991b"
        );
    }

    function testExpiryRejectsZero() public view {
        KeyAuthorization memory authorization =
            KeyAuthorizationLib.create(1, IAccountKeychain.SignatureType.Secp256k1, KEY);
        try this.withZeroExpiry(authorization) {
            revert("expected revert");
        } catch {}
    }

    function withZeroExpiry(KeyAuthorization memory authorization) external pure {
        authorization.withExpiry(0);
    }

    function _assertBytesEq(bytes memory actual, bytes memory expected) private pure {
        require(keccak256(actual) == keccak256(expected), "encoded bytes");
    }
}
