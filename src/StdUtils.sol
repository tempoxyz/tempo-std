// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ITIP20Factory} from "./interfaces/ITIP20Factory.sol";
import {StdPrecompiles} from "./StdPrecompiles.sol";

/// @title Standard Utils Library for Tempo
///
/// @notice <https://github.com/tempoxyz/tempo/blob/main/crates/precompiles/src/tip20/mod.rs>
library StdUtils {
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

    /// @notice Checks if an address is a TIP20 token created by the default factory
    /// @param token The address to check
    /// @return True if the token was created by the factory
    function isTIP20(address token) internal view returns (bool) {
        return StdPrecompiles.TIP20_FACTORY.isTIP20(token);
    }

    /// @notice Checks if an address is a TIP20 token created by a specific factory
    /// @param factory The TIP20 factory address
    /// @param token The address to check
    /// @return True if the token was created by the factory
    function isTIP20(address factory, address token) internal view returns (bool) {
        return ITIP20Factory(factory).isTIP20(token);
    }
}
