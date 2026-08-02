// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IRouteValidator} from "../interfaces/IRouteValidator.sol";
import {SentrixTypes} from "../libraries/SentrixTypes.sol";

contract RouteValidator is IRouteValidator, Ownable {
    error ZeroAddress();
    error ArbitrageDisabled();
    error FlashLoanArbitrageDisabled();
    error InvalidBorrowAmount();
    error TradeSizeExceeded(uint256 requested, uint256 maximum);
    error GasReimbursementExceeded(uint256 requested, uint256 maximum);
    error ExpiredRequest(uint256 deadline, uint256 currentTimestamp);
    error InvalidRouteLength(SentrixTypes.ArbitrageType arbitrageType, uint256 length);
    error UnapprovedAdapter(address adapter);
    error UnapprovedToken(address token);
    error InvalidRouteStart(address expected, address actual);
    error InvalidRouteEnd(address expected, address actual);
    error BrokenTokenContinuity(uint256 stepIndex, address previousTokenOut, address nextTokenIn);
    error InvalidMinAmountOut(uint256 stepIndex);

    event AdapterApprovalUpdated(address indexed adapter, bool approved);
    event TokenApprovalUpdated(address indexed token, bool approved);

    mapping(address adapter => bool approved) public approvedAdapters;
    mapping(address token => bool approved) public approvedTokens;

    constructor(address owner_) Ownable(owner_) {
        if (owner_ == address(0)) revert ZeroAddress();
    }

    function setAdapterApproval(address adapter, bool approved) external onlyOwner {
        if (adapter == address(0)) revert ZeroAddress();
        approvedAdapters[adapter] = approved;
        emit AdapterApprovalUpdated(adapter, approved);
    }

    function setTokenApproval(address token, bool approved) external onlyOwner {
        if (token == address(0)) revert ZeroAddress();
        approvedTokens[token] = approved;
        emit TokenApprovalUpdated(token, approved);
    }

    function validateRoute(
        SentrixTypes.ArbitrageRequest calldata request,
        SentrixTypes.UserRiskConfig calldata riskConfig,
        bool usesFlashLoan
    ) external view override returns (bool) {
        _validateRequest(request, riskConfig, usesFlashLoan);
        _validateRouteShape(request);
        return true;
    }

    function _validateRequest(
        SentrixTypes.ArbitrageRequest calldata request,
        SentrixTypes.UserRiskConfig calldata riskConfig,
        bool usesFlashLoan
    ) private view {
        if (request.vault == address(0) || request.settlementToken == address(0)) revert ZeroAddress();
        if (!riskConfig.arbitrageEnabled) revert ArbitrageDisabled();
        if (usesFlashLoan && !riskConfig.flashLoanArbitrageEnabled) revert FlashLoanArbitrageDisabled();
        if (request.borrowAmount == 0) revert InvalidBorrowAmount();
        if (request.borrowAmount > riskConfig.maxTradeSize) {
            revert TradeSizeExceeded(request.borrowAmount, riskConfig.maxTradeSize);
        }
        if (request.maxGasReimbursement > riskConfig.maxGasReimbursement) {
            revert GasReimbursementExceeded(request.maxGasReimbursement, riskConfig.maxGasReimbursement);
        }
        if (request.deadline < block.timestamp) revert ExpiredRequest(request.deadline, block.timestamp);
        if (!approvedTokens[request.settlementToken]) revert UnapprovedToken(request.settlementToken);
    }

    function _validateRouteShape(SentrixTypes.ArbitrageRequest calldata request) private view {
        uint256 routeLength = request.swaps.length;
        uint256 expectedLength = request.arbitrageType == SentrixTypes.ArbitrageType.TWO_POOL ? 2 : 3;

        if (routeLength != expectedLength) {
            revert InvalidRouteLength(request.arbitrageType, routeLength);
        }

        for (uint256 i = 0; i < routeLength; i++) {
            SentrixTypes.SwapStep calldata step = request.swaps[i];
            _validateSwapStep(step, i);

            if (i > 0 && request.swaps[i - 1].tokenOut != step.tokenIn) {
                revert BrokenTokenContinuity(i, request.swaps[i - 1].tokenOut, step.tokenIn);
            }
        }

        if (request.swaps[0].tokenIn != request.settlementToken) {
            revert InvalidRouteStart(request.settlementToken, request.swaps[0].tokenIn);
        }

        address finalToken = request.swaps[routeLength - 1].tokenOut;
        if (finalToken != request.settlementToken) {
            revert InvalidRouteEnd(request.settlementToken, finalToken);
        }
    }

    function _validateSwapStep(SentrixTypes.SwapStep calldata step, uint256 stepIndex) private view {
        if (step.adapter == address(0) || step.tokenIn == address(0) || step.tokenOut == address(0)) {
            revert ZeroAddress();
        }
        if (!approvedAdapters[step.adapter]) revert UnapprovedAdapter(step.adapter);
        if (!approvedTokens[step.tokenIn]) revert UnapprovedToken(step.tokenIn);
        if (!approvedTokens[step.tokenOut]) revert UnapprovedToken(step.tokenOut);
        if (step.minAmountOut == 0) revert InvalidMinAmountOut(stepIndex);
    }
}
