// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

/// @title Native ZoneFactory interface (TIP-1091)
/// @notice Creates native zones and records their metadata.
interface IZoneFactory {
    /// @notice Parameters for creating a new zone.
    struct CreateZoneParams {
        address initialToken;
        bool accessMode;
        bool gatewayMode;
        address[] allowedAccounts;
        address[] zoneGateways;
        address admin;
        address[] sequencers;
        uint8 threshold;
        string rpcUrl;
    }

    /// @notice Zone metadata recorded by the native factory.
    struct ZoneInfo {
        uint32 zoneId;
        address portal;
        bool accessMode;
        bool gatewayMode;
        address admin;
        address[] sequencers;
        uint8 threshold;
        address verifier;
        string rpcUrl;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    event ZoneCreated(
        uint32 indexed zoneId,
        address indexed portal,
        address initialToken,
        bool accessMode,
        bool gatewayMode,
        address admin,
        address[] sequencers,
        uint8 threshold,
        address verifier
    );

    error InvalidToken();
    error TokenTransferPolicyNotSet();
    error InvalidClosedLoopConfig();
    error NotOwner();
    error InvalidAdmin();
    error InvalidSequencerSet();
    error AlreadyInitialized();
    error TokenMetadataTooLong();

    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;

    function createZone(CreateZoneParams calldata params) external returns (uint32 zoneId, address portal);

    function nextZoneId() external view returns (uint32);

    function zones(uint32 id) external view returns (ZoneInfo memory info);

    function isZonePortal(address portal) external view returns (bool);
}

/// @title Minimal ZonePortal interface (TIP-1091)
/// @notice Minimal portal ABI needed for constructor-equivalent native initialization.
interface IZonePortal {
    enum Role {
        None,
        Sequencer,
        Account,
        CallbackGateway,
        PauseGuardian
    }

    enum Capability {
        PausePortal,
        AccessPolicy
    }

    event SequencerSetUpdated(uint64 indexed nonce, uint8 threshold, address[] sequencers);
    event TokenEnabled(address indexed token, string name, string symbol, string currency);
    event RoleUpdated(address indexed account, Role prev, Role next);
    event EnforcementModesUpdated(bool accessMode, bool gatewayMode);
    event LeaderUpdated(
        address indexed previousLeader,
        address indexed newLeader,
        uint64 indexed leaderEpoch,
        uint64 leaderActivationTempoBlock
    );
}
