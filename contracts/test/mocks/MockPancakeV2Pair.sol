// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MockPancakeV2Pair {
    using SafeERC20 for IERC20;

    uint256 internal constant FEE_DENOMINATOR = 10_000;
    uint256 internal constant FEE_NUMERATOR = 9_975;

    address public immutable token0;
    address public immutable token1;

    uint112 private reserve0;
    uint112 private reserve1;

    error InvalidTokenPair();
    error InvalidAmount();
    error ReserveOverflow(uint256 reserve);
    error SlippageExceeded(uint256 amountOut, uint256 minAmountOut);

    constructor(address token0_, address token1_) {
        token0 = token0_;
        token1 = token1_;
    }

    function seed(uint256 amount0, uint256 amount1) external {
        if (amount0 == 0 || amount1 == 0) revert InvalidAmount();

        IERC20(token0).safeTransferFrom(msg.sender, address(this), amount0);
        IERC20(token1).safeTransferFrom(msg.sender, address(this), amount1);
        reserve0 = _toReserve(uint256(reserve0) + amount0);
        reserve1 = _toReserve(uint256(reserve1) + amount1);
    }

    function getReserves() external view returns (uint112, uint112, uint32) {
        return (reserve0, reserve1, uint32(block.timestamp));
    }

    function quote(address tokenIn, address tokenOut, uint256 amountIn) external view returns (uint256 amountOut) {
        (uint256 reserveIn, uint256 reserveOut) = _reservesFor(tokenIn, tokenOut);
        return _getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function swap(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut, address recipient)
        external
        returns (uint256 amountOut)
    {
        if (amountIn == 0) revert InvalidAmount();

        (uint256 reserveIn, uint256 reserveOut) = _reservesFor(tokenIn, tokenOut);
        amountOut = _getAmountOut(amountIn, reserveIn, reserveOut);
        if (amountOut < minAmountOut) revert SlippageExceeded(amountOut, minAmountOut);

        if (tokenIn == token0) {
            reserve0 = _toReserve(reserveIn + amountIn);
            reserve1 = _toReserve(reserveOut - amountOut);
        } else {
            reserve1 = _toReserve(reserveIn + amountIn);
            reserve0 = _toReserve(reserveOut - amountOut);
        }

        IERC20(tokenOut).safeTransfer(recipient, amountOut);
    }

    function _reservesFor(address tokenIn, address tokenOut)
        private
        view
        returns (uint256 reserveIn, uint256 reserveOut)
    {
        if (tokenIn == token0 && tokenOut == token1) {
            return (reserve0, reserve1);
        }

        if (tokenIn == token1 && tokenOut == token0) {
            return (reserve1, reserve0);
        }

        revert InvalidTokenPair();
    }

    function _getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) private pure returns (uint256) {
        if (amountIn == 0 || reserveIn == 0 || reserveOut == 0) revert InvalidAmount();

        uint256 amountInWithFee = amountIn * FEE_NUMERATOR;
        return (amountInWithFee * reserveOut) / ((reserveIn * FEE_DENOMINATOR) + amountInWithFee);
    }

    function _toReserve(uint256 reserve) private pure returns (uint112) {
        if (reserve > type(uint112).max) revert ReserveOverflow(reserve);
        // forge-lint: disable-next-line(unsafe-typecast)
        return uint112(reserve);
    }
}
