// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

import {ITIP403Registry} from "./ITIP403Registry.sol";

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
    /// @param blockedAt The block number at which the inbound was blocked
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
        ITIP403Registry.BlockedReason blockedReason;
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

    /// @notice Stores a newly blocked inbound transfer or mint receipt
    /// @param token The TIP-20 token address
    /// @param originator The sender of the blocked inbound
    /// @param receiver The receiver whose receive policy blocked the inbound
    /// @param recipient The intended recipient of the blocked inbound
    /// @param recoveryAuthority The recovery authority assigned to the blocked receipt
    /// @param amount The amount of tokens blocked
    /// @param blockedReason The reason the inbound was blocked
    /// @param kind Whether the blocked inbound was a transfer or mint
    /// @param memo Application-specific memo attached to the inbound
    /// @return blockedNonce The guard-scoped nonce assigned to this blocked receipt
    /// @return blockedAt The block number at which the inbound was blocked
    function storeBlocked(
        address token,
        address originator,
        address receiver,
        address recipient,
        address recoveryAuthority,
        uint256 amount,
        ITIP403Registry.BlockedReason blockedReason,
        InboundKind kind,
        bytes32 memo
    ) external returns (uint64 blockedNonce, uint64 blockedAt);

    /// @notice Emitted when an inbound transfer or mint is blocked by a receive policy
    event TransferBlocked(
        address indexed token,
        address indexed from,
        address indexed receiver,
        uint8 receiptVersion,
        uint64 blockedNonce,
        uint64 blockedAt,
        address recipient,
        uint256 amount,
        ITIP403Registry.BlockedReason blockedReason,
        address recoveryAuthority,
        bytes32 memo
    );

    /// @notice Emitted when a blocked receipt is claimed
    event ReceiptClaimed(
        address indexed token,
        address indexed receiver,
        uint8 receiptVersion,
        uint64 indexed blockedNonce,
        uint64 blockedAt,
        address originator,
        address recipient,
        address recoveryAuthority,
        address caller,
        address to,
        uint256 amount
    );

    /// @notice Emitted when a blocked receipt is burned
    event ReceiptBurned(
        address indexed token,
        address indexed receiver,
        uint8 receiptVersion,
        uint64 indexed blockedNonce,
        uint64 blockedAt,
        address originator,
        address recipient,
        address recoveryAuthority,
        address caller,
        uint256 amount
    );

    /// @notice Error when a receive policy references an incompatible policy type
    error InvalidReceivePolicyType();

    /// @notice Error when the recovery authority address is invalid
    error InvalidRecoveryAuthority();

    /// @notice Error when the claim receipt is invalid or does not match any blocked receipt
    error InvalidReceipt();

    /// @notice Error when the claim destination address is invalid
    error InvalidClaimAddress();

    /// @notice Error when the caller is not authorized to claim the blocked receipt
    error UnauthorizedClaimer();

    /// @notice Error when a reserved address is used where it should not be
    error AddressReserved();
}
