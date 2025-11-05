// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IFeeManager {
    event ValidatorTokenSet(address indexed validator, address indexed token);
    event UserTokenSet(address indexed user, address indexed token);
}
