use alloy_consensus::transaction::SignerRecoverable;
use alloy_eips::{Decodable2718, Encodable2718};
use alloy_primitives::{Address, B256, Bytes, Signature, TxKind, U256, address, hex};
use alloy_rlp::Decodable;
use serde_json::Value;
use std::{collections::BTreeMap, process::Command};
use tempo_primitives::transaction::{
    AASigned, Call, CallScope, KeyAuthorization, SelectorRule, SignatureType,
    SignedKeyAuthorization, TempoTransaction, TokenLimit,
};

const ROOT: Address = address!("7e5f4552091a69125d5dfcb7b8c2659029395bdf");
const KEY: Address = address!("2b5ad5c4795c026514f8317c7a215e218dccd6cf");

fn main() {
    // Generate fresh bytes from Solidity, rather than only decoding copied fixtures.
    let output = Command::new(std::env::var("FORGE").unwrap_or_else(|_| "forge".into()))
        .args([
            "test",
            "--match-contract",
            "KeyAuthorizationInteropTest",
            "--json",
            "-vv",
        ])
        .current_dir(concat!(env!("CARGO_MANIFEST_DIR"), "/../.."))
        .output()
        .expect("run forge");
    assert!(
        output.status.success(),
        "forge failed: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    let result: Value = serde_json::from_slice(&output.stdout).expect("forge JSON");
    let tests =
        result["test/KeyAuthorizationInterop.t.sol:KeyAuthorizationInteropTest"]["test_results"]
            .as_object()
            .expect("test results");
    assert_eq!(tests.len(), 6, "all six fixtures must run");
    for (name, result) in tests {
        assert_eq!(result["status"], "Success", "{name}");
        let fields: BTreeMap<_, _> = result["decoded_logs"]
            .as_array()
            .unwrap()
            .iter()
            .map(|log| {
                let (key, value) = log
                    .as_str()
                    .unwrap()
                    .split_once(": ")
                    .expect("named bytes log");
                (key, hex::decode(value).expect("hex bytes"))
            })
            .collect();
        verify(name, &fields);
        println!(
            "PASS {name}: canonical decode/re-encode, fields, signing hashes and signer recovery"
        );
    }
}

fn verify(name: &str, fields: &BTreeMap<&str, Vec<u8>>) {
    let mut expected = TempoTransaction {
        chain_id: 1,
        max_fee_per_gas: 100,
        gas_limit: 100000,
        calls: vec![Call {
            to: TxKind::Call(address!("0000000000000000000000000000000000003333")),
            value: U256::ZERO,
            input: Bytes::new(),
        }],
        ..Default::default()
    };
    if name != "testInteropNoAuthorization()" {
        let mut authorization = KeyAuthorization::unrestricted(1, SignatureType::Secp256k1, KEY);
        match name {
            "testInteropDenyAll()" => {
                authorization = authorization.with_no_spending().with_no_calls()
            }
            "testInteropScoped()" => {
                authorization = authorization
                    .with_expiry(2000000000)
                    .with_limits(vec![
                        TokenLimit {
                            token: address!("0000000000000000000000000000000000002222"),
                            limit: U256::from(42),
                            period: 3600,
                        },
                        TokenLimit {
                            token: address!("0000000000000000000000000000000000002223"),
                            limit: U256::ZERO,
                            period: 0,
                        },
                    ])
                    .with_allowed_calls(vec![CallScope {
                        target: address!("0000000000000000000000000000000000003333"),
                        selector_rules: vec![SelectorRule {
                            selector: [0xaa, 0xbb, 0xcc, 0xdd],
                            recipients: vec![address!("0000000000000000000000000000000000004444")],
                        }],
                    }])
                    .with_witness(B256::ZERO)
                    .with_account(ROOT);
            }
            "testInteropAdmin()" => authorization = authorization.into_admin(ROOT),
            "testInteropUnrestricted()" | "testInteropSponsored()" => {}
            _ => panic!("unexpected fixture: {name}"),
        }
        let mut input = fields["authorization"].as_slice();
        let signed =
            SignedKeyAuthorization::decode(&mut input).expect("canonical signed authorization");
        assert!(input.is_empty());
        assert_eq!(signed.authorization, authorization);
        assert_eq!(signed.recover_signer().unwrap(), ROOT);
        assert_eq!(
            authorization.signature_hash().as_slice(),
            fields["authorization_hash"]
        );
        assert_eq!(alloy_rlp::encode(&signed), fields["authorization"]);
        expected.key_authorization = Some(signed);
    }
    if name == "testInteropSponsored()" {
        expected.fee_token = Some(address!("0000000000000000000000000000000000002222"));
        let signature = Signature::try_from(fields["fee_signature"].as_slice()).unwrap();
        assert_eq!(
            signature
                .recover_address_from_prehash(&expected.fee_payer_signature_hash(ROOT))
                .unwrap(),
            KEY
        );
        expected.fee_payer_signature = Some(signature);
    }
    expected.validate().expect("valid transaction structure");
    assert_eq!(expected.signature_hash().as_slice(), fields["user_hash"]);
    assert_eq!(
        expected.fee_payer_signature_hash(ROOT).as_slice(),
        fields["fee_hash"]
    );

    let mut unsigned = vec![0x76];
    unsigned.extend(alloy_rlp::encode(&expected));
    assert_eq!(unsigned, fields["unsigned"]);
    let mut input = &fields["unsigned"][1..];
    assert_eq!(TempoTransaction::decode(&mut input).unwrap(), expected);
    assert!(input.is_empty());

    let mut input = fields["signed"].as_slice();
    let signed = AASigned::decode_2718(&mut input).expect("canonical signed transaction");
    assert!(input.is_empty());
    assert_eq!(signed.tx(), &expected);
    assert_eq!(signed.recover_signer().unwrap(), ROOT);
    assert_eq!(signed.encoded_2718(), fields["signed"]);
}
