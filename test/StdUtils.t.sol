// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {StdUtils} from "../src/StdUtils.sol";
import {StdTokens} from "../src/StdTokens.sol";

contract StdUtilsTest is Test {
    function test_knownTokens_haveTIP20Prefix() public pure {
        assertTrue(StdUtils.hasTIP20Prefix(StdTokens.PATH_USD_ADDRESS));
        assertTrue(StdUtils.hasTIP20Prefix(StdTokens.ALPHA_USD_ADDRESS));
        assertTrue(StdUtils.hasTIP20Prefix(StdTokens.BETA_USD_ADDRESS));
        assertTrue(StdUtils.hasTIP20Prefix(StdTokens.THETA_USD_ADDRESS));
    }

    function testFuzz_hasTIP20Prefix(address token) public pure {
        bool expected = bytes12(bytes20(token)) == StdUtils.TIP20_TOKEN_PREFIX;
        assertEq(StdUtils.hasTIP20Prefix(token), expected);
    }
}
