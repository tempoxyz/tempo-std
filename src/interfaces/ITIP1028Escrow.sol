// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

import {ITIP403Registry} from "./ITIP403Registry.sol";

/// @title The interface for TIP-1028 escrow
/// @notice Escrow holding blocked inbound TIP-20 transfers and mints until claimed
interface ITIP1028Escrow {
    /// @notice The kind of inbound operation that was blocked
    /// @param TRANSFER A regular TIP-20 transfer
    /// @param MINT A TIP-20 mint
    enum InboundKind {
        TRANSFER,
        MINT
    }

    /// @notice V1 claim receipt encoding for a blocked inbound
    /// @param originator The original sender (transfer) or issuer (mint)
    /// @param recipient The intended recipient of the blocked inbound
    /// @param blockedAt The block number at which the inbound was blocked
    /// @param blockedNonce The escrow-scoped nonce assigned to this blocked receipt
    /// @param blockedReason The reason the inbound was blocked
    /// @param kind Whether the blocked inbound was a transfer or mint
    /// @param memo Application-specific memo attached to the inbound
    struct ClaimReceiptV1 {
        address originator;
        address recipient;
        uint64 blockedAt;
        uint64 blockedNonce;
        ITIP403Registry.BlockedReason blockedReason;
        InboundKind kind;
        bytes32 memo;
    }

    /// @notice Returns the escrowed balance for a specific blocked receipt
    /// @param token The TIP-20 token address
    /// @param recoveryAuthority The recovery authority that was assigned to the blocked receipt
    /// @param receiptVersion The version of the claim receipt encoding
    /// @param receipt The ABI-encoded claim receipt
    /// @return amount The escrowed balance for the receipt
    function blockedReceiptBalance(
        address token,
        address recoveryAuthority,
        uint8 receiptVersion,
        bytes calldata receipt
    ) external view returns (uint256 amount);

    /// @notice Claims a blocked receipt, releasing escrowed funds to the specified address
    /// @param token The TIP-20 token address
    /// @param recoveryAuthority The recovery authority that was assigned to the blocked receipt
    /// @param receiptVersion The version of the claim receipt encoding
    /// @param receipt The ABI-encoded claim receipt
    /// @param to The address to release the escrowed funds to
    function claim(address token, address recoveryAuthority, uint8 receiptVersion, bytes calldata receipt, address to)
        external;

    /// @notice Emitted when an inbound transfer or mint is blocked by a receive policy
    /// @param token The TIP-20 token address
    /// @param from The sender of the blocked inbound
    /// @param receiver The receiver whose receive policy blocked the inbound
    /// @param receiptVersion The version of the claim receipt encoding
    /// @param blockedNonce The escrow-scoped nonce assigned to this blocked receipt
    /// @param blockedAt The block number at which the inbound was blocked
    /// @param recipient The intended recipient of the blocked inbound
    /// @param amount The amount of tokens blocked
    /// @param blockedReason The reason the inbound was blocked
    /// @param recoveryAuthority The recovery authority assigned to the blocked receipt
    /// @param memo Application-specific memo attached to the inbound
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
    /// @param token The TIP-20 token address
    /// @param receiver The receiver whose escrow held the blocked funds
    /// @param receiptVersion The version of the claim receipt encoding
    /// @param blockedNonce The escrow-scoped nonce of the claimed receipt
    /// @param blockedAt The block number at which the inbound was originally blocked
    /// @param originator The original sender of the blocked inbound
    /// @param recipient The intended recipient of the blocked inbound
    /// @param recoveryAuthority The recovery authority that authorized the claim
    /// @param caller The address that called claim
    /// @param to The address that received the released funds
    /// @param amount The amount of tokens released
    event BlockedReceiptClaimed(
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

    /// @notice Error when the caller is not authorized to claim the blocked receipt
    error UnauthorizedClaimer();

    /// @notice Error when the claim receipt is invalid or does not match any blocked receipt
    error InvalidReceiptClaim();

    /// @notice Error when the escrow balance is insufficient (already claimed or zero)
    error InsufficientEscrowBalance();

    /// @notice Error when the escrow address itself is used where it should not be
    error EscrowAddressReserved();

    /// @notice Error when the claim destination address is invalid
    error InvalidClaimAddress();

    /// @notice Error when the token address is invalid
    error InvalidToken();
}
