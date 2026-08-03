// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SentrixTypes} from "../libraries/SentrixTypes.sol";

interface IArbitrageExecutor {
    event UserFundedArbitrageExecuted(
        address indexed vault,
        address indexed settlementToken,
        address indexed executor,
        uint256 amountIn,
        uint256 amountOut,
        uint256 grossProfit
    );

    function executeArbitrage(SentrixTypes.ArbitrageRequest calldata request) external returns (uint256 grossProfit);
}
