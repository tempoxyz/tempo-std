// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

import {ITIP20} from "./interfaces/ITIP20.sol";

/// @title Standard Tokens Library for Tempo
///
/// @notice <https://github.com/tempoxyz/tempo/blob/main/crates/contracts/src/precompiles/mod.rs>
/// @notice <https://github.com/tempoxyz/tempo/blob/98ad3e3e2c400e9f2adf6da6e8a3523669f7c558/xtask/src/genesis_args.rs#L168-L200>
library StdTokens {
    address internal constant PATH_USD_ADDRESS = 0x20C0000000000000000000000000000000000000;
    address internal constant ALPHA_USD_ADDRESS = 0x20C0000000000000000000000000000000000001;
    address internal constant BETA_USD_ADDRESS = 0x20C0000000000000000000000000000000000002;
    address internal constant THETA_USD_ADDRESS = 0x20C0000000000000000000000000000000000003;
    /// @dev OpenUSD (OUSD), same address on Tempo mainnet and testnet.
    /// <https://github.com/tempoxyz/tempo/blob/main/crates/hardfork/src/constants.rs>
    address internal constant OUSD_ADDRESS = 0x20c0000000000000000000006a37DA5C996874BE;

    ITIP20 internal constant PATH_USD = ITIP20(PATH_USD_ADDRESS);
    ITIP20 internal constant ALPHA_USD = ITIP20(ALPHA_USD_ADDRESS);
    ITIP20 internal constant BETA_USD = ITIP20(BETA_USD_ADDRESS);
    ITIP20 internal constant THETA_USD = ITIP20(THETA_USD_ADDRESS);
    ITIP20 internal constant OUSD = ITIP20(OUSD_ADDRESS);
}
