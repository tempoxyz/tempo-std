// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

/// @title Zone Factory Precompile Interface (TIP-1091)
/// @notice Deployed at `StdPrecompiles.ZONE_FACTORY_ADDRESS` from Hardfork T10.
interface IZoneFactory {
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

    /// @notice Parameters required to deploy and initialize a new Zone.
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
