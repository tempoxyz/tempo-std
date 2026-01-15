// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @title Standard Chain Library for Tempo
///
/// @notice <https://github.com/tempoxyz/tempo/tree/main/crates/chainspec/src/genesis>
library StdChain {
    struct Chain {
        string name;
        uint256 chainId;
        string rpcUrl;
    }

    uint256 internal constant MAINNET_CHAIN_ID = 4217;
    uint256 internal constant MODERATO_CHAIN_ID = 42431;
    uint256 internal constant ANDANTINO_CHAIN_ID = 42429;

    string internal constant MAINNET_RPC_URL = "https://rpc.mainnet.tempo.xyz";
    string internal constant MODERATO_RPC_URL = "https://rpc.moderato.tempo.xyz";
    string internal constant ANDANTINO_RPC_URL = "https://rpc.testnet.tempo.xyz";

    function mainnet() internal pure returns (Chain memory) {
        return Chain({name: "tempo", chainId: MAINNET_CHAIN_ID, rpcUrl: MAINNET_RPC_URL});
    }

    function moderato() internal pure returns (Chain memory) {
        return Chain({name: "moderato", chainId: MODERATO_CHAIN_ID, rpcUrl: MODERATO_RPC_URL});
    }

    function andantino() internal pure returns (Chain memory) {
        return Chain({name: "andantino", chainId: ANDANTINO_CHAIN_ID, rpcUrl: ANDANTINO_RPC_URL});
    }
}
