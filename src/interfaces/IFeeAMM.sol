// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IFeeAMM {
    // Each pool is directional: userToken -> validatorToken
    // For a pair of tokens A and B, there are two separate pools:
    // - Pool(A, B): for swapping A to B at fixed rate of 0.997 (fee swaps) and B to A at fixed rate of 0.9985 (rebalancing)
    // - Pool(B, A): for swapping B to A at fixed rate of 0.997 (fee swaps) and A to B at fixed rate of 0.9985 (rebalancing)
    struct Pool {
        uint128 reserveUserToken;
        uint128 reserveValidatorToken;
    }

    struct PoolKey {
        address userToken;
        address validatorToken;
    }

    event RebalanceSwap(
        address indexed userToken,
        address indexed validatorToken,
        address indexed swapper,
        uint256 amountIn,
        uint256 amountOut
    );
    event FeeSwap(address indexed userToken, address indexed validatorToken, uint256 amountIn, uint256 amountOut);
    event Mint(
        address indexed sender,
        address indexed userToken,
        address indexed validatorToken,
        uint256 amountUserToken,
        uint256 amountValidatorToken,
        uint256 liquidity
    );
    event Burn(
        address indexed sender,
        address indexed userToken,
        address indexed validatorToken,
        uint256 amountUserToken,
        uint256 amountValidatorToken,
        uint256 liquidity,
        address to
    );

    error InsufficientLiquidity();
}
