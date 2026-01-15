// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @title Standard TIP20 Library for Tempo
///
/// @notice <https://github.com/tempoxyz/tempo/blob/main/crates/precompiles/src/tip20/mod.rs>
library StdTIP20 {
    /// @notice TIP20 token address prefix (first 12 bytes)
    /// @dev Full address format: TIP20_TOKEN_PREFIX (12 bytes) || derived_bytes (8 bytes)
    bytes12 internal constant TIP20_TOKEN_PREFIX = 0x20C000000000000000000000;

    /// @notice Checks if an address has the TIP20 prefix
    /// @dev This only checks the prefix, not whether the token was actually created.
    ///      Use `ITIP20Factory.isTIP20()` for full validation.
    /// @param token The address to check
    /// @return True if the address has the TIP20 prefix
    function isTIP20Prefix(address token) internal pure returns (bool) {
        return bytes12(bytes20(token)) == TIP20_TOKEN_PREFIX;
    }
}
