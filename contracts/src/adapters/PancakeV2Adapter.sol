// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IDexAdapter} from "../interfaces/IDexAdapter.sol";
import {IPancakeV2Factory} from "../interfaces/IPancakeV2Factory.sol";
import {IPancakeV2Router} from "../interfaces/IPancakeV2Router.sol";

contract PancakeV2Adapter is IDexAdapter {
    using SafeERC20 for IERC20;

    address public immutable router;
    address public immutable factory;
    address public immutable wbnb;

    error ZeroAddress();
    error RouterFactoryMismatch(address expectedFactory, address actualFactory);
    error RouterWbnbMismatch(address expectedWbnb, address actualWbnb);
    error InvalidAmount();
    error InvalidPath();
    error PairNotFound(address tokenIn, address tokenOut);
    error ExpiredDeadline(uint256 deadline, uint256 currentTimestamp);

    constructor(address router_, address factory_, address wbnb_) {
        if (router_ == address(0) || factory_ == address(0) || wbnb_ == address(0)) {
            revert ZeroAddress();
        }

        address actualFactory = IPancakeV2Router(router_).factory();
        if (actualFactory != factory_) {
            revert RouterFactoryMismatch(factory_, actualFactory);
        }

        address actualWbnb = IPancakeV2Router(router_).WETH();
        if (actualWbnb != wbnb_) {
            revert RouterWbnbMismatch(wbnb_, actualWbnb);
        }

        router = router_;
        factory = factory_;
        wbnb = wbnb_;
    }

    function swap(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut, bytes calldata routeData)
        external
        override
        returns (uint256 amountOut)
    {
        if (amountIn == 0) revert InvalidAmount();

        (address[] memory path, uint256 deadline) = abi.decode(routeData, (address[], uint256));
        _validatePath(tokenIn, tokenOut, path);
        _validatePairs(path);
        if (deadline < block.timestamp) revert ExpiredDeadline(deadline, block.timestamp);

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).forceApprove(router, amountIn);

        uint256[] memory amounts =
            IPancakeV2Router(router).swapExactTokensForTokens(amountIn, minAmountOut, path, msg.sender, deadline);

        IERC20(tokenIn).forceApprove(router, 0);
        amountOut = amounts[amounts.length - 1];
    }

    function quote(address tokenIn, address tokenOut, uint256 amountIn, bytes calldata routeData)
        external
        view
        returns (uint256 amountOut)
    {
        if (amountIn == 0) revert InvalidAmount();

        address[] memory path = abi.decode(routeData, (address[]));
        _validatePath(tokenIn, tokenOut, path);
        _validatePairs(path);

        uint256[] memory amounts = IPancakeV2Router(router).getAmountsOut(amountIn, path);
        return amounts[amounts.length - 1];
    }

    function encodeRouteData(address[] calldata path, uint256 deadline) external pure returns (bytes memory) {
        return abi.encode(path, deadline);
    }

    function encodeQuoteData(address[] calldata path) external pure returns (bytes memory) {
        return abi.encode(path);
    }

    function _validatePath(address tokenIn, address tokenOut, address[] memory path) private pure {
        if (tokenIn == address(0) || tokenOut == address(0)) revert ZeroAddress();
        if (path.length < 2 || path.length > 3 || path[0] != tokenIn || path[path.length - 1] != tokenOut) {
            revert InvalidPath();
        }

        for (uint256 i = 0; i < path.length; ++i) {
            if (path[i] == address(0)) revert ZeroAddress();
        }
    }

    function _validatePairs(address[] memory path) private view {
        address firstPair = IPancakeV2Factory(factory).getPair(path[0], path[1]);
        if (firstPair == address(0)) revert PairNotFound(path[0], path[1]);

        if (path.length == 3) {
            address secondPair = IPancakeV2Factory(factory).getPair(path[1], path[2]);
            if (secondPair == address(0)) revert PairNotFound(path[1], path[2]);
        }
    }
}
