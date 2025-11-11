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

### Installation

```
forge install tempoxyz/tempo-std
```

### Standard Precompiles

<pre>
src
├── interfaces
│   ├── <a href="./src/interfaces/IFeeAMM.sol">IFeeAMM.sol</a>: A
│   ├── <a href="./src/interfaces/IFeeManager.sol">IFeeManager.sol</a>: B
│   ├── <a href="./src/interfaces/ILinkingUSD.sol">ILinkingUSD.sol</a>: C
│   ├── <a href="./src/interfaces/INonce.sol">INonce.sol</a>: D
│   ├── <a href="./src/interfaces/IStablecoinExchange.sol">IStablecoinExchange.sol</a>: E
│   ├── <a href="./src/interfaces/ITIP20Factory.sol">ITIP20Factory.sol</a>: F
│   ├── <a href="./src/interfaces/ITIP20RewardsRegistry.sol">ITIP20RewardsRegistry.sol</a>: G
│   ├── <a href="./src/interfaces/ITIP20RolesAuth.sol">ITIP20RolesAuth.sol</a>: H
│   ├── <a href="./src/interfaces/ITIP20.sol">ITIP20.sol</a>: I
│   ├── <a href="./src/interfaces/ITIP403Registry.sol">ITIP403Registry.sol</a>: J
│   └── <a href="./src/interfaces/ITIPAccountRegistrar.sol">ITIPAccountRegistrar.sol</a>: K
└── <a href="./src/StdPrecompiles.sol">StdPrecompiles.sol</a>: L
</pre>

### Standard Contracts

<pre>
src
├── interfaces
│   ├── <a href="./src/interfaces/ICreateX.sol">ICreateX.sol</a>: <a href="https://github.com/pcaversaccio/createx">@pcaversaccio/createx</a>
│   ├── <a href="./src/interfaces/IMulticall3.sol">IMulticall3.sol</a>: <a href="https://github.com/mds1/multicall3">@mds1/multicall3</a>
│   ├── <a href="./src/interfaces/IPermit2.sol">IPermit2.sol</a>: <a href="https://github.com/Uniswap/permit2">@uniswap/permit2</a>
└──  <a href="./src/StdContracts.sol">StdContracts.sol</a>
</pre>

### Support

The current minimum supported Solidity version is `0.8.13`.

### License

Licensed under either of [Apache License](./LICENSE-APACHE), Version
2.0 or [MIT License](./LICENSE-MIT) at your option.

Unless you explicitly state otherwise, any contribution intentionally submitted
for inclusion in these crates by you, as defined in the Apache-2.0 license,
shall be dual licensed as above, without any additional terms or conditions.
