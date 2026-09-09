// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

import {IAccountKeychain} from "../src/interfaces/IAccountKeychain.sol";
import {KeyAuthorization, KeyAuthorizationLib} from "../src/tx/KeyAuthorizationLib.sol";
import {KeyAuthorizationRlp} from "../src/tx/KeyAuthorizationRlp.sol";
import {TempoTransaction, TempoTransactionLib} from "../src/tx/TempoTransactionLib.sol";
import {TxRlp} from "../src/tx/TxRlp.sol";
import {VmRlp} from "../src/StdVm.sol";

contract KeyAuthorizationValidationTest {
    using KeyAuthorizationLib for KeyAuthorization;
    using TempoTransactionLib for TempoTransaction;

    function testSetAllowedCallsSelectorIsUnambiguous() public pure {
        require(
            IAccountKeychain.setAllowedCalls.selector
                == bytes4(keccak256("setAllowedCalls(address,(address,(bytes4,address[])[])[])")),
            "selector"
        );
    }

    function testContradictoryRestrictionsRevert() public view {
        IAccountKeychain.KeyRestrictions memory restrictions;
        restrictions.expiry = type(uint64).max;
        restrictions.allowAnyCalls = true;
        restrictions.allowedCalls = new IAccountKeychain.CallScope[](1);
        try this.convert(restrictions) {
            revert("expected revert");
        } catch Error(string memory reason) {
            require(keccak256(bytes(reason)) == keccak256("KeyAuthorizationLib: contradictory call scopes"));
        }
    }

    function testUnrestrictedConversion() public pure {
        IAccountKeychain.KeyRestrictions memory restrictions;
        restrictions.expiry = type(uint64).max;
        restrictions.allowAnyCalls = true;
        KeyAuthorization memory authorization =
            KeyAuthorizationLib.fromRestrictions(1, IAccountKeychain.SignatureType.Secp256k1, address(1), restrictions);
        require(!authorization.hasExpiry && !authorization.hasLimits && !authorization.hasAllowedCalls);
    }

    function testDirectStructZeroExpiryRevertsAtEveryEntryPoint() public view {
        KeyAuthorization memory authorization;
        authorization.hasExpiry = true;
        for (uint8 path; path < 4; path++) {
            try this.encodeAuthorization(authorization, path) {
                revert("expected revert");
            } catch Error(string memory reason) {
                require(keccak256(bytes(reason)) == keccak256("KeyAuthorizationLib: zero expiry"));
            }
        }
    }

    function testMalformedRlpRejected() public view {
        _reject(hex"");
        _reject(hex"80"); // string, not list
        _reject(hex"c0"); // missing authorization and signature
        _reject(hex"c180"); // authorization is not a list
        _reject(hex"c2c080"); // missing authorization fields
        _reject(hex"f801c0"); // non-minimal long-list header
        _reject(hex"f90038"); // leading zero in length
        _reject(hex"f838"); // truncated payload
        bytes memory valid = _authorization().sign(1);
        _reject(bytes.concat(valid, hex"80")); // second top-level item
        valid[1] = bytes1(uint8(valid[1]) + 1); // truncated list
        _reject(valid);
    }

    function testMalformedAuthorizationSchemaRejected() public view {
        bytes[] memory fields = new bytes[](3);
        fields[0] = hex"01";
        fields[1] = hex"80";
        fields[2] = TxRlp.encodeString(abi.encodePacked(address(1)));
        fields[0] = hex"8101"; // non-minimal string
        _reject(_signed(TxRlp.encodeRawList(fields)));
        fields[0] = hex"00"; // non-minimal integer zero
        _reject(_signed(TxRlp.encodeRawList(fields)));
        fields[0] = hex"89010000000000000000"; // uint64 overflow
        _reject(_signed(TxRlp.encodeRawList(fields)));
        fields[0] = hex"01";
        fields[1] = hex"03"; // unsupported key type
        _reject(_signed(TxRlp.encodeRawList(fields)));
        fields[1] = hex"80";
        fields[2] = hex"80"; // address must be 20 bytes
        _reject(_signed(TxRlp.encodeRawList(fields)));

        bytes memory base = _authorization().encode();
        // Change the short-list length and append a trailing None expiry.
        base[0] = bytes1(uint8(base[0]) + 1);
        _reject(_signed(bytes.concat(base, hex"80")));
    }

    function testMalformedNestedScopesRejected() public view {
        bytes[] memory fields = new bytes[](6);
        fields[0] = hex"01";
        fields[1] = hex"80";
        fields[2] = TxRlp.encodeString(abi.encodePacked(address(1)));
        fields[3] = hex"80";
        fields[4] = hex"80";
        fields[5] = hex"c1c0"; // scope missing target and rules
        _reject(_signed(TxRlp.encodeRawList(fields)));
        fields[5] = hex"c180"; // scope must be a list
        _reject(_signed(TxRlp.encodeRawList(fields)));
        fields[5] = hex"01"; // scopes must be a list or None
        _reject(_signed(TxRlp.encodeRawList(fields)));
    }

    function testInvalidPrimitiveSignaturesRejected() public view {
        _reject(_authorization().encodeSigned(hex""));
        _reject(_authorization().encodeSigned(hex"01"));
        _reject(_authorization().encodeSigned(new bytes(64)));
        bytes memory signature = new bytes(65);
        signature[64] = 0x02;
        _reject(_authorization().encodeSigned(signature));
        signature = new bytes(130);
        signature[0] = 0x03; // keychain is not a primitive signature
        _reject(_authorization().encodeSigned(signature));
    }

    function testPrimitiveSignatureShapesAccepted() public pure {
        bytes memory signature = new bytes(130);
        signature[0] = 0x01;
        KeyAuthorizationRlp.validate(_authorization().encodeSigned(signature));
        signature = new bytes(129);
        signature[0] = 0x02;
        KeyAuthorizationRlp.validate(_authorization().encodeSigned(signature));
    }

    function testFuzzBuilderOutputAccepted(uint64 chainId, uint64 expiry, uint8 flags, bytes32 witness, address key)
        public
        pure
    {
        KeyAuthorization memory authorization =
            KeyAuthorizationLib.create(chainId, IAccountKeychain.SignatureType(flags % 3), key);
        if (flags & 1 != 0 && expiry != 0) authorization = authorization.withExpiry(expiry);
        if (flags & 2 != 0) authorization = authorization.withLimits(new IAccountKeychain.TokenLimit[](0));
        if (flags & 4 != 0) authorization = authorization.withAllowedCalls(new IAccountKeychain.CallScope[](0));
        if (flags & 8 != 0) authorization = authorization.withWitness(witness);
        if (flags & 16 != 0) authorization = authorization.withAccount(key);
        if (flags & 32 != 0) authorization = authorization.asAdmin(key);
        KeyAuthorizationRlp.validate(authorization.sign(1));
    }

    function testDirectTransactionMutationValidatedOnAllPaths() public view {
        TempoTransaction memory transaction = TempoTransactionLib.create();
        transaction.hasKeyAuthorization = true;
        transaction.keyAuthorization = hex"80";
        for (uint8 path; path < 4; path++) {
            try this.encodeTransaction(transaction, path) {
                revert("expected revert");
            } catch (bytes memory reason) {
                require(
                    keccak256(reason)
                        == keccak256(abi.encodeWithSelector(KeyAuthorizationRlp.InvalidKeyAuthorization.selector))
                );
            }
        }
    }

    function convert(IAccountKeychain.KeyRestrictions memory restrictions) external pure {
        KeyAuthorizationLib.fromRestrictions(1, IAccountKeychain.SignatureType.Secp256k1, address(1), restrictions);
    }

    function encodeAuthorization(KeyAuthorization memory authorization, uint8 path) external pure {
        if (path == 0) authorization.encode();
        else if (path == 1) authorization.signingHash();
        else if (path == 2) authorization.encodeSigned(new bytes(65));
        else authorization.sign(1);
    }

    function encodeTransaction(TempoTransaction memory transaction, uint8 path) external pure {
        if (path == 0) transaction.encode(VmRlp(address(0)));
        else if (path == 1) transaction.signingHash(VmRlp(address(0)));
        else if (path == 2) transaction.encodeWithSignature(VmRlp(address(0)), 27, bytes32(0), bytes32(0));
        else transaction.feePayerSignatureHash(VmRlp(address(0)), address(1));
    }

    function attach(bytes memory encoded) external pure {
        TempoTransactionLib.create().withKeyAuthorization(encoded);
    }

    function _reject(bytes memory encoded) private view {
        try this.attach(encoded) {
            revert("expected revert");
        } catch (bytes memory reason) {
            require(
                keccak256(reason)
                    == keccak256(abi.encodeWithSelector(KeyAuthorizationRlp.InvalidKeyAuthorization.selector))
            );
        }
    }

    function _authorization() private pure returns (KeyAuthorization memory) {
        return KeyAuthorizationLib.create(1, IAccountKeychain.SignatureType.Secp256k1, address(1));
    }

    function _signed(bytes memory encoded) private pure returns (bytes memory) {
        bytes[] memory fields = new bytes[](2);
        fields[0] = encoded;
        fields[1] = TxRlp.encodeString(new bytes(65));
        return TxRlp.encodeRawList(fields);
    }
}
