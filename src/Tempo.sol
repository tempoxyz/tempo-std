// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

import {StdPrecompiles} from "./StdPrecompiles.sol";
import {StdTokens} from "./StdTokens.sol";
import {IAccountKeychain} from "./interfaces/IAccountKeychain.sol";
import {IAddressRegistry} from "./interfaces/IAddressRegistry.sol";
import {ICurrentCommittee} from "./interfaces/ICurrentCommittee.sol";
import {IFeeManager} from "./interfaces/IFeeManager.sol";
import {INonce} from "./interfaces/INonce.sol";
import {ISignatureVerifier} from "./interfaces/ISignatureVerifier.sol";
import {IStablecoinDEX} from "./interfaces/IStablecoinDEX.sol";
import {IStorageCredits} from "./interfaces/IStorageCredits.sol";
import {ITIP20} from "./interfaces/ITIP20.sol";
import {ITIP20Factory} from "./interfaces/ITIP20Factory.sol";
import {ITIP403Registry} from "./interfaces/ITIP403Registry.sol";
import {IReceivePolicyGuard} from "./interfaces/IReceivePolicyGuard.sol";
import {IValidatorConfig} from "./interfaces/IValidatorConfig.sol";
import {IValidatorConfigV2} from "./interfaces/IValidatorConfigV2.sol";
import {IZoneFactory} from "./interfaces/IZoneFactory.sol";

abstract contract Tempo {
    // Nonce precompile
    INonce public constant nonce = StdPrecompiles.NONCE_PRECOMPILE;
    address public constant NONCE = StdPrecompiles.NONCE_ADDRESS;

    // Account keychain precompile
    IAccountKeychain public constant keychain = StdPrecompiles.ACCOUNT_KEYCHAIN;
    address public constant KEYCHAIN = StdPrecompiles.ACCOUNT_KEYCHAIN_ADDRESS;

    // Stablecoin DEX precompile
    IStablecoinDEX public constant stableDEX = StdPrecompiles.STABLECOIN_DEX;
    address public constant STABLE_DEX = StdPrecompiles.STABLECOIN_DEX_ADDRESS;

    // Storage credits precompile
    IStorageCredits public constant storageCredits = StdPrecompiles.STORAGE_CREDITS;
    address public constant STORAGE_CREDITS = StdPrecompiles.STORAGE_CREDITS_ADDRESS;

    // Current committee precompile
    ICurrentCommittee public constant currentCommittee = StdPrecompiles.CURRENT_COMMITTEE;
    address public constant CURRENT_COMMITTEE = StdPrecompiles.CURRENT_COMMITTEE_ADDRESS;

    // Zone factory precompile
    IZoneFactory public constant zoneFactory = StdPrecompiles.ZONE_FACTORY;
    address public constant ZONE_FACTORY = StdPrecompiles.ZONE_FACTORY_ADDRESS;

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
    ITIP403Registry public constant tip403Registry = StdPrecompiles.TIP403_REGISTRY;
    address public constant TIP403_REGISTRY = StdPrecompiles.TIP403_REGISTRY_ADDRESS;

    // Receive policy guard precompile
    IReceivePolicyGuard public constant receivePolicyGuard = StdPrecompiles.RECEIVE_POLICY_GUARD;
    address public constant RECEIVE_POLICY_GUARD = StdPrecompiles.RECEIVE_POLICY_GUARD_ADDRESS;

    // Address registry precompile
    IAddressRegistry public constant addrRegistry = StdPrecompiles.ADDRESS_REGISTRY;
    address public constant ADDRESS_REGISTRY = StdPrecompiles.ADDRESS_REGISTRY_ADDRESS;

    // TIP-20 factory precompile
    ITIP20Factory public constant tip20Factory = StdPrecompiles.TIP20_FACTORY;
    address public constant TIP20_FACTORY = StdPrecompiles.TIP20_FACTORY_ADDRESS;

    // pathUSD is just a TIP20 at a special address (0x20C0...) with token_id=0
    ITIP20 public constant pathUSD = StdTokens.PATH_USD;
    address public constant PATH_USD = StdTokens.PATH_USD_ADDRESS;
}
