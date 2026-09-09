// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

import {IAccountKeychain} from "../src/interfaces/IAccountKeychain.sol";
import {KeyAuthorization, KeyAuthorizationLib} from "../src/tx/KeyAuthorizationLib.sol";
import {TempoTransaction, TempoTransactionLib} from "../src/tx/TempoTransactionLib.sol";
import {SignatureLib} from "../src/sig/SignatureLib.sol";
import {VM_ADDRESS, VmRlp, VmSign} from "../src/StdVm.sol";

/// @dev Run test/interop's Rust binary to decode and verify these Solidity-generated vectors.
contract KeyAuthorizationInteropTest {
    using KeyAuthorizationLib for KeyAuthorization;
    using TempoTransactionLib for TempoTransaction;

    event log_named_bytes(string key, bytes val);

    function testInteropNoAuthorization() public {
        _emitVector(0, false);
    }

    function testInteropUnrestricted() public {
        _emitVector(1, false);
    }

    function testInteropDenyAll() public {
        _emitVector(2, false);
    }

    function testInteropScoped() public {
        _emitVector(3, false);
    }

    function testInteropAdmin() public {
        _emitVector(4, false);
    }

    function testInteropSponsored() public {
        _emitVector(1, true);
    }

    function _emitVector(uint8 kind, bool sponsored) private {
        VmSign vm = VmSign(VM_ADDRESS);
        VmRlp rlp = VmRlp(VM_ADDRESS);
        TempoTransaction memory transaction = TempoTransactionLib.create()
            .withChainId(1)
            .withGasLimit(100000)
            .withMaxFeePerGas(100)
            .withCall(address(0x3333), 0, hex"");
        if (kind != 0) {
            KeyAuthorization memory authorization =
                KeyAuthorizationLib.create(1, IAccountKeychain.SignatureType.Secp256k1, vm.addr(2));
            if (kind == 2) {
                authorization = authorization.withLimits(new IAccountKeychain.TokenLimit[](0))
                    .withAllowedCalls(new IAccountKeychain.CallScope[](0));
            } else if (kind == 3) {
                IAccountKeychain.TokenLimit[] memory limits = new IAccountKeychain.TokenLimit[](2);
                limits[0] = IAccountKeychain.TokenLimit({token: address(0x2222), amount: 42, period: 3600});
                limits[1] = IAccountKeychain.TokenLimit({token: address(0x2223), amount: 0, period: 0});
                address[] memory recipients = new address[](1);
                recipients[0] = address(0x4444);
                IAccountKeychain.SelectorRule[] memory rules = new IAccountKeychain.SelectorRule[](1);
                rules[0] = IAccountKeychain.SelectorRule({selector: 0xaabbccdd, recipients: recipients});
                IAccountKeychain.CallScope[] memory scopes = new IAccountKeychain.CallScope[](1);
                scopes[0] = IAccountKeychain.CallScope({target: address(0x3333), selectorRules: rules});
                authorization = authorization.withExpiry(2000000000)
                    .withLimits(limits)
                    .withAllowedCalls(scopes)
                    .withWitness(bytes32(0))
                    .withAccount(vm.addr(1));
            } else if (kind == 4) {
                authorization = authorization.asAdmin(vm.addr(1));
            }
            bytes memory signedAuthorization = authorization.sign(1);
            transaction = transaction.withKeyAuthorization(signedAuthorization);
            emit log_named_bytes("authorization", signedAuthorization);
            emit log_named_bytes("authorization_hash", abi.encodePacked(authorization.signingHash()));
        }
        if (sponsored) {
            transaction = transaction.withFeeToken(address(0x2222));
            bytes memory feeSignature = SignatureLib.signSecp(2, transaction.feePayerSignatureHash(rlp, vm.addr(1)));
            transaction = transaction.withFeePayerSignature(feeSignature);
            emit log_named_bytes("fee_signature", feeSignature);
        }
        bytes32 hash = transaction.signingHash(rlp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, hash);
        if (kind == 0) {
            require(
                keccak256(transaction.encode(rlp))
                    == keccak256(
                        hex"76e8018064830186a0d8d79400000000000000000000000000000000000033338080c0808080808080c0"
                    ),
                "no authorization unsigned vector"
            );
            require(
                keccak256(transaction.encodeWithSignature(rlp, v, r, s))
                    == keccak256(
                        hex"76f86b018064830186a0d8d79400000000000000000000000000000000000033338080c0808080808080c0b8414f5678361cd962005fc23d95dda7b934cf0ed0be5e81f68822ff639c74f8ee9d31c3fcbd071e4a4d1b55f59fbf9582a30b4c3035c51f4f375f66045af1ee5a651b"
                    ),
                "no authorization signed vector"
            );
            require(
                hash == 0x9b0f4fff4efd85b1a8a33813ca37faf977c4cfe747ebe3fd076d76d3b468c47b, "no authorization user hash"
            );
            require(
                transaction.feePayerSignatureHash(rlp, vm.addr(1))
                    == 0xbee3afc9c718fc6bbdd2b913f4cd846e3787128e0ef0149e93febd56699e32c2,
                "no authorization fee hash"
            );
        }
        emit log_named_bytes("unsigned", transaction.encode(rlp));
        emit log_named_bytes("signed", transaction.encodeWithSignature(rlp, v, r, s));
        emit log_named_bytes("user_hash", abi.encodePacked(hash));
        emit log_named_bytes("fee_hash", abi.encodePacked(transaction.feePayerSignatureHash(rlp, vm.addr(1))));
    }
}
