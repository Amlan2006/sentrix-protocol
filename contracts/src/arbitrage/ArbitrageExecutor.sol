// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IArbitrageExecutor} from "../interfaces/IArbitrageExecutor.sol";
import {IDexAdapter} from "../interfaces/IDexAdapter.sol";
import {IRouteValidator} from "../interfaces/IRouteValidator.sol";
import {IUserVault} from "../interfaces/IUserVault.sol";
import {SentrixTypes} from "../libraries/SentrixTypes.sol";

contract ArbitrageExecutor is IArbitrageExecutor, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IRouteValidator public immutable routeValidator;

    error ZeroAddress();
    error InvalidAmount();
    error InvalidSettlementToken(address expected, address actual);
    error InsufficientProfit(uint256 requiredAmountOut, uint256 actualAmountOut);
    error InvalidSwapOutput(uint256 stepIndex);
    error ResidualSettlementBalance(uint256 balance);
    error RouteValidationFailed();

    constructor(address routeValidator_) {
        if (routeValidator_ == address(0)) revert ZeroAddress();
        routeValidator = IRouteValidator(routeValidator_);
    }

    function executeArbitrage(SentrixTypes.ArbitrageRequest calldata request)
        external
        override
        nonReentrant
        returns (uint256 grossProfit)
    {
        if (request.vault == address(0) || request.settlementToken == address(0)) revert ZeroAddress();
        if (request.borrowAmount == 0) revert InvalidAmount();

        IUserVault vault = IUserVault(request.vault);
        address vaultSettlementToken = vault.settlementToken();
        if (vaultSettlementToken != request.settlementToken) {
            revert InvalidSettlementToken(vaultSettlementToken, request.settlementToken);
        }

        SentrixTypes.UserRiskConfig memory riskConfig = vault.riskConfig();
        if (!routeValidator.validateRoute(request, riskConfig, false)) revert RouteValidationFailed();

        uint256 amountIn = vault.startUserFundedArbitrage(request.borrowAmount, address(this));
        uint256 currentAmount = _executeSwap(request.swaps[0], amountIn, 0);
        currentAmount = _executeSwap(request.swaps[1], currentAmount, 1);

        if (request.arbitrageType == SentrixTypes.ArbitrageType.TRIANGULAR) {
            currentAmount = _executeSwap(request.swaps[2], currentAmount, 2);
        }

        uint256 requiredAmountOut = request.borrowAmount + request.minGrossProfit;
        if (currentAmount < requiredAmountOut) {
            revert InsufficientProfit(requiredAmountOut, currentAmount);
        }

        grossProfit = currentAmount - request.borrowAmount;
        IERC20(request.settlementToken).safeTransfer(request.vault, currentAmount);
        vault.finishUserFundedArbitrage(request.borrowAmount, grossProfit);

        uint256 residualSettlementBalance = IERC20(request.settlementToken).balanceOf(address(this));
        if (residualSettlementBalance != 0) revert ResidualSettlementBalance(residualSettlementBalance);

        emit UserFundedArbitrageExecuted(
            request.vault, request.settlementToken, msg.sender, request.borrowAmount, currentAmount, grossProfit
        );
    }

    function _executeSwap(SentrixTypes.SwapStep calldata step, uint256 amountIn, uint256 stepIndex)
        private
        returns (uint256 amountOut)
    {
        IERC20(step.tokenIn).forceApprove(step.adapter, amountIn);
        amountOut =
            IDexAdapter(step.adapter).swap(step.tokenIn, step.tokenOut, amountIn, step.minAmountOut, step.routeData);
        IERC20(step.tokenIn).forceApprove(step.adapter, 0);

        if (amountOut == 0) revert InvalidSwapOutput(stepIndex);
    }
}
