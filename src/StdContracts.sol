// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

/// @title Standard Contracts Library for Tempo
///
/// @notice <https://github.com/tempoxyz/tempo/tree/main/crates/contracts/src/lib.rs>
library StdContracts {
    address internal constant MULTICALL_ADDRESS = 0xcA11bde05977b3631167028862bE2a173976CA11;
    address internal constant CREATEX_ADDRESS = 0xba5Ed099633D3B313e4D5F7bdc1305d3c28ba5Ed;
    address internal constant SAFE_DEPLOYER_ADDRESS = 0x914d7Fec6aaC8cd542e72Bca78B30650d45643d7;
    address internal constant PERMIT2_ADDRESS = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    address internal constant DEFAULT_7702_DELEGATE_ADDRESS = 0x7702c00000000000000000000000000000000000;
    address internal constant ARACHNID_CREATE2_FACTORY_ADDRESS = 0x4e59b44847b379578588920cA78FbF26c0B4956C;
}
