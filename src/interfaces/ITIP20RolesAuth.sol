// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

interface ITIP20RolesAuth {
    /// @notice Thrown when the caller lacks the required role for the requested action
    error Unauthorized();

    event RoleMembershipUpdated(bytes32 indexed role, address indexed account, address indexed sender, bool hasRole);
    event RoleAdminUpdated(bytes32 indexed role, bytes32 indexed newAdminRole, address indexed sender);

    function hasRole(address account, bytes32 role) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role) external;

    function setRoleAdmin(bytes32 role, bytes32 adminRole) external;
}
