// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ITIPAccountRegistrar {
    error InvalidSignature();
    error CodeNotEmpty();
    error NonceNotZero();

    function delegateToDefault(bytes32 hash, bytes calldata signature) external returns (address authority);
}
