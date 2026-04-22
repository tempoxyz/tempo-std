// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

import {StdPrecompiles} from "./StdPrecompiles.sol";
import {StdTokens} from "./StdTokens.sol";
import {IAccountKeychain} from "./interfaces/IAccountKeychain.sol";
import {IAddressRegistry} from "./interfaces/IAddressRegistry.sol";
import {IFeeManager} from "./interfaces/IFeeManager.sol";
import {INonce} from "./interfaces/INonce.sol";
import {ISignatureVerifier} from "./interfaces/ISignatureVerifier.sol";
import {IStablecoinDEX} from "./interfaces/IStablecoinDEX.sol";
import {ITIP20} from "./interfaces/ITIP20.sol";
import {ITIP20Factory} from "./interfaces/ITIP20Factory.sol";
import {ITIP403Registry} from "./interfaces/ITIP403Registry.sol";
import {IValidatorConfig} from "./interfaces/IValidatorConfig.sol";
import {IValidatorConfigV2} from "./interfaces/IValidatorConfigV2.sol";

abstract contract StdBase {
    // Nonce precompile
    INonce public constant nonce = StdPrecompiles.NONCE_PRECOMPILE;
    address public constant NONCE = StdPrecompiles.NONCE_ADDRESS;

    // Account keychain precompile
    IAccountKeychain public constant keychain = StdPrecompiles.ACCOUNT_KEYCHAIN;
    address public constant KEYCHAIN = StdPrecompiles.ACCOUNT_KEYCHAIN_ADDRESS;

    // Stablecoin DEX precompile
    IStablecoinDEX public constant stableDEX = StdPrecompiles.STABLECOIN_DEX;
    address public constant STABLE_DEX = StdPrecompiles.STABLECOIN_DEX_ADDRESS;

    // Fee manager precompile
    IFeeManager public constant feeAMM = StdPrecompiles.TIP_FEE_MANAGER;
    address public constant FEE_AMM = StdPrecompiles.TIP_FEE_MANAGER_ADDRESS;

    // Validator config precompile
    IValidatorConfig public constant validatorConfig = StdPrecompiles.VALIDATOR_CONFIG;
    address public constant VALIDATOR_CONFIG = StdPrecompiles.VALIDATOR_CONFIG_ADDRESS;

    // Validator config v2 precompile
    IValidatorConfigV2 public constant validatorConfigV2 = StdPrecompiles.VALIDATOR_CONFIG_V2;
    address public constant VALIDATOR_CONFIG_V2 = StdPrecompiles.VALIDATOR_CONFIG_V2_ADDRESS;

    // Signature verifier precompile
    ISignatureVerifier public constant signatureVerifier = StdPrecompiles.SIGNATURE_VERIFIER;
    address public constant SIGNATURE_VERIFIER = StdPrecompiles.SIGNATURE_VERIFIER_ADDRESS;

    // TIP-403 registry precompile
    ITIP403Registry public constant registry = StdPrecompiles.TIP403_REGISTRY;
    address public constant REGISTRY = StdPrecompiles.TIP403_REGISTRY_ADDRESS;

    // TIP-20 address registry precompile
    IAddressRegistry public constant tip20Registry = StdPrecompiles.ADDRESS_REGISTRY;
    address public constant TIP20_REGISTRY = StdPrecompiles.ADDRESS_REGISTRY_ADDRESS;

    // TIP-20 factory precompile
    ITIP20Factory public constant tip20Factory = StdPrecompiles.TIP20_FACTORY;
    address public constant TIP20_FACTORY = StdPrecompiles.TIP20_FACTORY_ADDRESS;

    // pathUSD is just a TIP20 at a special address (0x20C0...) with token_id=0
    ITIP20 public constant pathUSD = StdTokens.PATH_USD;
    address public constant PATH_USD = StdTokens.PATH_USD_ADDRESS;
}
