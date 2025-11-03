// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @title Interface for TIP20RewardsRegistry
/// @notice Registry contract for all TIP20 reward streams
interface ITIP20RewardsRegistry {
    /// Finalize streams for all tokens ending at the current timestamp
    function finalizeStreams() external;

    /// Add a token to the registry for a given stream end time
    function addStream(address token, uint128 endTime) external;

    error Unauthorized();
    error StreamsAlreadyFinalized();
}
