// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IFeeManager} from "./interfaces/IFeeManager.sol";
import {ILinkingUSD} from "./interfaces/ILinkingUSD.sol";
import {ITIP20} from "./interfaces/ITIP20.sol";
import {ITIP403Registry} from "./interfaces/ITIP403Registry.sol";
import {ITIP20Factory} from "./interfaces/ITIP20Factory.sol";
import {ITIP20RewardsRegistry} from "./interfaces/ITIP20RewardsRegistry.sol";
import {ITIPAccountRegistrar} from "./interfaces/ITIPAccountRegistrar.sol";
import {IStablecoinExchange} from "./interfaces/IStablecoinExchange.sol";
import {INonce} from "./interfaces/INonce.sol";

/// @title Standard Precompiles Library for Tempo
///
/// @notice <https://github.com/tempoxyz/tempo/blob/main/crates/contracts/src/precompiles/mod.rs>
library StdPrecompiles {
    address internal constant TIP_FEE_MANAGER_ADDRESS = 0xfeEC000000000000000000000000000000000000;
    address internal constant LINKING_USD_ADDRESS = 0x20C0000000000000000000000000000000000000;
    address internal constant DEFAULT_FEE_TOKEN = 0x20C0000000000000000000000000000000000001;
    address internal constant TIP403_REGISTRY_ADDRESS = 0x403c000000000000000000000000000000000000;
    address internal constant TIP20_FACTORY_ADDRESS = 0x20Fc000000000000000000000000000000000000;
    address internal constant TIP20_REWARDS_REGISTRY_ADDRESS = 0x2100000000000000000000000000000000000000;
    address internal constant TIP_ACCOUNT_REGISTRAR = 0x7702ac0000000000000000000000000000000000;
    address internal constant STABLECOIN_EXCHANGE_ADDRESS = 0xDEc0000000000000000000000000000000000000;
    address internal constant NONCE_ADDRESS = 0x4e4F4E4345000000000000000000000000000000;
    address internal constant VALIDATOR_CONFIG_ADDRESS = 0xCccCcCCC00000000000000000000000000000000;

    IFeeManager internal constant TIP_FEE_MANAGER = IFeeManager(TIP_FEE_MANAGER_ADDRESS);
    ILinkingUSD internal constant LINKING_USD = ILinkingUSD(LINKING_USD_ADDRESS);
    ITIP20 internal constant DEFAULT_FEE_TOKEN_CONTRACT = ITIP20(DEFAULT_FEE_TOKEN);
    ITIP403Registry internal constant TIP403_REGISTRY = ITIP403Registry(TIP403_REGISTRY_ADDRESS);
    ITIP20Factory internal constant TIP20_FACTORY = ITIP20Factory(TIP20_FACTORY_ADDRESS);
    ITIP20RewardsRegistry internal constant TIP20_REWARDS_REGISTRY =
        ITIP20RewardsRegistry(TIP20_REWARDS_REGISTRY_ADDRESS);
    ITIPAccountRegistrar internal constant TIP_ACCOUNT_REGISTRAR_CONTRACT = ITIPAccountRegistrar(TIP_ACCOUNT_REGISTRAR);
    IStablecoinExchange internal constant STABLECOIN_EXCHANGE = IStablecoinExchange(STABLECOIN_EXCHANGE_ADDRESS);
    INonce internal constant NONCE_PRECOMPILE = INonce(NONCE_ADDRESS);
}
