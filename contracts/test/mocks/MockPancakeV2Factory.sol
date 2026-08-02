// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MockPancakeV2Pair} from "./MockPancakeV2Pair.sol";

contract MockPancakeV2Factory {
    mapping(address tokenA => mapping(address tokenB => address pair)) public getPair;

    address[] public allPairs;

    error IdenticalTokens();
    error ZeroAddress();
    error PairExists();

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        if (tokenA == tokenB) revert IdenticalTokens();
        if (tokenA == address(0) || tokenB == address(0)) revert ZeroAddress();
        if (getPair[tokenA][tokenB] != address(0)) revert PairExists();

        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        pair = address(new MockPancakeV2Pair(token0, token1));
        getPair[tokenA][tokenB] = pair;
        getPair[tokenB][tokenA] = pair;
        allPairs.push(pair);
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }
}
