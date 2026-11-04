// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

/// @title ITIP20ChannelReserve
/// @notice Interface for the TIP-1034 native TIP-20 Channel Reserve precompile on Tempo.
/// @dev Precompile address: 0x4d50500000000000000000000000000000000000 (Activated in Hardfork T5)
interface ITIP20ChannelReserve {
    /// @notice Immutable channel identity supplied to all descriptor-based methods.
    struct ChannelDescriptor {
        address payer;
        address payee;
        address operator;
        address token;
        bytes32 salt;
        address authorizedSigner;
        bytes32 expiringNonceHash;
    }

    /// @notice Mutable channel state packed into one native storage slot.
    struct ChannelState {
        uint96 settled;
        uint96 deposit;
        uint32 closeRequestedAt;
    }

    /// @notice Full descriptor plus current state.
    struct Channel {
        ChannelDescriptor descriptor;
        ChannelState state;
    }

    /// @notice Delay between payer `requestClose` and `withdraw` (15 minutes).
    function CLOSE_GRACE_PERIOD() external view returns (uint64);

    /// @notice EIP-712 type hash for `Voucher(bytes32 channelId,uint96 cumulativeAmount)`.
    function VOUCHER_TYPEHASH() external view returns (bytes32);

    /// @notice Opens a channel and pulls `deposit` TIP-20 units from `msg.sender`.
    function open(
        address payee,
        address operator,
        address token,
        uint96 deposit,
        bytes32 salt,
        address authorizedSigner
    ) external returns (bytes32 channelId);

    /// @notice Pays the unsettled delta up to `cumulativeAmount` using a valid voucher.
    function settle(
        ChannelDescriptor calldata descriptor,
        uint96 cumulativeAmount,
        bytes calldata signature
    ) external;

    /// @notice Adds deposit to a channel and cancels any pending close request.
    function topUp(
        ChannelDescriptor calldata descriptor,
        uint96 additionalDeposit
    ) external;

    /// @notice Closes the channel from the payee/operator side and refunds uncaptured deposit.
    function close(
        ChannelDescriptor calldata descriptor,
        uint96 cumulativeAmount,
        uint96 captureAmount,
        bytes calldata signature
    ) external;

    /// @notice Starts the payer withdrawal timer.
    function requestClose(ChannelDescriptor calldata descriptor) external;

    /// @notice Withdraws the payer refund after the close grace period has elapsed.
    function withdraw(ChannelDescriptor calldata descriptor) external;

    /// @notice Returns the descriptor and state for a channel.
    function getChannel(ChannelDescriptor calldata descriptor) external view returns (Channel memory);

    /// @notice Returns the state for `channelId`, or the zero state when absent.
    function getChannelState(bytes32 channelId) external view returns (ChannelState memory);

    /// @notice Returns states for `channelIds` in order.
    function getChannelStatesBatch(bytes32[] calldata channelIds) external view returns (ChannelState[] memory);

    /// @notice Computes the canonical channel id for a descriptor.
    function computeChannelId(
        address payer,
        address payee,
        address operator,
        address token,
        bytes32 salt,
        address authorizedSigner,
        bytes32 expiringNonceHash
    ) external view returns (bytes32);

    /// @notice Computes the EIP-712 digest signed by the payer or authorized signer.
    function getVoucherDigest(bytes32 channelId, uint96 cumulativeAmount) external view returns (bytes32);

    /// @notice Returns the EIP-712 domain separator for the current chain.
    function domainSeparator() external view returns (bytes32);

    /// @notice Returns the number of reusable channel storage credits owned by `payer`.
    function storageCredits(address payer) external view returns (uint64 credits);

    /// @notice Emitted after a channel is opened and funded.
    event ChannelOpened(
        bytes32 indexed channelId,
        address indexed payer,
        address indexed payee,
        address operator,
        address token,
        address authorizedSigner,
        bytes32 salt,
        bytes32 expiringNonceHash,
        uint96 deposit
    );

    /// @notice Emitted after voucher settlement pays a delta to the payee.
    event Settled(
        bytes32 indexed channelId,
        address indexed payer,
        address indexed payee,
        uint96 cumulativeAmount,
        uint96 deltaPaid,
        uint96 newSettled
    );

    /// @notice Emitted after channel deposit changes or a close request is cancelled by top-up.
    event TopUp(
        bytes32 indexed channelId,
        address indexed payer,
        address indexed payee,
        uint96 additionalDeposit,
        uint96 newDeposit
    );

    /// @notice Emitted when the payer starts the close grace timer.
    event CloseRequested(
        bytes32 indexed channelId,
        address indexed payer,
        address indexed payee,
        uint256 closeGraceEnd
    );

    /// @notice Emitted when a channel is deleted by payee close or payer withdraw.
    event ChannelClosed(
        bytes32 indexed channelId,
        address indexed payer,
        address indexed payee,
        uint96 settledToPayee,
        uint96 refundedToPayer
    );

    /// @notice Emitted when top-up clears a pending close request.
    event CloseRequestCancelled(
        bytes32 indexed channelId,
        address indexed payer,
        address indexed payee
    );

    error ChannelAlreadyExists();
    error ChannelNotFound();
    error NotPayer();
    error NotPayeeOrOperator();
    error InvalidPayee();
    error ZeroDeposit();
    error ExpiringNonceHashNotSet();
    error InvalidSignature();
    error AmountExceedsDeposit();
    error AmountNotIncreasing();
    error CaptureAmountInvalid();
    error CloseNotReady();
    error DepositOverflow();
}
