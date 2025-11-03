// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

/// @title The interface for TIP-4217 currency registry
/// @notice Registry for managing currency identifiers and their decimal precision according to ISO 4217 standard
interface ITIP4217Registry {
    /// @notice Returns the number of decimal places for a given currency
    /// @param currency The currency identifier (e.g., "USD", "EUR", "JPY")
    /// @return The number of decimal places used by the specified currency
    function getCurrencyDecimals(string calldata currency) external view returns (uint8);
}
