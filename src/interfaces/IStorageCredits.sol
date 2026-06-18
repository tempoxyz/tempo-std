// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

/// @title Storage Credits Precompile
/// @notice Tracks storage credits that can refund, preserve, or directly spend storage-clearing
/// credits for an account.
/// @dev Deployed at `StdPrecompiles.STORAGE_CREDITS_ADDRESS`.
interface IStorageCredits {
    /// @notice Controls how an account handles storage credits during execution.
    enum Mode {
        /// @notice Refund cleared storage as gas according to the active protocol rules.
        Refund,
        /// @notice Preserve cleared storage credits on the account balance.
        Preserve,
        /// @notice Spend from the account's storage credit budget before charging gas.
        Direct
    }

    /// @notice Reverts when the requested mode is not supported by the precompile.
    error InvalidMode();

    /// @notice Reverts when a function is invoked through an unsupported call context.
    error OnlyDirectCall();

    /// @notice Returns the preserved storage credit balance for an account.
    /// @param account Account to query.
    /// @return Preserved storage credits held by `account`.
    function balanceOf(address account) external view returns (uint64);

    /// @notice Returns the active storage credit mode for an account.
    /// @param account Account to query.
    /// @return Active storage credit mode for `account`.
    function modeOf(address account) external view returns (Mode);

    /// @notice Returns the current storage credit spend budget for an account.
    /// @param account Account to query.
    /// @return Storage credits available for direct spending by `account`.
    function budgetOf(address account) external view returns (uint64);

    /// @notice Sets the caller's storage credit mode.
    /// @param newMode New mode to apply to the caller.
    function setMode(Mode newMode) external;

    /// @notice Sets the caller's direct-spend storage credit budget.
    /// @param credits Number of storage credits to make available for direct spending.
    function setBudget(uint64 credits) external;
}
