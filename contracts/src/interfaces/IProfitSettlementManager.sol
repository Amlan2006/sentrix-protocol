// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IProfitSettlementManager {
    function settleProfit(address vault, uint256 grossProfit, uint256 gasReimbursement)
        external
        returns (uint256 netProfit);
}
