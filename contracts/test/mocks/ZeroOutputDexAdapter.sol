// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IDexAdapter} from "../../src/interfaces/IDexAdapter.sol";

contract ZeroOutputDexAdapter is IDexAdapter {
    function swap(address, address, uint256, uint256, bytes calldata) external pure returns (uint256) {
        return 0;
    }
}
