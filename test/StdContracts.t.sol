// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {StdContracts} from "../src/StdContracts.sol";

contract StdContractsTest is Test {
    function test_interfaceBindings() public pure {
        assertEq(address(StdContracts.MULTICALL3), StdContracts.MULTICALL3_ADDRESS);
        assertEq(address(StdContracts.CREATEX), StdContracts.CREATEX_ADDRESS);
        assertEq(address(StdContracts.PERMIT2), StdContracts.PERMIT2_ADDRESS);
    }
}
