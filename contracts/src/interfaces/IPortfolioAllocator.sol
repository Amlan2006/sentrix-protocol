// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IPortfolioAllocator {
    function allocate(address vault, address token, uint256 amount) external returns (bool);
}
