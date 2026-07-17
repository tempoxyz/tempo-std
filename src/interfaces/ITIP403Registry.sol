// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

/// @title The interface for TIP-403 transfer policy registry
/// @notice Registry for managing transfer policies that control which addresses can send or receive tokens
interface ITIP403Registry {
    /// @notice Policy types available for transfer restrictions
    /// @param WHITELIST Only addresses on the whitelist are authorized for transfers
    /// @param BLACKLIST All addresses except those on the blacklist are authorized for transfers
    /// @param COMPOUND TIP-1015: Compound policy referencing three simple policies
    enum PolicyType {
        WHITELIST,
        BLACKLIST,
        COMPOUND
    }

    /// @notice Reasons an inbound transfer can be blocked by a receive policy
    /// @param NONE The transfer is not blocked
    /// @param TOKEN_FILTER The token is not allowed by the token filter policy
    /// @param RECEIVE_POLICY The sender is not allowed by the receive policy
    enum BlockedReason {
        NONE,
        TOKEN_FILTER,
        RECEIVE_POLICY
    }

    /// @notice Data structure containing policy configuration
    /// @param policyType The type of policy (whitelist or blacklist)
    /// @param admin The address authorized to modify this policy
    struct PolicyData {
        PolicyType policyType;
        address admin;
    }

    /// @notice Error when caller lacks authorization to perform the requested action
    error Unauthorized();

    /// @notice Error when querying a policy that does not exist
    error PolicyNotFound();

    /// @notice TIP-1015: Error when a compound policy references a non-simple policy
    error PolicyNotSimple();

    /// @notice Error when attempting to operate on a policy with incompatible type
    error IncompatiblePolicyType();

    /// @notice Error when policy has an invalid type
    error InvalidPolicyType();

    /// @notice TIP-1022 virtual addresses cannot be used as literal policy members
    error VirtualAddressNotAllowed();

    /// @notice Error when a receive policy references an incompatible policy type
    error InvalidReceivePolicyType();

    /// @notice Error when the recovery authority address is invalid
    error InvalidRecoveryAuthority();

    /// @notice Emitted when a policy's admin is updated
    /// @param policyId The ID of the policy that was updated
    /// @param updater The address that performed the update
    /// @param admin The new admin address for the policy
    event PolicyAdminUpdated(uint64 indexed policyId, address indexed updater, address indexed admin);

    /// @notice Emitted when a new policy is created
    /// @param policyId The ID of the newly created policy
    /// @param updater The address that created the policy
    /// @param policyType The type of policy that was created
    event PolicyCreated(uint64 indexed policyId, address indexed updater, PolicyType policyType);

    /// @notice Emitted when a whitelist policy is modified
    /// @param policyId The ID of the whitelist policy that was updated
    /// @param updater The address that performed the update
    /// @param account The account whose whitelist status was changed
    /// @param allowed Whether the account is now allowed (true) or not (false)
    event WhitelistUpdated(uint64 indexed policyId, address indexed updater, address indexed account, bool allowed);

    /// @notice Emitted when a blacklist policy is modified
    /// @param policyId The ID of the blacklist policy that was updated
    /// @param updater The address that performed the update
    /// @param account The account whose blacklist status was changed
    /// @param restricted Whether the account is now restricted (true) or not (false)
    event BlacklistUpdated(uint64 indexed policyId, address indexed updater, address indexed account, bool restricted);

    /// @notice Returns the current policy ID counter
    /// @return The next policy ID that will be assigned to a newly created policy
    function policyIdCounter() external view returns (uint64);

    /// @notice Returns whether a policy exists
    /// @param policyId The ID of the policy to check
    /// @return True if the policy exists, false otherwise
    function policyExists(uint64 policyId) external view returns (bool);

    /// @notice Returns the effective transfer policy for a TIP-20 token
    /// @param token The TIP-20 token to query
    /// @return isSet Whether TIP-403 stores the token's policy binding
    /// @return policyId The registry binding, or the legacy token-local policy ID when unset
    function tokenTransferPolicyId(address token) external view returns (bool isSet, uint64 policyId);

    /// @notice Migrates legacy token-local policy IDs into TIP-403
    /// @param tokens The TIP-20 tokens to migrate
    /// @return migrated The number of bindings created
    function migrateTransferPolicyIds(address[] calldata tokens) external returns (uint256 migrated);

    /// @notice Returns the policy data for a given policy ID
    /// @param policyId The ID of the policy to query
    /// @return policyType The type of the policy (whitelist or blacklist)
    /// @return admin The admin address of the policy
    function policyData(uint64 policyId) external view returns (PolicyType policyType, address admin);

    /// @notice Creates a new transfer policy without initial accounts
    /// @param admin The address to be assigned as the admin of the new policy
    /// @param policyType The type of policy to create (whitelist or blacklist)
    /// @return newPolicyId The ID of the newly created policy
    function createPolicy(address admin, PolicyType policyType) external returns (uint64 newPolicyId);

    /// @notice Creates a new transfer policy with initial accounts
    /// @param admin The address to be assigned as the admin of the new policy
    /// @param policyType The type of policy to create (whitelist or blacklist)
    /// @param accounts The initial accounts to add to the policy list
    /// @return newPolicyId The ID of the newly created policy
    function createPolicyWithAccounts(address admin, PolicyType policyType, address[] calldata accounts)
        external
        returns (uint64 newPolicyId);

    /// @notice Updates the admin address for an existing policy
    /// @param policyId The ID of the policy to update
    /// @param admin The new admin address for the policy
    function setPolicyAdmin(uint64 policyId, address admin) external;

    /// @notice Modifies the whitelist status of an account for a whitelist policy
    /// @param policyId The ID of the whitelist policy to modify
    /// @param account The account to update
    /// @param allowed Whether to allow (true) or disallow (false) the account
    function modifyPolicyWhitelist(uint64 policyId, address account, bool allowed) external;

    /// @notice Modifies the blacklist status of an account for a blacklist policy
    /// @param policyId The ID of the blacklist policy to modify
    /// @param account The account to update
    /// @param restricted Whether to restrict (true) or unrestrict (false) the account
    function modifyPolicyBlacklist(uint64 policyId, address account, bool restricted) external;

    /// @notice Checks if a user is authorized under a specific policy
    /// @param policyId The ID of the policy to check against
    /// @param user The address to check authorization for
    /// @return True if the user is authorized, false otherwise
    function isAuthorized(uint64 policyId, address user) external view returns (bool);

    // =========================================================================
    //                      TIP-1015: Compound Policies
    // =========================================================================

    /// @notice TIP-1015: Emitted when a new compound policy is created
    event CompoundPolicyCreated(
        uint64 indexed policyId,
        address indexed creator,
        uint64 senderPolicyId,
        uint64 recipientPolicyId,
        uint64 mintRecipientPolicyId
    );

    /// @notice Emitted when an account's receive policy is updated
    /// @param account The account whose receive policy was updated
    /// @param senderPolicyId The sender policy ID for the receive policy
    /// @param tokenFilterId The token filter policy ID for the receive policy
    /// @param recoveryAuthority The recovery authority address for blocked receipts
    event ReceivePolicyUpdated(
        address indexed account, uint64 senderPolicyId, uint64 tokenFilterId, address recoveryAuthority
    );

    /// @notice TIP-1015: Creates a new immutable compound policy
    /// @param senderPolicyId Policy ID to check for transfer senders
    /// @param recipientPolicyId Policy ID to check for transfer recipients
    /// @param mintRecipientPolicyId Policy ID to check for mint recipients
    /// @return newPolicyId ID of the newly created compound policy
    function createCompoundPolicy(uint64 senderPolicyId, uint64 recipientPolicyId, uint64 mintRecipientPolicyId)
        external
        returns (uint64 newPolicyId);

    /// @notice TIP-1015: Checks if a user is authorized as a sender
    /// @param policyId Policy ID to check against
    /// @param user Address to check
    /// @return True if authorized to send
    function isAuthorizedSender(uint64 policyId, address user) external view returns (bool);

    /// @notice TIP-1015: Checks if a user is authorized as a recipient
    /// @param policyId Policy ID to check against
    /// @param user Address to check
    /// @return True if authorized to receive
    function isAuthorizedRecipient(uint64 policyId, address user) external view returns (bool);

    /// @notice TIP-1015: Checks if a user is authorized as a mint recipient
    /// @param policyId Policy ID to check against
    /// @param user Address to check
    /// @return True if authorized to receive mints
    function isAuthorizedMintRecipient(uint64 policyId, address user) external view returns (bool);

    /// @notice TIP-1015: Returns the constituent policy IDs for a compound policy
    /// @param policyId ID of the compound policy to query
    /// @return senderPolicyId Policy ID for sender checks
    /// @return recipientPolicyId Policy ID for recipient checks
    /// @return mintRecipientPolicyId Policy ID for mint recipient checks
    function compoundPolicyData(uint64 policyId)
        external
        view
        returns (uint64 senderPolicyId, uint64 recipientPolicyId, uint64 mintRecipientPolicyId);

    // =========================================================================
    //                      TIP-1028: Receive Policies
    // =========================================================================

    /// @notice Returns the receive policy configuration for an account
    /// @param account The account to query
    /// @return hasReceivePolicy Whether the account has a receive policy set
    /// @return senderPolicyId The sender policy ID for inbound transfer authorization
    /// @return senderPolicyType The type of the sender policy
    /// @return tokenFilterId The token filter policy ID
    /// @return tokenFilterType The type of the token filter policy
    /// @return recoveryAuthority The recovery authority address for blocked receipts
    function receivePolicy(address account)
        external
        view
        returns (
            bool hasReceivePolicy,
            uint64 senderPolicyId,
            PolicyType senderPolicyType,
            uint64 tokenFilterId,
            PolicyType tokenFilterType,
            address recoveryAuthority
        );

    /// @notice Validates an inbound transfer against the receiver's receive policy
    /// @param token The TIP-20 token being transferred
    /// @param sender The sender of the transfer
    /// @param receiver The receiver of the transfer
    /// @return authorized Whether the transfer is authorized
    /// @return blockedReason The reason the transfer was blocked (NONE if authorized)
    function validateReceivePolicy(address token, address sender, address receiver)
        external
        view
        returns (bool authorized, BlockedReason blockedReason);

    /// @notice Sets the caller's receive policy for inbound transfers
    /// @param senderPolicyId The sender policy ID to use for inbound transfer authorization
    /// @param tokenFilterId The token filter policy ID
    /// @param recoveryAuthority The recovery authority address for blocked receipts
    function setReceivePolicy(uint64 senderPolicyId, uint64 tokenFilterId, address recoveryAuthority) external;
}
