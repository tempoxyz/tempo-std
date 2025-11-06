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

### Contracts

```ml
src
├── interfaces
│   ├── ICreateX.sol
│   ├── IERC20.sol
│   ├── IFeeAMM.sol
│   ├── IFeeManager.sol
│   ├── ILinkingUSD.sol
│   ├── IMulticall3.sol
│   ├── INonce.sol
│   ├── IPermit2.sol
│   ├── IStablecoinExchange.sol
│   ├── ITIP20Factory.sol
│   ├── ITIP20RewardsRegistry.sol
│   ├── ITIP20RolesAuth.sol
│   ├── ITIP20.sol
│   ├── ITIP403Registry.sol
│   └── ITIPAccountRegistrar.sol
├── StdContracts.sol
└── StdPrecompiles.sol
```

### Support

The current minimum supported Solidity version is `0.8.13`.

### License

Licensed under either of [Apache License](./LICENSE-APACHE), Version
2.0 or [MIT License](./LICENSE-MIT) at your option.

Unless you explicitly state otherwise, any contribution intentionally submitted
for inclusion in these crates by you, as defined in the Apache-2.0 license,
shall be dual licensed as above, without any additional terms or conditions.
