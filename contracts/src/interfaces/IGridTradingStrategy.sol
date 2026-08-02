// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IGridTradingStrategy {
    function pauseGrid(uint256 gridId) external;
    function exitGrid(uint256 gridId) external;
}
