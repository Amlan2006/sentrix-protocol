// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library SentrixTypes {
    enum ArbitrageType {
        TWO_POOL,
        TRIANGULAR
    }

    struct SwapStep {
        address adapter;
        address tokenIn;
        address tokenOut;
        uint256 minAmountOut;
        bytes routeData;
    }

    struct ArbitrageRequest {
        address vault;
        address settlementToken;
        uint256 borrowAmount;
        uint256 minGrossProfit;
        uint256 maxGasReimbursement;
        uint256 deadline;
        ArbitrageType arbitrageType;
        SwapStep[] swaps;
    }

    struct UserRiskConfig {
        uint256 minNetProfit;
        uint256 maxTradeSize;
        uint256 maxGasReimbursement;
        uint16 maxSlippageBps;
        uint16 reinvestmentBps;
        bool arbitrageEnabled;
        bool flashLoanArbitrageEnabled;
        bool gridEnabled;
    }

    struct VaultAccounting {
        uint256 principalDeposited;
        uint256 principalWithdrawn;
        uint256 idleSettlementBalance;
        uint256 grossArbitrageProfit;
        uint256 flashLoanFeesPaid;
        uint256 gasReimbursementsPaid;
        uint256 protocolFeesPaid;
        uint256 executorFeesPaid;
        uint256 netArbitrageProfit;
        uint256 withdrawableProfit;
        uint256 reinvestmentCapital;
        uint256 activeGridCapital;
        uint256 realizedGridProfit;
    }
}
