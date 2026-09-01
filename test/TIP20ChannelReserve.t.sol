// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

import {StdPrecompiles} from "../src/StdPrecompiles.sol";
import {Tempo} from "../src/Tempo.sol";
import {ITIP20ChannelReserve} from "../src/interfaces/ITIP20ChannelReserve.sol";

contract TIP20ChannelReserveExportsTest is Tempo {
    address internal constant EXPECTED_TIP20_CHANNEL_RESERVE_ADDRESS = 0x4d50500000000000000000000000000000000000;

    function testAddressExports() public pure {
        require(
            StdPrecompiles.TIP20_CHANNEL_RESERVE_ADDRESS == EXPECTED_TIP20_CHANNEL_RESERVE_ADDRESS,
            "StdPrecompiles tip20 channel reserve address mismatch"
        );
        require(
            TIP20_CHANNEL_RESERVE == EXPECTED_TIP20_CHANNEL_RESERVE_ADDRESS,
            "Tempo tip20 channel reserve address mismatch"
        );
    }

    function testTypedExports() public pure {
        require(
            address(StdPrecompiles.TIP20_CHANNEL_RESERVE) == EXPECTED_TIP20_CHANNEL_RESERVE_ADDRESS,
            "StdPrecompiles typed export mismatch"
        );
        require(
            address(tip20ChannelReserve) == EXPECTED_TIP20_CHANNEL_RESERVE_ADDRESS,
            "Tempo typed export mismatch"
        );
    }

    function testFunctionSelectors() public pure {
        require(
            ITIP20ChannelReserve.CLOSE_GRACE_PERIOD.selector == bytes4(keccak256("CLOSE_GRACE_PERIOD()")),
            "CLOSE_GRACE_PERIOD selector mismatch"
        );
        require(
            ITIP20ChannelReserve.VOUCHER_TYPEHASH.selector == bytes4(keccak256("VOUCHER_TYPEHASH()")),
            "VOUCHER_TYPEHASH selector mismatch"
        );
        require(
            ITIP20ChannelReserve.open.selector == bytes4(keccak256("open(address,address,address,uint96,bytes32,address)")),
            "open selector mismatch"
        );
        require(
            ITIP20ChannelReserve.settle.selector == bytes4(keccak256("settle((address,address,address,address,bytes32,address,bytes32),uint96,bytes)")),
            "settle selector mismatch"
        );
        require(
            ITIP20ChannelReserve.topUp.selector == bytes4(keccak256("topUp((address,address,address,address,bytes32,address,bytes32),uint96)")),
            "topUp selector mismatch"
        );
        require(
            ITIP20ChannelReserve.close.selector == bytes4(keccak256("close((address,address,address,address,bytes32,address,bytes32),uint96,uint96,bytes)")),
            "close selector mismatch"
        );
        require(
            ITIP20ChannelReserve.requestClose.selector == bytes4(keccak256("requestClose((address,address,address,address,bytes32,address,bytes32))")),
            "requestClose selector mismatch"
        );
        require(
            ITIP20ChannelReserve.withdraw.selector == bytes4(keccak256("withdraw((address,address,address,address,bytes32,address,bytes32))")),
            "withdraw selector mismatch"
        );
        require(
            ITIP20ChannelReserve.getChannel.selector == bytes4(keccak256("getChannel((address,address,address,address,bytes32,address,bytes32))")),
            "getChannel selector mismatch"
        );
        require(
            ITIP20ChannelReserve.getChannelState.selector == bytes4(keccak256("getChannelState(bytes32)")),
            "getChannelState selector mismatch"
        );
        require(
            ITIP20ChannelReserve.getChannelStatesBatch.selector == bytes4(keccak256("getChannelStatesBatch(bytes32[])")),
            "getChannelStatesBatch selector mismatch"
        );
        require(
            ITIP20ChannelReserve.computeChannelId.selector == bytes4(keccak256("computeChannelId(address,address,address,address,bytes32,address,bytes32)")),
            "computeChannelId selector mismatch"
        );
        require(
            ITIP20ChannelReserve.getVoucherDigest.selector == bytes4(keccak256("getVoucherDigest(bytes32,uint96)")),
            "getVoucherDigest selector mismatch"
        );
        require(
            ITIP20ChannelReserve.domainSeparator.selector == bytes4(keccak256("domainSeparator()")),
            "domainSeparator selector mismatch"
        );
        require(
            ITIP20ChannelReserve.storageCredits.selector == bytes4(keccak256("storageCredits(address)")),
            "storageCredits selector mismatch"
        );
    }

    function testErrorSelectors() public pure {
        require(
            ITIP20ChannelReserve.ChannelAlreadyExists.selector == bytes4(keccak256("ChannelAlreadyExists()")),
            "ChannelAlreadyExists selector mismatch"
        );
        require(
            ITIP20ChannelReserve.ChannelNotFound.selector == bytes4(keccak256("ChannelNotFound()")),
            "ChannelNotFound selector mismatch"
        );
        require(
            ITIP20ChannelReserve.NotPayer.selector == bytes4(keccak256("NotPayer()")),
            "NotPayer selector mismatch"
        );
        require(
            ITIP20ChannelReserve.NotPayeeOrOperator.selector == bytes4(keccak256("NotPayeeOrOperator()")),
            "NotPayeeOrOperator selector mismatch"
        );
        require(
            ITIP20ChannelReserve.InvalidPayee.selector == bytes4(keccak256("InvalidPayee()")),
            "InvalidPayee selector mismatch"
        );
        require(
            ITIP20ChannelReserve.ZeroDeposit.selector == bytes4(keccak256("ZeroDeposit()")),
            "ZeroDeposit selector mismatch"
        );
        require(
            ITIP20ChannelReserve.ExpiringNonceHashNotSet.selector == bytes4(keccak256("ExpiringNonceHashNotSet()")),
            "ExpiringNonceHashNotSet selector mismatch"
        );
        require(
            ITIP20ChannelReserve.InvalidSignature.selector == bytes4(keccak256("InvalidSignature()")),
            "InvalidSignature selector mismatch"
        );
        require(
            ITIP20ChannelReserve.AmountExceedsDeposit.selector == bytes4(keccak256("AmountExceedsDeposit()")),
            "AmountExceedsDeposit selector mismatch"
        );
        require(
            ITIP20ChannelReserve.AmountNotIncreasing.selector == bytes4(keccak256("AmountNotIncreasing()")),
            "AmountNotIncreasing selector mismatch"
        );
        require(
            ITIP20ChannelReserve.CaptureAmountInvalid.selector == bytes4(keccak256("CaptureAmountInvalid()")),
            "CaptureAmountInvalid selector mismatch"
        );
        require(
            ITIP20ChannelReserve.CloseNotReady.selector == bytes4(keccak256("CloseNotReady()")),
            "CloseNotReady selector mismatch"
        );
        require(
            ITIP20ChannelReserve.DepositOverflow.selector == bytes4(keccak256("DepositOverflow()")),
            "DepositOverflow selector mismatch"
        );
    }
}
