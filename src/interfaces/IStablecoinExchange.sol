// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

interface IStablecoinExchange {
    // Events
    event OrderPlaced(
        uint128 indexed orderId, address indexed maker, address indexed token, uint128 amount, bool isBid, int16 tick
    );

    event FlipOrderPlaced(
        uint128 indexed orderId,
        address indexed maker,
        address indexed token,
        uint128 amount,
        bool isBid,
        int16 tick,
        int16 flipTick
    );

    event OrderCancelled(uint128 indexed orderId);

    event OrderFilled(
        uint128 indexed orderId, address indexed maker, address indexed taker, uint128 amountFilled, bool partialFill
    );

    // Balance management
    function withdraw(address token, uint128 amount) external;

    function balanceOf(address user, address token) external view returns (uint128);

    // Swap functions
    // Will support routing across multiple pairs, in the future
    function swapExactAmountIn(address tokenIn, address tokenOut, uint128 amountIn, uint128 minAmountOut)
        external
        returns (uint128 amountOut);

    function swapExactAmountOut(address tokenIn, address tokenOut, uint128 amountOut, uint128 maxAmountIn)
        external
        returns (uint128 amountIn);

    function quoteSwapExactAmountOut(address tokenIn, address tokenOut, uint128 amountOut)
        external
        view
        returns (uint128 amountIn);

    function quoteSwapExactAmountIn(address tokenIn, address tokenOut, uint128 amountIn)
        external
        view
        returns (uint128 amountOut);

    // Order management
    // Only supports placing an order on a pair between a token and its quote token
    // Amount is denominated in the token
    // Tick is the price of the token denominated in the quote token, minus 1, times 1000
    // A bid is an order to buy the token using its quote token
    // A ask is an order to sell the token for its quote token
    function place(address token, uint128 amount, bool isBid, int16 tick) external returns (uint128 orderId);

    // flipTick must be greater than tick if the order is a bid, less if the order is an ask
    function placeFlip(address token, uint128 amount, bool isBid, int16 tick, int16 flipTick)
        external
        returns (uint128 orderId);

    function cancel(uint128 orderId) external;
}
