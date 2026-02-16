<br>
<br>

<p align="center">
  <a href="https://tempo.xyz">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/tempoxyz/.github/refs/heads/main/assets/combomark-dark.svg">
      <img alt="tempo combomark" src="https://raw.githubusercontent.com/tempoxyz/.github/refs/heads/main/assets/combomark-bright.svg" width="auto" height="120">
    </picture>
  </a>
</p>

<br>
<br>

# Tempo Standard Library

Tempo Standard Library is a collection of helpful Tempo specific contracts and libraries for use with [Foundry](https://github.com/foundry-rs/foundry).

## Installation

```bash
forge install tempoxyz/tempo-std
```

## Standard Precompiles

<pre>
src
├── interfaces
│   ├── <a href="./src/interfaces/IAccountKeychain.sol">IAccountKeychain.sol</a>: Account Keychain | <a href="https://docs.tempo.xyz/documentation/protocol/transactions/spec-tempo-transaction#keychain-precompile">Docs</a> | <a href="https://github.com/tempoxyz/tempo/blob/main/crates/precompiles/src/account_keychain/mod.rs">Implementation</a>
│   ├── <a href="./src/interfaces/IFeeAMM.sol">IFeeAMM.sol</a>: Fee AMM | <a href="https://docs.tempo.xyz/documentation/protocol/fees/fee-amm">Docs</a> | <a href="https://github.com/tempoxyz/tempo/blob/main/crates/precompiles/src/tip_fee_manager/amm.rs">Implementation</a>
│   ├── <a href="./src/interfaces/IFeeManager.sol">IFeeManager.sol</a>: Fee AMM Management | <a href="https://docs.tempo.xyz/documentation/protocol/fees/spec-fee-amm#2-feemanager-contract">Docs</a> | <a href="https://github.com/tempoxyz/tempo/blob/main/crates/precompiles/src/tip_fee_manager/mod.rs">Implementation</a>
│   ├── <a href="./src/interfaces/INonce.sol">INonce.sol</a>: 2D Nonce Management for Tempo Transactions | <a href="https://github.com/tempoxyz/tempo/blob/main/crates/precompiles/src/nonce/mod.rs">Implementation</a>
│   ├── <a href="./src/interfaces/IStablecoinDEX.sol">IStablecoinDEX.sol</a>: Stablecoin DEX | <a href="https://docs.tempo.xyz/protocol/exchange/spec#stablecoin-dex">Docs</a> | <a href="https://github.com/tempoxyz/tempo/blob/main/crates/precompiles/src/stablecoin_dex/mod.rs">Implementation</a>
│   ├── <a href="./src/interfaces/ITIP20Factory.sol">ITIP20Factory.sol</a>: TIP-20: Factory Contract | <a href="https://docs.tempo.xyz/documentation/protocol/tip20/spec#tip20factory">Docs</a> | <a href="https://github.com/tempoxyz/tempo/blob/main/crates/precompiles/src/tip20_factory/mod.rs">Implementation</a>
│   ├── <a href="./src/interfaces/ITIP20RewardsRegistry.sol">ITIP20RewardsRegistry.sol</a>: TIP-20: Reward Distribution | <a href="https://docs.tempo.xyz/documentation/protocol/tip20-rewards/spec">Docs</a> | <a href="https://github.com/tempoxyz/tempo/blob/main/crates/precompiles/src/tip20_rewards_registry/mod.rs">Implementation</a>
│   ├── <a href="./src/interfaces/ITIP20RolesAuth.sol">ITIP20RolesAuth.sol</a>: TIP-20: Roles & Permissions | <a href="https://docs.tempo.xyz/documentation/protocol/tip20/spec#role-based-access-control">Docs</a> | <a href="https://github.com/tempoxyz/tempo/blob/main/crates/precompiles/src/tip20/roles.rs">Implementation</a>
│   ├── <a href="./src/interfaces/ITIP20.sol">ITIP20.sol</a>: TIP-20: Core Token Standard | <a href="https://docs.tempo.xyz/documentation/protocol/tip20/overview">Docs</a> | <a href="https://github.com/tempoxyz/tempo/blob/main/crates/precompiles/src/tip20/mod.rs">Implementation</a>
│   └── <a href="./src/interfaces/ITIP403Registry.sol">ITIP403Registry.sol</a>: TIP-403: Policy Registry System | <a href="https://docs.tempo.xyz/documentation/protocol/tip403/overview">Docs</a> | <a href="https://github.com/tempoxyz/tempo/blob/main/crates/precompiles/src/tip403_registry/mod.rs">Implementation</a>
│   └── <a href="./src/interfaces/IValidatorConfig.sol">IValidatorConfig.sol</a>: Manage consensus validators | <a href="https://github.com/tempoxyz/tempo/blob/main/crates/precompiles/src/validator_config/mod.rs">Implementation</a>
└── <a href="./src/StdPrecompiles.sol">StdPrecompiles.sol</a>: Collection of precompiles and their interfaces on Tempo
</pre>

## Standard Contracts

<pre>
src
├── interfaces
│   ├── <a href="./src/interfaces/ICreateX.sol">ICreateX.sol</a>: <a href="https://github.com/pcaversaccio/createx">@pcaversaccio/createx</a>
│   ├── <a href="./src/interfaces/IMulticall3.sol">IMulticall3.sol</a>: <a href="https://github.com/mds1/multicall3">@mds1/multicall3</a>
│   ├── <a href="./src/interfaces/IPermit2.sol">IPermit2.sol</a>: <a href="https://github.com/Uniswap/permit2">@uniswap/permit2</a>
└──  <a href="./src/StdContracts.sol">StdContracts.sol</a>: Collection of predeployed contracts and their interfaces on Tempo
</pre>

## Standard Tokens

<pre>
src
└── <a href="./src/StdTokens.sol">StdTokens.sol</a>: Collection of tokens and their interfaces on Tempo
</pre>

## Standard Vm

<pre>
src
└── <a href="./src/StdVm.sol">StdVm.sol</a>: Minimal Vm interfaces for RLP encoding and transaction execution
</pre>

## Transaction Builders

Solidity libraries for building and RLP-encoding Ethereum and Tempo transactions, useful for testing with Foundry.

<pre>
src
└── tx
    ├── <a href="./src/tx/AccessListTypes.sol">AccessListTypes.sol</a>: EIP-2930 access list types
    ├── <a href="./src/tx/Eip1559TransactionLib.sol">Eip1559TransactionLib.sol</a>: EIP-1559 (type 2) transaction builder
    ├── <a href="./src/tx/Eip7702TransactionLib.sol">Eip7702TransactionLib.sol</a>: EIP-7702 (type 4) transaction builder with authorization support
    ├── <a href="./src/tx/LegacyTransactionLib.sol">LegacyTransactionLib.sol</a>: Legacy (type 0) transaction builder
    ├── <a href="./src/tx/TempoTransactionLib.sol">TempoTransactionLib.sol</a>: Tempo (type 0x76) transaction builder with batch calls, 2D nonces, and fee payer support
    └── <a href="./src/tx/TxRlp.sol">TxRlp.sol</a>: RLP encoding helpers for transaction builders
</pre>

## Support

The current minimum supported Solidity version is `0.8.20`.

## Contributing

Our contributor guidelines can be found in [`CONTRIBUTING.md`](https://github.com/tempoxyz/tempo-std?tab=contributing-ov-file).

## Security

See [`SECURITY.md`](https://github.com/tempoxyz/tempo-std?tab=security-ov-file).

## License

Licensed under either of [Apache License](./LICENSE-APACHE), Version
2.0 or [MIT License](./LICENSE-MIT) at your option.

Unless you explicitly state otherwise, any contribution intentionally submitted
for inclusion in these crates by you, as defined in the Apache-2.0 license,
shall be dual licensed as above, without any additional terms or conditions.
