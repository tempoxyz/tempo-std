// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {StdTIP20} from "../src/StdTIP20.sol";
import {StdTokens} from "../src/StdTokens.sol";

contract StdTIP20Test is Test {
    function test_knownTokens_haveTIP20Prefix() public pure {
        assertTrue(StdTIP20.isTIP20Prefix(StdTokens.PATH_USD_ADDRESS));
        assertTrue(StdTIP20.isTIP20Prefix(StdTokens.ALPHA_USD_ADDRESS));
        assertTrue(StdTIP20.isTIP20Prefix(StdTokens.BETA_USD_ADDRESS));
        assertTrue(StdTIP20.isTIP20Prefix(StdTokens.THETA_USD_ADDRESS));
    }

    function testFuzz_isTIP20Prefix(address token) public pure {
        bool expected = bytes12(bytes20(token)) == StdTIP20.TIP20_TOKEN_PREFIX;
        assertEq(StdTIP20.isTIP20Prefix(token), expected);
    }
}
