// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {StdPrecompiles} from "../src/StdPrecompiles.sol";

contract StdPrecompilesTest is Test {
    function test_interfaceBindings() public pure {
        assertEq(address(StdPrecompiles.TIP_FEE_MANAGER), StdPrecompiles.TIP_FEE_MANAGER_ADDRESS);
        assertEq(address(StdPrecompiles.TIP403_REGISTRY), StdPrecompiles.TIP403_REGISTRY_ADDRESS);
        assertEq(address(StdPrecompiles.TIP20_FACTORY), StdPrecompiles.TIP20_FACTORY_ADDRESS);
        assertEq(address(StdPrecompiles.TIP20_REWARDS_REGISTRY), StdPrecompiles.TIP20_REWARDS_REGISTRY_ADDRESS);
        assertEq(address(StdPrecompiles.STABLECOIN_DEX), StdPrecompiles.STABLECOIN_DEX_ADDRESS);
        assertEq(address(StdPrecompiles.NONCE_PRECOMPILE), StdPrecompiles.NONCE_ADDRESS);
        assertEq(address(StdPrecompiles.VALIDATOR_CONFIG), StdPrecompiles.VALIDATOR_CONFIG_ADDRESS);
        assertEq(address(StdPrecompiles.ACCOUNT_KEYCHAIN), StdPrecompiles.ACCOUNT_KEYCHAIN_ADDRESS);
    }
}
