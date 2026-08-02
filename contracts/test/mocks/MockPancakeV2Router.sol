// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MockPancakeV2Factory} from "./MockPancakeV2Factory.sol";
import {MockPancakeV2Pair} from "./MockPancakeV2Pair.sol";

contract MockPancakeV2Router {
    using SafeERC20 for IERC20;

    address public immutable factory;
    address public immutable WETH;

    error InvalidPath();
    error PairNotFound();
    error ExpiredDeadline();

    constructor(address factory_, address wbnb_) {
        factory = factory_;
        WETH = wbnb_;
    }

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts) {
        if (path.length < 2) revert InvalidPath();

        amounts = new uint256[](path.length);
        amounts[0] = amountIn;

        for (uint256 i = 0; i < path.length - 1; ++i) {
            address pair = MockPancakeV2Factory(factory).getPair(path[i], path[i + 1]);
            if (pair == address(0)) revert PairNotFound();
            amounts[i + 1] = MockPancakeV2Pair(pair).quote(path[i], path[i + 1], amounts[i]);
        }
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts) {
        if (deadline < block.timestamp) revert ExpiredDeadline();

        amounts = this.getAmountsOut(amountIn, path);
        if (amounts[amounts.length - 1] < amountOutMin) {
            revert MockPancakeV2Pair.SlippageExceeded(amounts[amounts.length - 1], amountOutMin);
        }

        IERC20(path[0]).safeTransferFrom(msg.sender, _pairFor(path[0], path[1]), amountIn);

        for (uint256 i = 0; i < path.length - 1; ++i) {
            address recipient = i == path.length - 2 ? to : _pairFor(path[i + 1], path[i + 2]);
            MockPancakeV2Pair(_pairFor(path[i], path[i + 1])).swap(path[i], path[i + 1], amounts[i], 0, recipient);
        }
    }

    function _pairFor(address tokenA, address tokenB) private view returns (address pair) {
        pair = MockPancakeV2Factory(factory).getPair(tokenA, tokenB);
        if (pair == address(0)) revert PairNotFound();
    }
}
