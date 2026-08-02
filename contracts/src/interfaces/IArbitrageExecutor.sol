// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SentrixTypes} from "../libraries/SentrixTypes.sol";

interface IArbitrageExecutor {
    function executeArbitrage(SentrixTypes.ArbitrageRequest calldata request) external returns (uint256 grossProfit);
}
