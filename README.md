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

```
forge install tempoxyz/tempo-std
```

## Standard Precompiles

<pre>
src
├── interfaces
│   ├── <a href="./src/interfaces/IFeeAMM.sol">IFeeAMM.sol</a>: <a href="https://docs.tempo.xyz/protocol/transactions/fee-amm#fee-amm-specification">Fee AMM</a>
│   ├── <a href="./src/interfaces/IFeeManager.sol">IFeeManager.sol</a>: <a href="https://docs.tempo.xyz/protocol/transactions/fee-amm#fee-amm-specification">Fee AMM Management</a>
│   ├── <a href="./src/interfaces/ILinkingUSD.sol">ILinkingUSD.sol</a>: <a href="https://docs.tempo.xyz/protocol/stablecoin-exchange/linking-usd">LinkingUSD</a>
│   ├── <a href="./src/interfaces/INonce.sol">INonce.sol</a>: 2D Nonce Management for Account Abstraction
│   ├── <a href="./src/interfaces/IStablecoinExchange.sol">IStablecoinExchange.sol</a>: <a href="https://docs.tempo.xyz/protocol/stablecoin-exchange/stablecoin-exchange">Stablecoin Exchange</a>
│   ├── <a href="./src/interfaces/ITIP20Factory.sol">ITIP20Factory.sol</a>: <a href="https://docs.tempo.xyz/documentation/tokens/creating-tokens#creating-tokens">TIP-20: Factory Contract</a>
│   ├── <a href="./src/interfaces/ITIP20RewardsRegistry.sol">ITIP20RewardsRegistry.sol</a>: <a href="https://docs.tempo.xyz/protocol/tokens/reward-distribution#overview">TIP-20: Reward Distribution</a>
│   ├── <a href="./src/interfaces/ITIP20RolesAuth.sol">ITIP20RolesAuth.sol</a>: <a href="https://docs.tempo.xyz/documentation/tokens/roles">TIP-20: Roles & Permissions</a>
│   ├── <a href="./src/interfaces/ITIP20.sol">ITIP20.sol</a>: <a href="https://docs.tempo.xyz/protocol/tokens/tip-20">TIP-20: Core Token Standard</a>
│   └── <a href="./src/interfaces/ITIP403Registry.sol">ITIP403Registry.sol</a>: <a href="https://docs.tempo.xyz/protocol/tokens/tip-403">TIP-403: Policy Registry System</a>
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

## Support

The current minimum supported Solidity version is `0.8.13`.

## Security

See [`SECURITY.md`](https://github.com/tempoxyz/tempo-std?tab=security-ov-file).

## License

Licensed under either of [Apache License](./LICENSE-APACHE), Version
2.0 or [MIT License](./LICENSE-MIT) at your option.

Unless you explicitly state otherwise, any contribution intentionally submitted
for inclusion in these crates by you, as defined in the Apache-2.0 license,
shall be dual licensed as above, without any additional terms or conditions.
