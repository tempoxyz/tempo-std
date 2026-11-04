// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

/// @title TIP-20 channel reserve interface (T12 descriptor-based ABI)
/// @notice The reserve locks payer deposits, verifies EIP-712 cumulative vouchers, pays the
///         payee incrementally, and lets the payer withdraw the remaining balance after a
///         close grace period.
interface ITempoStreamChannel {
    /// @notice Immutable channel identity supplied to all descriptor-based methods.
    struct ChannelDescriptor {
        /// Account that funded the channel and receives refunds.
        address payer;
        /// Account that receives settled voucher payments.
        address payee;
        /// Optional relayer allowed to submit `settle` for the payee.
        address operator;
        /// TIP-20 token address held by the channel.
        address token;
        /// User-supplied salt to distinguish otherwise identical channels.
        bytes32 salt;
        /// Optional signer for vouchers. Zero means `payer` signs.
        address authorizedSigner;
        /// Transaction-derived hash assigned when the channel was opened.
        bytes32 expiringNonceHash;
    }

    /// @notice Mutable channel state packed into one native storage slot.
    struct ChannelState {
        /// Cumulative amount already paid to the payee.
        uint96 settled;
        /// Total deposit currently locked by the channel.
        uint96 deposit;
        /// Payer close-request timestamp, or zero when no close is pending.
        uint32 closeRequestedAt;
    }

    /// @notice Full descriptor plus current state.
    struct Channel {
        /// Channel identity fields.
        ChannelDescriptor descriptor;
        /// Mutable channel accounting state.
        ChannelState state;
    }

    /// @notice Delay between payer `requestClose` and `withdraw`.
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
    function settle(ChannelDescriptor calldata descriptor, uint96 cumulativeAmount, bytes calldata signature) external;

    /// @notice Adds deposit to a channel and cancels any pending close request.
    function topUp(ChannelDescriptor calldata descriptor, uint96 additionalDeposit) external;

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
        bytes32 indexed channelId, address indexed payer, address indexed payee, uint256 closeGraceEnd
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
    event CloseRequestCancelled(bytes32 indexed channelId, address indexed payer, address indexed payee);

    /// @notice Channel id already exists in persistent state or earlier in this transaction.
    error ChannelAlreadyExists();

    /// @notice Descriptor resolves to an empty channel slot.
    error ChannelNotFound();

    /// @notice Caller must be the descriptor payer.
    error NotPayer();

    /// @notice Caller must be the descriptor payee or nonzero operator.
    error NotPayeeOrOperator();

    /// @notice Payee is zero or a TIP-20-prefix address.
    error InvalidPayee();

    /// @notice Initial deposit cannot be zero.
    error ZeroDeposit();

    /// @notice Handler did not seed the transaction-scoped open context hash.
    error ExpiringNonceHashNotSet();

    /// @notice Voucher signature did not recover to the expected signer.
    error InvalidSignature();

    /// @notice Voucher or capture amount exceeds the channel deposit.
    error AmountExceedsDeposit();

    /// @notice Settlement amount must be greater than the current settled amount.
    error AmountNotIncreasing();

    /// @notice Close capture is below settled amount or above voucher amount.
    error CaptureAmountInvalid();

    /// @notice Payer withdraw was attempted before the close grace period elapsed.
    error CloseNotReady();

    /// @notice Top-up would overflow the packed deposit.
    error DepositOverflow();
}
