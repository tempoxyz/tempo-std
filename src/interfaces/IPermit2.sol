// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

library IAllowanceTransfer {
    struct AllowanceTransferDetails {
        address from;
        address to;
        uint160 amount;
        address token;
    }

    struct PermitBatch {
        PermitDetails[] details;
        address spender;
        uint256 sigDeadline;
    }

    struct PermitDetails {
        address token;
        uint160 amount;
        uint48 expiration;
        uint48 nonce;
    }

    struct PermitSingle {
        PermitDetails details;
        address spender;
        uint256 sigDeadline;
    }

    struct TokenSpenderPair {
        address token;
        address spender;
    }
}

library ISignatureTransfer {
    struct PermitBatchTransferFrom {
        TokenPermissions[] permitted;
        uint256 nonce;
        uint256 deadline;
    }

    struct PermitTransferFrom {
        TokenPermissions permitted;
        uint256 nonce;
        uint256 deadline;
    }

    struct SignatureTransferDetails {
        address to;
        uint256 requestedAmount;
    }

    struct TokenPermissions {
        address token;
        uint256 amount;
    }
}

interface IPermit2 {
    error AllowanceExpired(uint256 deadline);
    error ExcessiveInvalidation();
    error InsufficientAllowance(uint256 amount);
    error InvalidAmount(uint256 maxAmount);
    error InvalidContractSignature();
    error InvalidNonce();
    error InvalidSignature();
    error InvalidSignatureLength();
    error InvalidSigner();
    error LengthMismatch();
    error SignatureExpired(uint256 signatureDeadline);

    event Approval(
        address indexed owner, address indexed token, address indexed spender, uint160 amount, uint48 expiration
    );
    event Lockdown(address indexed owner, address token, address spender);
    event NonceInvalidation(
        address indexed owner, address indexed token, address indexed spender, uint48 newNonce, uint48 oldNonce
    );
    event Permit(
        address indexed owner,
        address indexed token,
        address indexed spender,
        uint160 amount,
        uint48 expiration,
        uint48 nonce
    );
    event UnorderedNonceInvalidation(address indexed owner, uint256 word, uint256 mask);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function allowance(address, address, address)
        external
        view
        returns (uint160 amount, uint48 expiration, uint48 nonce);

    function approve(address token, address spender, uint160 amount, uint48 expiration) external;

    function invalidateNonces(address token, address spender, uint48 newNonce) external;

    function invalidateUnorderedNonces(uint256 wordPos, uint256 mask) external;

    function lockdown(IAllowanceTransfer.TokenSpenderPair[] memory approvals) external;

    function nonceBitmap(address, uint256) external view returns (uint256);

    function permit(address owner, IAllowanceTransfer.PermitBatch memory permitBatch, bytes memory signature) external;

    function permit(address owner, IAllowanceTransfer.PermitSingle memory permitSingle, bytes memory signature) external;

    function permitTransferFrom(
        ISignatureTransfer.PermitTransferFrom memory permit,
        ISignatureTransfer.SignatureTransferDetails memory transferDetails,
        address owner,
        bytes memory signature
    ) external;

    function permitTransferFrom(
        ISignatureTransfer.PermitBatchTransferFrom memory permit,
        ISignatureTransfer.SignatureTransferDetails[] memory transferDetails,
        address owner,
        bytes memory signature
    ) external;

    function permitWitnessTransferFrom(
        ISignatureTransfer.PermitTransferFrom memory permit,
        ISignatureTransfer.SignatureTransferDetails memory transferDetails,
        address owner,
        bytes32 witness,
        string memory witnessTypeString,
        bytes memory signature
    ) external;

    function permitWitnessTransferFrom(
        ISignatureTransfer.PermitBatchTransferFrom memory permit,
        ISignatureTransfer.SignatureTransferDetails[] memory transferDetails,
        address owner,
        bytes32 witness,
        string memory witnessTypeString,
        bytes memory signature
    ) external;

    function transferFrom(IAllowanceTransfer.AllowanceTransferDetails[] memory transferDetails) external;

    function transferFrom(address from, address to, uint160 amount, address token) external;
}
