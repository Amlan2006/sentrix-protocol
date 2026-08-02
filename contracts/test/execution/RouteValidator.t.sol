// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Test} from "forge-std/Test.sol";
import {RouteValidator} from "../../src/execution/RouteValidator.sol";
import {SentrixTypes} from "../../src/libraries/SentrixTypes.sol";

contract RouteValidatorTest is Test {
    event AdapterApprovalUpdated(address indexed adapter, bool approved);
    event TokenApprovalUpdated(address indexed token, bool approved);

    address private owner = address(0xA11CE);
    address private other = address(0xB0B);
    address private vault = address(0xA011);
    address private settlementToken = address(0x1001);
    address private tokenB = address(0x1002);
    address private tokenC = address(0x1003);
    address private adapterA = address(0xA001);
    address private adapterB = address(0xA002);
    address private unapprovedAdapter = address(0xBAD1);
    address private unapprovedToken = address(0xBAD2);

    RouteValidator private validator;

    function setUp() public {
        validator = new RouteValidator(owner);

        vm.startPrank(owner);
        validator.setAdapterApproval(adapterA, true);
        validator.setAdapterApproval(adapterB, true);
        validator.setTokenApproval(settlementToken, true);
        validator.setTokenApproval(tokenB, true);
        validator.setTokenApproval(tokenC, true);
        vm.stopPrank();
    }

    function test_ownerCanApproveAndRevokeAdapter() public {
        address adapter = address(0xA003);

        vm.prank(owner);
        vm.expectEmit(true, false, false, true, address(validator));
        emit AdapterApprovalUpdated(adapter, true);
        validator.setAdapterApproval(adapter, true);
        assertTrue(validator.approvedAdapters(adapter));

        vm.prank(owner);
        vm.expectEmit(true, false, false, true, address(validator));
        emit AdapterApprovalUpdated(adapter, false);
        validator.setAdapterApproval(adapter, false);
        assertFalse(validator.approvedAdapters(adapter));
    }

    function test_ownerCanApproveAndRevokeToken() public {
        address token = address(0x1004);

        vm.prank(owner);
        vm.expectEmit(true, false, false, true, address(validator));
        emit TokenApprovalUpdated(token, true);
        validator.setTokenApproval(token, true);
        assertTrue(validator.approvedTokens(token));

        vm.prank(owner);
        vm.expectEmit(true, false, false, true, address(validator));
        emit TokenApprovalUpdated(token, false);
        validator.setTokenApproval(token, false);
        assertFalse(validator.approvedTokens(token));
    }

    function test_nonOwnerCannotUpdatePolicy() public {
        vm.prank(other);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, other));
        validator.setAdapterApproval(address(0xA003), true);

        vm.prank(other);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, other));
        validator.setTokenApproval(address(0x1004), true);
    }

    function test_policyRejectsZeroAddress() public {
        vm.startPrank(owner);
        vm.expectRevert(RouteValidator.ZeroAddress.selector);
        validator.setAdapterApproval(address(0), true);

        vm.expectRevert(RouteValidator.ZeroAddress.selector);
        validator.setTokenApproval(address(0), true);
        vm.stopPrank();
    }

    function test_validTwoPoolRouteSucceeds() public view {
        assertTrue(validator.validateRoute(_twoPoolRequest(), _riskConfig(false), false));
    }

    function test_validTriangularRouteSucceeds() public view {
        assertTrue(validator.validateRoute(_triangularRequest(), _riskConfig(false), false));
    }

    function test_flashLoanRouteSucceedsWhenEnabled() public view {
        assertTrue(validator.validateRoute(_twoPoolRequest(), _riskConfig(true), true));
    }

    function test_arbitrageDisabledReverts() public {
        SentrixTypes.UserRiskConfig memory config = _riskConfig(false);
        config.arbitrageEnabled = false;

        vm.expectRevert(RouteValidator.ArbitrageDisabled.selector);
        validator.validateRoute(_twoPoolRequest(), config, false);
    }

    function test_flashLoanDisabledRevertsWhenRequested() public {
        vm.expectRevert(RouteValidator.FlashLoanArbitrageDisabled.selector);
        validator.validateRoute(_twoPoolRequest(), _riskConfig(false), true);
    }

    function test_expiredRequestReverts() public {
        SentrixTypes.ArbitrageRequest memory request = _twoPoolRequest();
        request.deadline = block.timestamp - 1;

        vm.expectRevert(
            abi.encodeWithSelector(RouteValidator.ExpiredRequest.selector, request.deadline, block.timestamp)
        );
        validator.validateRoute(request, _riskConfig(false), false);
    }

    function test_zeroBorrowAmountReverts() public {
        SentrixTypes.ArbitrageRequest memory request = _twoPoolRequest();
        request.borrowAmount = 0;

        vm.expectRevert(RouteValidator.InvalidBorrowAmount.selector);
        validator.validateRoute(request, _riskConfig(false), false);
    }

    function test_tradeSizeExceededReverts() public {
        SentrixTypes.ArbitrageRequest memory request = _twoPoolRequest();
        request.borrowAmount = 1_001e6;

        vm.expectRevert(abi.encodeWithSelector(RouteValidator.TradeSizeExceeded.selector, 1_001e6, 1_000e6));
        validator.validateRoute(request, _riskConfig(false), false);
    }

    function test_gasReimbursementExceededReverts() public {
        SentrixTypes.ArbitrageRequest memory request = _twoPoolRequest();
        request.maxGasReimbursement = 26e6;

        vm.expectRevert(abi.encodeWithSelector(RouteValidator.GasReimbursementExceeded.selector, 26e6, 25e6));
        validator.validateRoute(request, _riskConfig(false), false);
    }

    function test_zeroVaultOrSettlementTokenReverts() public {
        SentrixTypes.ArbitrageRequest memory request = _twoPoolRequest();
        request.vault = address(0);

        vm.expectRevert(RouteValidator.ZeroAddress.selector);
        validator.validateRoute(request, _riskConfig(false), false);

        request = _twoPoolRequest();
        request.settlementToken = address(0);

        vm.expectRevert(RouteValidator.ZeroAddress.selector);
        validator.validateRoute(request, _riskConfig(false), false);
    }

    function test_unapprovedSettlementTokenReverts() public {
        SentrixTypes.ArbitrageRequest memory request = _twoPoolRequest();
        request.settlementToken = unapprovedToken;
        request.swaps[0].tokenIn = unapprovedToken;
        request.swaps[1].tokenOut = unapprovedToken;

        vm.expectRevert(abi.encodeWithSelector(RouteValidator.UnapprovedToken.selector, unapprovedToken));
        validator.validateRoute(request, _riskConfig(false), false);
    }

    function test_wrongTwoPoolLengthReverts() public {
        SentrixTypes.ArbitrageRequest memory request = _triangularRequest();
        request.arbitrageType = SentrixTypes.ArbitrageType.TWO_POOL;

        vm.expectRevert(
            abi.encodeWithSelector(RouteValidator.InvalidRouteLength.selector, SentrixTypes.ArbitrageType.TWO_POOL, 3)
        );
        validator.validateRoute(request, _riskConfig(false), false);
    }

    function test_wrongTriangularLengthReverts() public {
        SentrixTypes.ArbitrageRequest memory request = _twoPoolRequest();
        request.arbitrageType = SentrixTypes.ArbitrageType.TRIANGULAR;

        vm.expectRevert(
            abi.encodeWithSelector(RouteValidator.InvalidRouteLength.selector, SentrixTypes.ArbitrageType.TRIANGULAR, 2)
        );
        validator.validateRoute(request, _riskConfig(false), false);
    }

    function test_wrongStartTokenReverts() public {
        SentrixTypes.ArbitrageRequest memory request = _twoPoolRequest();
        request.swaps[0].tokenIn = tokenB;

        vm.expectRevert(abi.encodeWithSelector(RouteValidator.InvalidRouteStart.selector, settlementToken, tokenB));
        validator.validateRoute(request, _riskConfig(false), false);
    }

    function test_wrongEndTokenReverts() public {
        SentrixTypes.ArbitrageRequest memory request = _twoPoolRequest();
        request.swaps[1].tokenOut = tokenB;

        vm.expectRevert(abi.encodeWithSelector(RouteValidator.InvalidRouteEnd.selector, settlementToken, tokenB));
        validator.validateRoute(request, _riskConfig(false), false);
    }

    function test_brokenTokenContinuityReverts() public {
        SentrixTypes.ArbitrageRequest memory request = _triangularRequest();
        request.swaps[1].tokenIn = settlementToken;

        vm.expectRevert(
            abi.encodeWithSelector(RouteValidator.BrokenTokenContinuity.selector, 1, tokenB, settlementToken)
        );
        validator.validateRoute(request, _riskConfig(false), false);
    }

    function test_unapprovedAdapterReverts() public {
        SentrixTypes.ArbitrageRequest memory request = _twoPoolRequest();
        request.swaps[0].adapter = unapprovedAdapter;

        vm.expectRevert(abi.encodeWithSelector(RouteValidator.UnapprovedAdapter.selector, unapprovedAdapter));
        validator.validateRoute(request, _riskConfig(false), false);
    }

    function test_unapprovedTokenInReverts() public {
        SentrixTypes.ArbitrageRequest memory request = _twoPoolRequest();
        request.swaps[1].tokenIn = unapprovedToken;

        vm.expectRevert(abi.encodeWithSelector(RouteValidator.UnapprovedToken.selector, unapprovedToken));
        validator.validateRoute(request, _riskConfig(false), false);
    }

    function test_unapprovedTokenOutReverts() public {
        SentrixTypes.ArbitrageRequest memory request = _twoPoolRequest();
        request.swaps[0].tokenOut = unapprovedToken;

        vm.expectRevert(abi.encodeWithSelector(RouteValidator.UnapprovedToken.selector, unapprovedToken));
        validator.validateRoute(request, _riskConfig(false), false);
    }

    function test_zeroSwapAddressesRevert() public {
        SentrixTypes.ArbitrageRequest memory request = _twoPoolRequest();
        request.swaps[0].adapter = address(0);

        vm.expectRevert(RouteValidator.ZeroAddress.selector);
        validator.validateRoute(request, _riskConfig(false), false);

        request = _twoPoolRequest();
        request.swaps[0].tokenIn = address(0);

        vm.expectRevert(RouteValidator.ZeroAddress.selector);
        validator.validateRoute(request, _riskConfig(false), false);

        request = _twoPoolRequest();
        request.swaps[0].tokenOut = address(0);

        vm.expectRevert(RouteValidator.ZeroAddress.selector);
        validator.validateRoute(request, _riskConfig(false), false);
    }

    function test_zeroMinAmountOutReverts() public {
        SentrixTypes.ArbitrageRequest memory request = _twoPoolRequest();
        request.swaps[1].minAmountOut = 0;

        vm.expectRevert(abi.encodeWithSelector(RouteValidator.InvalidMinAmountOut.selector, 1));
        validator.validateRoute(request, _riskConfig(false), false);
    }

    function _twoPoolRequest() private view returns (SentrixTypes.ArbitrageRequest memory request) {
        request.vault = vault;
        request.settlementToken = settlementToken;
        request.borrowAmount = 500e6;
        request.minGrossProfit = 1e6;
        request.maxGasReimbursement = 10e6;
        request.deadline = block.timestamp + 1 hours;
        request.arbitrageType = SentrixTypes.ArbitrageType.TWO_POOL;
        request.swaps = new SentrixTypes.SwapStep[](2);
        request.swaps[0] = SentrixTypes.SwapStep({
            adapter: adapterA, tokenIn: settlementToken, tokenOut: tokenB, minAmountOut: 1, routeData: ""
        });
        request.swaps[1] = SentrixTypes.SwapStep({
            adapter: adapterB, tokenIn: tokenB, tokenOut: settlementToken, minAmountOut: 1, routeData: ""
        });
    }

    function _triangularRequest() private view returns (SentrixTypes.ArbitrageRequest memory request) {
        request.vault = vault;
        request.settlementToken = settlementToken;
        request.borrowAmount = 500e6;
        request.minGrossProfit = 1e6;
        request.maxGasReimbursement = 10e6;
        request.deadline = block.timestamp + 1 hours;
        request.arbitrageType = SentrixTypes.ArbitrageType.TRIANGULAR;
        request.swaps = new SentrixTypes.SwapStep[](3);
        request.swaps[0] = SentrixTypes.SwapStep({
            adapter: adapterA, tokenIn: settlementToken, tokenOut: tokenB, minAmountOut: 1, routeData: ""
        });
        request.swaps[1] = SentrixTypes.SwapStep({
            adapter: adapterB, tokenIn: tokenB, tokenOut: tokenC, minAmountOut: 1, routeData: ""
        });
        request.swaps[2] = SentrixTypes.SwapStep({
            adapter: adapterA, tokenIn: tokenC, tokenOut: settlementToken, minAmountOut: 1, routeData: ""
        });
    }

    function _riskConfig(bool flashLoanEnabled) private pure returns (SentrixTypes.UserRiskConfig memory config) {
        config.minNetProfit = 1e6;
        config.maxTradeSize = 1_000e6;
        config.maxGasReimbursement = 25e6;
        config.maxSlippageBps = 100;
        config.reinvestmentBps = 2_500;
        config.arbitrageEnabled = true;
        config.flashLoanArbitrageEnabled = flashLoanEnabled;
        config.gridEnabled = false;
    }
}
