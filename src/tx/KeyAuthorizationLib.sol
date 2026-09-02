// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

import {IAccountKeychain} from "../interfaces/IAccountKeychain.sol";
import {SignatureLib} from "../sig/SignatureLib.sol";
import {TxRlp} from "./TxRlp.sol";

/// @notice A TIP-1099 authorization for provisioning an access key through a Tempo transaction.
/// @dev Optional fields are represented explicitly so `None` remains distinct from an empty list
///      and a zero-valued witness remains distinct from an absent witness.
struct KeyAuthorization {
    uint64 chainId;
    IAccountKeychain.SignatureType keyType;
    address keyId;
    bool hasExpiry;
    uint64 expiry;
    bool hasLimits;
    IAccountKeychain.TokenLimit[] limits;
    bool hasAllowedCalls;
    IAccountKeychain.CallScope[] allowedCalls;
    bool hasWitness;
    bytes32 witness;
    bool isAdmin;
    bool hasAccount;
    address account;
}

/// @title Builder, RLP encoder, and Foundry signer for TIP-1099 key authorizations.
/// @dev The wire format matches Tempo's `KeyAuthorization` and `SignedKeyAuthorization` types:
///      `[chain_id, key_type, key_id, expiry?, limits?, allowed_calls?, witness?, is_admin?, account?]`
///      and `[authorization, signature]` respectively. Optional trailing fields are omitted
///      canonically; absent fields preceding a present field are encoded as empty strings.
library KeyAuthorizationLib {
    /// @notice Creates an unrestricted, non-expiring access-key authorization.
    function create(uint64 chainId, IAccountKeychain.SignatureType keyType, address keyId)
        internal
        pure
        returns (KeyAuthorization memory authorization)
    {
        authorization.chainId = chainId;
        authorization.keyType = keyType;
        authorization.keyId = keyId;
    }

    /// @notice Creates an authorization from the legacy key-restrictions representation.
    /// @dev `type(uint64).max` maps to no expiry, `enforceLimits == false` to unlimited spending,
    ///      and `allowAnyCalls == true` to unrestricted calls.
    function fromRestrictions(
        uint64 chainId,
        IAccountKeychain.SignatureType keyType,
        address keyId,
        IAccountKeychain.KeyRestrictions memory restrictions
    ) internal pure returns (KeyAuthorization memory authorization) {
        authorization = create(chainId, keyType, keyId);
        if (restrictions.expiry != type(uint64).max) {
            authorization = withExpiry(authorization, restrictions.expiry);
        }
        if (restrictions.enforceLimits) {
            authorization = withLimits(authorization, restrictions.limits);
        }
        if (!restrictions.allowAnyCalls) {
            authorization = withAllowedCalls(authorization, restrictions.allowedCalls);
        }
    }

    function withExpiry(KeyAuthorization memory self, uint64 expiry) internal pure returns (KeyAuthorization memory) {
        require(expiry != 0, "KeyAuthorizationLib: zero expiry");
        self.hasExpiry = true;
        self.expiry = expiry;
        return self;
    }

    function withLimits(KeyAuthorization memory self, IAccountKeychain.TokenLimit[] memory limits)
        internal
        pure
        returns (KeyAuthorization memory)
    {
        self.hasLimits = true;
        self.limits = limits;
        return self;
    }

    function withAllowedCalls(KeyAuthorization memory self, IAccountKeychain.CallScope[] memory allowedCalls)
        internal
        pure
        returns (KeyAuthorization memory)
    {
        self.hasAllowedCalls = true;
        self.allowedCalls = allowedCalls;
        return self;
    }

    function withWitness(KeyAuthorization memory self, bytes32 witness)
        internal
        pure
        returns (KeyAuthorization memory)
    {
        self.hasWitness = true;
        self.witness = witness;
        return self;
    }

    /// @notice Marks an authorization as an admin key bound to `account`.
    function asAdmin(KeyAuthorization memory self, address account) internal pure returns (KeyAuthorization memory) {
        self.isAdmin = true;
        self.hasAccount = true;
        self.account = account;
        return self;
    }

    /// @notice Binds a non-admin authorization to `account`.
    function withAccount(KeyAuthorization memory self, address account)
        internal
        pure
        returns (KeyAuthorization memory)
    {
        self.hasAccount = true;
        self.account = account;
        return self;
    }

    /// @notice Returns the canonical RLP encoding signed by a key-authorization signer.
    function encode(KeyAuthorization memory self) internal pure returns (bytes memory) {
        uint256 fieldCount = _fieldCount(self);
        bytes[] memory fields = new bytes[](fieldCount);
        fields[0] = TxRlp.encodeString(TxRlp.encodeUint(self.chainId));
        fields[1] = TxRlp.encodeString(TxRlp.encodeUint(uint8(self.keyType)));
        fields[2] = TxRlp.encodeString(TxRlp.encodeAddress(self.keyId));

        if (fieldCount > 3) {
            fields[3] = TxRlp.encodeString(self.hasExpiry ? TxRlp.encodeUint(self.expiry) : TxRlp.encodeNone());
        }
        if (fieldCount > 4) {
            fields[4] = self.hasLimits ? _encodeLimits(self.limits) : TxRlp.encodeString(TxRlp.encodeNone());
        }
        if (fieldCount > 5) {
            fields[5] =
                self.hasAllowedCalls ? _encodeAllowedCalls(self.allowedCalls) : TxRlp.encodeString(TxRlp.encodeNone());
        }
        if (fieldCount > 6) {
            fields[6] = self.hasWitness
                ? TxRlp.encodeString(TxRlp.encodeBytes32Full(self.witness))
                : TxRlp.encodeString(TxRlp.encodeNone());
        }
        if (fieldCount > 7) {
            fields[7] = TxRlp.encodeString(self.isAdmin ? TxRlp.encodeUint(1) : TxRlp.encodeNone());
        }
        if (fieldCount > 8) {
            fields[8] = self.hasAccount
                ? TxRlp.encodeString(TxRlp.encodeAddress(self.account))
                : TxRlp.encodeString(TxRlp.encodeNone());
        }

        return TxRlp.encodeRawList(fields);
    }

    /// @notice Computes the hash that authorizes this key configuration.
    function signingHash(KeyAuthorization memory self) internal pure returns (bytes32) {
        return keccak256(encode(self));
    }

    /// @notice Encodes a signed key authorization from an already encoded primitive signature.
    /// @dev `signature` uses Tempo's primitive-signature format; secp256k1 is `r || s || v`.
    function encodeSigned(KeyAuthorization memory self, bytes memory signature) internal pure returns (bytes memory) {
        bytes[] memory fields = new bytes[](2);
        fields[0] = encode(self);
        fields[1] = TxRlp.encodeString(signature);
        return TxRlp.encodeRawList(fields);
    }

    /// @notice Signs and encodes this authorization with a secp256k1 key via Foundry cheatcodes.
    function sign(KeyAuthorization memory self, uint256 privateKey) internal pure returns (bytes memory) {
        return encodeSigned(self, SignatureLib.signSecp(privateKey, signingHash(self)));
    }

    function _fieldCount(KeyAuthorization memory self) private pure returns (uint256) {
        if (self.hasAccount) return 9;
        if (self.isAdmin) return 8;
        if (self.hasWitness) return 7;
        if (self.hasAllowedCalls) return 6;
        if (self.hasLimits) return 5;
        if (self.hasExpiry) return 4;
        return 3;
    }

    function _encodeLimits(IAccountKeychain.TokenLimit[] memory limits) private pure returns (bytes memory) {
        bytes[] memory encoded = new bytes[](limits.length);
        for (uint256 i = 0; i < limits.length; i++) {
            uint256 fieldCount = limits[i].period == 0 ? 2 : 3;
            bytes[] memory fields = new bytes[](fieldCount);
            fields[0] = TxRlp.encodeString(TxRlp.encodeAddress(limits[i].token));
            fields[1] = TxRlp.encodeString(TxRlp.encodeUint(limits[i].amount));
            if (fieldCount == 3) {
                fields[2] = TxRlp.encodeString(TxRlp.encodeUint(limits[i].period));
            }
            encoded[i] = TxRlp.encodeRawList(fields);
        }
        return TxRlp.encodeRawList(encoded);
    }

    function _encodeAllowedCalls(IAccountKeychain.CallScope[] memory scopes) private pure returns (bytes memory) {
        bytes[] memory encoded = new bytes[](scopes.length);
        for (uint256 i = 0; i < scopes.length; i++) {
            bytes[] memory fields = new bytes[](2);
            fields[0] = TxRlp.encodeString(TxRlp.encodeAddress(scopes[i].target));
            fields[1] = _encodeSelectorRules(scopes[i].selectorRules);
            encoded[i] = TxRlp.encodeRawList(fields);
        }
        return TxRlp.encodeRawList(encoded);
    }

    function _encodeSelectorRules(IAccountKeychain.SelectorRule[] memory rules) private pure returns (bytes memory) {
        bytes[] memory encoded = new bytes[](rules.length);
        for (uint256 i = 0; i < rules.length; i++) {
            bytes[] memory fields = new bytes[](2);
            fields[0] = TxRlp.encodeString(abi.encodePacked(rules[i].selector));
            fields[1] = _encodeAddresses(rules[i].recipients);
            encoded[i] = TxRlp.encodeRawList(fields);
        }
        return TxRlp.encodeRawList(encoded);
    }

    function _encodeAddresses(address[] memory addresses) private pure returns (bytes memory) {
        bytes[] memory encoded = new bytes[](addresses.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            encoded[i] = TxRlp.encodeString(TxRlp.encodeAddress(addresses[i]));
        }
        return TxRlp.encodeRawList(encoded);
    }
}
