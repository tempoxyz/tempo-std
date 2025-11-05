// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @title Interface for TIP20RewardsRegistry
/// @notice Registry contract for all TIP20 reward streams
interface ITIP20RewardsRegistry {
    error Unauthorized();
    error StreamsAlreadyFinalized();

    /// @notice Add a token to the registry for a given stream end time
    function addStream(uint128 endTime) external;

    /// @notice Remove a stream before it ends (for cancellation)
    function removeStream(uint128 endTime) external;

    /// @notice Finalize streams for all tokens ending at the current timestamp
    function finalizeStreams() external;
}
