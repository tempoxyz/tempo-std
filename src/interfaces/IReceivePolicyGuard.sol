// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

/// @title The interface for the TIP-1028 receive policy guard
/// @notice Tracks blocked inbound TIP-20 transfers and mints until claimed or burned
interface IReceivePolicyGuard {
    /// @notice The kind of inbound operation that was blocked
    /// @param TRANSFER A regular TIP-20 transfer
    /// @param MINT A TIP-20 mint
    enum InboundKind {
        TRANSFER,
        MINT
    }

    /// @notice V1 claim receipt encoding for a blocked inbound
    /// @param version The receipt encoding version
    /// @param token The TIP-20 token address
    /// @param recoveryAuthority The recovery authority assigned to the blocked receipt
    /// @param originator The original sender (transfer) or issuer (mint)
    /// @param recipient The intended recipient of the blocked inbound
    /// @param blockedAt The block timestamp at which the inbound was blocked
    /// @param blockedNonce The guard-scoped nonce assigned to this blocked receipt
    /// @param blockedReason The reason the inbound was blocked
    /// @param kind Whether the blocked inbound was a transfer or mint
    /// @param memo Application-specific memo attached to the inbound
    struct ClaimReceiptV1 {
        uint8 version;
        address token;
        address recoveryAuthority;
        address originator;
        address recipient;
        uint64 blockedAt;
        uint64 blockedNonce;
        uint8 blockedReason;
        InboundKind kind;
        bytes32 memo;
    }

    /// @notice Returns the blocked balance for an encoded receipt
    /// @param receipt The ABI-encoded claim receipt
    /// @return amount The blocked balance for the receipt
    function balanceOf(bytes calldata receipt) external view returns (uint256 amount);

    /// @notice Claims a blocked receipt, releasing funds to the specified address
    /// @param to The address to release the blocked funds to
    /// @param receipt The ABI-encoded claim receipt
    function claim(address to, bytes calldata receipt) external;

    /// @notice Burns the funds backing a blocked receipt
    /// @param receipt The ABI-encoded claim receipt
    function burnBlockedReceipt(bytes calldata receipt) external;

    /// @notice Emitted when an inbound TIP-20 transfer or mint is blocked and funds are redirected
    /// @param token TIP-20 token whose funds are held by the guard
    /// @param receiver Resolved account where funds would settle; for virtual recipients its their master
    /// @param blockedNonce Guard nonce assigned to the blocked operation
    /// @param amount Amount of blocked funds held by the guard
    /// @param receiptVersion Claim receipt layout version
    /// @param receipt ABI-encoded receipt witness that can be passed to `claim`
    event TransferBlocked(
        address indexed token,
        address indexed receiver,
        uint64 indexed blockedNonce,
        uint256 amount,
        uint8 receiptVersion,
        bytes receipt
    );

    /// @notice Emitted when blocked funds are claimed with a valid receipt
    event ReceiptClaimed(
        address indexed token,
        address indexed receiver,
        uint64 indexed blockedNonce,
        uint64 blockedAt,
        uint8 receiptVersion,
        address originator,
        address recipient,
        address recoveryAuthority,
        address caller,
        address to,
        uint256 amount
    );

    /// @notice Emitted when blocked funds are burned with a valid receipt
    event ReceiptBurned(
        address indexed token,
        address indexed receiver,
        uint64 indexed blockedNonce,
        uint64 blockedAt,
        uint8 receiptVersion,
        address originator,
        address recipient,
        address recoveryAuthority,
        address caller,
        uint256 amount
    );

    /// @notice Error when the claim receipt is invalid or does not match any blocked receipt
    error InvalidReceipt();

    /// @notice Error when the claim destination address is invalid
    error InvalidClaimAddress();

    /// @notice Error when the caller is not authorized to claim the blocked receipt
    error UnauthorizedClaimer();

    /// @notice Error when a reserved address is used where it should not be
    error AddressReserved();
}
