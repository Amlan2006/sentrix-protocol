// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MockConstantProductPool {
    using SafeERC20 for IERC20;

    error InvalidTokenPair();
    error InvalidAmount();
    error InsufficientLiquidity();
    error SlippageExceeded(uint256 amountOut, uint256 minAmountOut);

    address public immutable token0;
    address public immutable token1;

    uint256 public reserve0;
    uint256 public reserve1;

    constructor(address token0_, address token1_) {
        token0 = token0_;
        token1 = token1_;
    }

    function seed(uint256 amount0, uint256 amount1) external {
        if (amount0 == 0 || amount1 == 0) revert InvalidAmount();

        IERC20(token0).safeTransferFrom(msg.sender, address(this), amount0);
        IERC20(token1).safeTransferFrom(msg.sender, address(this), amount1);

        reserve0 += amount0;
        reserve1 += amount1;
    }

    function quote(address tokenIn, address tokenOut, uint256 amountIn) public view returns (uint256 amountOut) {
        if (amountIn == 0) revert InvalidAmount();
        (uint256 reserveIn, uint256 reserveOut) = _reservesFor(tokenIn, tokenOut);
        if (reserveIn == 0 || reserveOut == 0) revert InsufficientLiquidity();

        uint256 amountInWithFee = amountIn * 997;
        amountOut = (amountInWithFee * reserveOut) / ((reserveIn * 1000) + amountInWithFee);
        if (amountOut == 0 || amountOut >= reserveOut) revert InsufficientLiquidity();
    }

    function swap(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut, address recipient)
        external
        returns (uint256 amountOut)
    {
        if (recipient == address(0)) revert InvalidTokenPair();

        amountOut = quote(tokenIn, tokenOut, amountIn);
        if (amountOut < minAmountOut) revert SlippageExceeded(amountOut, minAmountOut);

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);

        if (tokenIn == token0 && tokenOut == token1) {
            reserve0 += amountIn;
            reserve1 -= amountOut;
        } else if (tokenIn == token1 && tokenOut == token0) {
            reserve1 += amountIn;
            reserve0 -= amountOut;
        } else {
            revert InvalidTokenPair();
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
}
