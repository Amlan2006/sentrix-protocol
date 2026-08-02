// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IOracleManager {
    function getPrice(address baseToken, address quoteToken) external view returns (uint256 price, uint256 updatedAt);
}
