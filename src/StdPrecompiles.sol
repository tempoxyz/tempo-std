// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

import {IAccountKeychain} from "./interfaces/IAccountKeychain.sol";
import {IFeeManager} from "./interfaces/IFeeManager.sol";
import {ITIP403Registry} from "./interfaces/ITIP403Registry.sol";
import {ITIP20Factory} from "./interfaces/ITIP20Factory.sol";
import {ITIP20RewardsRegistry} from "./interfaces/ITIP20RewardsRegistry.sol";
import {IStablecoinDEX} from "./interfaces/IStablecoinDEX.sol";
import {IValidatorConfig} from "./interfaces/IValidatorConfig.sol";
import {INonce} from "./interfaces/INonce.sol";

/// @title Standard Precompiles Library for Tempo
///
/// @notice <https://github.com/tempoxyz/tempo/blob/main/crates/contracts/src/precompiles/mod.rs>
library StdPrecompiles {
    address internal constant TIP_FEE_MANAGER_ADDRESS = 0xfeEC000000000000000000000000000000000000;
    address internal constant TIP403_REGISTRY_ADDRESS = 0x403c000000000000000000000000000000000000;
    address internal constant TIP20_FACTORY_ADDRESS = 0x20Fc000000000000000000000000000000000000;
    address internal constant TIP20_REWARDS_REGISTRY_ADDRESS = 0x2100000000000000000000000000000000000000;
    address internal constant STABLECOIN_DEX_ADDRESS = 0xDEc0000000000000000000000000000000000000;
    address internal constant NONCE_ADDRESS = 0x4e4F4E4345000000000000000000000000000000;
    address internal constant VALIDATOR_CONFIG_ADDRESS = 0xCccCcCCC00000000000000000000000000000000;
    address internal constant ACCOUNT_KEYCHAIN_ADDRESS = 0xaAAAaaAA00000000000000000000000000000000;

    IFeeManager internal constant TIP_FEE_MANAGER = IFeeManager(TIP_FEE_MANAGER_ADDRESS);
    ITIP403Registry internal constant TIP403_REGISTRY = ITIP403Registry(TIP403_REGISTRY_ADDRESS);
    ITIP20Factory internal constant TIP20_FACTORY = ITIP20Factory(TIP20_FACTORY_ADDRESS);
    ITIP20RewardsRegistry internal constant TIP20_REWARDS_REGISTRY =
        ITIP20RewardsRegistry(TIP20_REWARDS_REGISTRY_ADDRESS);
    IStablecoinDEX internal constant STABLECOIN_DEX = IStablecoinDEX(STABLECOIN_DEX_ADDRESS);
    INonce internal constant NONCE_PRECOMPILE = INonce(NONCE_ADDRESS);
    IValidatorConfig internal constant VALIDATOR_CONFIG = IValidatorConfig(VALIDATOR_CONFIG_ADDRESS);
    IAccountKeychain internal constant ACCOUNT_KEYCHAIN = IAccountKeychain(ACCOUNT_KEYCHAIN_ADDRESS);
}
