// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IDexAdapter} from "../../src/interfaces/IDexAdapter.sol";
import {MockConstantProductPool} from "./MockConstantProductPool.sol";

contract MockAmmAdapter is IDexAdapter {
    using SafeERC20 for IERC20;

    error PoolNotRegistered();
    error InvalidAmount();
    error InvalidRouteData();

    mapping(bytes32 pairKey => address pool) public pools;

    function registerPool(address tokenA, address tokenB, address pool) external {
        pools[_pairKey(tokenA, tokenB)] = pool;
    }

    function swap(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut, bytes calldata routeData)
        external
        override
        returns (uint256 amountOut)
    {
        if (amountIn == 0) revert InvalidAmount();

        address pool = pools[_pairKey(tokenIn, tokenOut)];
        if (pool == address(0)) revert PoolNotRegistered();

        if (routeData.length != 0 && abi.decode(routeData, (address)) != pool) {
            revert InvalidRouteData();
        }

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).forceApprove(pool, amountIn);
        amountOut = MockConstantProductPool(pool).swap(tokenIn, tokenOut, amountIn, minAmountOut, msg.sender);
        IERC20(tokenIn).forceApprove(pool, 0);
    }

    function quote(address tokenIn, address tokenOut, uint256 amountIn) external view returns (uint256 amountOut) {
        address pool = pools[_pairKey(tokenIn, tokenOut)];
        if (pool == address(0)) revert PoolNotRegistered();
        return MockConstantProductPool(pool).quote(tokenIn, tokenOut, amountIn);
    }

    function _pairKey(address tokenA, address tokenB) private pure returns (bytes32) {
        return tokenA < tokenB ? keccak256(abi.encode(tokenA, tokenB)) : keccak256(abi.encode(tokenB, tokenA));
    }
}
