// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {StdTokens} from "../src/StdTokens.sol";

contract StdTokensTest is Test {
    function test_interfaceBindings() public pure {
        assertEq(address(StdTokens.PATH_USD), StdTokens.PATH_USD_ADDRESS);
        assertEq(address(StdTokens.ALPHA_USD), StdTokens.ALPHA_USD_ADDRESS);
        assertEq(address(StdTokens.BETA_USD), StdTokens.BETA_USD_ADDRESS);
        assertEq(address(StdTokens.THETA_USD), StdTokens.THETA_USD_ADDRESS);
    }
}
