// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

import {IFeeAMM} from "./IFeeAMM.sol";

interface IFeeManager is IFeeAMM {
    error CannotChangeWithinBlock();
    error InsufficientFeeTokenBalance();

    event UserTokenSet(address indexed user, address indexed token);
    event ValidatorTokenSet(address indexed validator, address indexed token);
    event FeesDistributed(address indexed validator, address indexed token, uint256 amount);

    /// @notice Transfers a validator's accumulated fee balance to their address and zeroes the
    ///         ledger. No-ops when the balance is zero.
    /// @param validator The validator to pay out.
    /// @param token The fee token to distribute.
    function distributeFees(address validator, address token) external;

    /// @notice Returns the accumulated fee balance for a validator in a given token.
    /// @param validator The validator address.
    /// @param token The fee token address.
    /// @return The amount of fees accumulated and pending distribution.
    function collectedFees(address validator, address token) external view returns (uint256);

    /// @notice Sets the caller's preferred fee token for paying transaction fees.
    ///         Must be a USD-denominated TIP-20 registered in TIP20Factory.
    /// @param token The USD-denominated TIP-20 token address.
    function setUserToken(address token) external;

    /// @notice Sets the caller's preferred fee token for receiving transaction fees.
    ///         Must be a USD-denominated TIP-20 registered in TIP20Factory.
    ///         Reverts with `CannotChangeWithinBlock` if the caller is the current block's beneficiary.
    /// @param token The USD-denominated TIP-20 token address.
    function setValidatorToken(address token) external;

    /// @notice Returns the raw stored fee token preference for a user.
    ///         Returns the zero address if no preference has been set.
    /// @param user The user address.
    /// @return The token address stored for the user, or zero if unset.
    function userTokens(address user) external view returns (address);

    /// @notice Returns the raw stored fee token preference for a validator.
    ///         Returns the zero address if no preference has been set.
    /// @param validator The validator address.
    /// @return The token address stored for the validator, or zero if unset.
    function validatorTokens(address validator) external view returns (address);
}
