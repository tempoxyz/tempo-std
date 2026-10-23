// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

/// @title Zone Portal Interface (TIP-1091)
/// @notice Minimal portal interface for Zone state management and event subscriptions.
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
