// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {ArbitrageExecutor} from "../../src/arbitrage/ArbitrageExecutor.sol";
import {RouteValidator} from "../../src/execution/RouteValidator.sol";
import {UserVault} from "../../src/vault/UserVault.sol";
import {SentrixTypes} from "../../src/libraries/SentrixTypes.sol";
import {MockAmmAdapter} from "../mocks/MockAmmAdapter.sol";
import {MockConstantProductPool} from "../mocks/MockConstantProductPool.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {FalseRouteValidator} from "../mocks/FalseRouteValidator.sol";
import {ZeroOutputDexAdapter} from "../mocks/ZeroOutputDexAdapter.sol";

contract ArbitrageExecutorTest is Test {
    address private owner = address(0xA11CE);
    address private validatorOwner = address(0xB0B);
    address private keeper = address(0xC0DE);

    MockERC20 private usdc;
    MockERC20 private wbnb;
    MockERC20 private wbtc;
    UserVault private vault;
    RouteValidator private routeValidator;
    ArbitrageExecutor private executor;
    MockAmmAdapter private adapterA;
    MockAmmAdapter private adapterB;

    function setUp() public {
        usdc = new MockERC20("Mock USDC", "mUSDC", 6);
        wbnb = new MockERC20("Mock WBNB", "mWBNB", 18);
        wbtc = new MockERC20("Mock WBTC", "mWBTC", 8);

        routeValidator = new RouteValidator(validatorOwner);
        executor = new ArbitrageExecutor(address(routeValidator));
        adapterA = new MockAmmAdapter();
        adapterB = new MockAmmAdapter();

        vault = new UserVault();
        vault.initialize(owner, address(usdc), _riskConfig(5_000));

        vm.startPrank(validatorOwner);
        routeValidator.setAdapterApproval(address(adapterA), true);
        routeValidator.setAdapterApproval(address(adapterB), true);
        routeValidator.setTokenApproval(address(usdc), true);
        routeValidator.setTokenApproval(address(wbnb), true);
        routeValidator.setTokenApproval(address(wbtc), true);
        vm.stopPrank();

        usdc.mint(owner, 1_000_000e6);
        vm.startPrank(owner);
        usdc.approve(address(vault), 100_000e6);
        vault.deposit(100_000e6);
        vault.authorizeStrategy(address(executor));
        vm.stopPrank();
    }

    function test_executeProfitableTwoPoolArbitrageCreditsVaultAccounting() public {
        MockConstantProductPool cheapWbnbPool = _seedPool(usdc, wbnb, 2_000_000e6, 1_000e18);
        MockConstantProductPool expensiveWbnbPool = _seedPool(usdc, wbnb, 2_200_000e6, 1_000e18);
        adapterA.registerPool(address(usdc), address(wbnb), address(cheapWbnbPool));
        adapterB.registerPool(address(usdc), address(wbnb), address(expensiveWbnbPool));

        SentrixTypes.ArbitrageRequest memory request = _twoPoolRequest(10_000e6, 100e6);
        uint256 grossProfit = executor.executeArbitrage(request);
        SentrixTypes.VaultAccounting memory accounting = vault.accounting();

        assertGt(grossProfit, 100e6);
        assertEq(usdc.balanceOf(address(executor)), 0);
        assertEq(accounting.grossArbitrageProfit, grossProfit);
        assertEq(accounting.netArbitrageProfit, grossProfit);
        assertEq(accounting.withdrawableProfit, grossProfit / 2);
        assertEq(accounting.reinvestmentCapital, grossProfit - (grossProfit / 2));
        assertEq(accounting.idleSettlementBalance, 100_000e6 + (grossProfit / 2));
    }

    function test_executeProfitableTriangularArbitrageCreditsVaultAccounting() public {
        MockConstantProductPool usdcWbnbPool = _seedPool(usdc, wbnb, 2_000_000e6, 1_000e18);
        MockConstantProductPool wbnbWbtcPool = _seedPool(wbnb, wbtc, 1_000e18, 50e8);
        MockConstantProductPool wbtcUsdcPool = _seedPool(wbtc, usdc, 50e8, 2_200_000e6);
        adapterA.registerPool(address(usdc), address(wbnb), address(usdcWbnbPool));
        adapterA.registerPool(address(wbnb), address(wbtc), address(wbnbWbtcPool));
        adapterA.registerPool(address(wbtc), address(usdc), address(wbtcUsdcPool));

        SentrixTypes.ArbitrageRequest memory request = _triangularRequest(10_000e6, 100e6);
        uint256 grossProfit = executor.executeArbitrage(request);

        assertGt(grossProfit, 100e6);
        assertEq(usdc.balanceOf(address(executor)), 0);
        assertEq(vault.accounting().grossArbitrageProfit, grossProfit);
    }

    function test_unprofitableRouteRevertsAtomically() public {
        MockConstantProductPool firstPool = _seedPool(usdc, wbnb, 2_000_000e6, 1_000e18);
        MockConstantProductPool secondPool = _seedPool(usdc, wbnb, 1_950_000e6, 1_000e18);
        adapterA.registerPool(address(usdc), address(wbnb), address(firstPool));
        adapterB.registerPool(address(usdc), address(wbnb), address(secondPool));

        SentrixTypes.ArbitrageRequest memory request = _twoPoolRequest(10_000e6, 1);
        uint256 startingVaultBalance = usdc.balanceOf(address(vault));
        SentrixTypes.VaultAccounting memory startingAccounting = vault.accounting();

        vm.expectRevert();
        executor.executeArbitrage(request);

        SentrixTypes.VaultAccounting memory endingAccounting = vault.accounting();
        assertEq(usdc.balanceOf(address(vault)), startingVaultBalance);
        assertEq(endingAccounting.idleSettlementBalance, startingAccounting.idleSettlementBalance);
        assertEq(endingAccounting.grossArbitrageProfit, 0);
    }

    function test_routeValidationFailureReverts() public {
        SentrixTypes.ArbitrageRequest memory request = _twoPoolRequest(10_000e6, 1);
        request.swaps[0].adapter = address(0xBAD);

        vm.expectRevert(abi.encodeWithSelector(RouteValidator.UnapprovedAdapter.selector, address(0xBAD)));
        executor.executeArbitrage(request);
    }

    function test_wrongSettlementTokenReverts() public {
        SentrixTypes.ArbitrageRequest memory request = _twoPoolRequest(10_000e6, 1);
        request.settlementToken = address(wbtc);

        vm.expectRevert(
            abi.encodeWithSelector(ArbitrageExecutor.InvalidSettlementToken.selector, address(usdc), address(wbtc))
        );
        executor.executeArbitrage(request);
    }

    function test_constructorRejectsZeroRouteValidator() public {
        vm.expectRevert(ArbitrageExecutor.ZeroAddress.selector);
        new ArbitrageExecutor(address(0));
    }

    function test_zeroVaultOrSettlementTokenReverts() public {
        SentrixTypes.ArbitrageRequest memory request = _twoPoolRequest(10_000e6, 1);
        request.vault = address(0);

        vm.expectRevert(ArbitrageExecutor.ZeroAddress.selector);
        executor.executeArbitrage(request);

        request = _twoPoolRequest(10_000e6, 1);
        request.settlementToken = address(0);

        vm.expectRevert(ArbitrageExecutor.ZeroAddress.selector);
        executor.executeArbitrage(request);
    }

    function test_zeroBorrowAmountReverts() public {
        SentrixTypes.ArbitrageRequest memory request = _twoPoolRequest(0, 1);

        vm.expectRevert(ArbitrageExecutor.InvalidAmount.selector);
        executor.executeArbitrage(request);
    }

    function test_falseRouteValidatorReverts() public {
        ArbitrageExecutor falseValidatorExecutor = new ArbitrageExecutor(address(new FalseRouteValidator()));
        vm.prank(owner);
        vault.authorizeStrategy(address(falseValidatorExecutor));

        vm.expectRevert(ArbitrageExecutor.RouteValidationFailed.selector);
        falseValidatorExecutor.executeArbitrage(_twoPoolRequest(10_000e6, 1));
    }

    function test_zeroOutputAdapterRevertsAtomically() public {
        ZeroOutputDexAdapter zeroOutputAdapter = new ZeroOutputDexAdapter();
        vm.prank(validatorOwner);
        routeValidator.setAdapterApproval(address(zeroOutputAdapter), true);

        SentrixTypes.ArbitrageRequest memory request = _twoPoolRequest(10_000e6, 1);
        request.swaps[0].adapter = address(zeroOutputAdapter);

        uint256 startingVaultBalance = usdc.balanceOf(address(vault));

        vm.expectRevert(abi.encodeWithSelector(ArbitrageExecutor.InvalidSwapOutput.selector, uint256(0)));
        executor.executeArbitrage(request);

        assertEq(usdc.balanceOf(address(vault)), startingVaultBalance);
    }

    function test_insufficientProfitReverts() public {
        MockConstantProductPool cheapWbnbPool = _seedPool(usdc, wbnb, 2_000_000e6, 1_000e18);
        MockConstantProductPool expensiveWbnbPool = _seedPool(usdc, wbnb, 2_200_000e6, 1_000e18);
        adapterA.registerPool(address(usdc), address(wbnb), address(cheapWbnbPool));
        adapterB.registerPool(address(usdc), address(wbnb), address(expensiveWbnbPool));

        SentrixTypes.ArbitrageRequest memory request = _twoPoolRequest(10_000e6, 50_000e6);

        vm.expectRevert();
        executor.executeArbitrage(request);
    }

    function test_unauthorizedExecutorCannotMoveVaultFunds() public {
        ArbitrageExecutor unauthorizedExecutor = new ArbitrageExecutor(address(routeValidator));

        vm.expectRevert(UserVault.Unauthorized.selector);
        unauthorizedExecutor.executeArbitrage(_twoPoolRequest(10_000e6, 1));
    }

    function test_pausedVaultRejectsExecutionStart() public {
        vm.prank(owner);
        vault.pauseEmergency();

        vm.expectRevert(UserVault.PausedOperation.selector);
        executor.executeArbitrage(_twoPoolRequest(10_000e6, 1));
    }

    function test_insufficientIdleBalanceReverts() public {
        SentrixTypes.ArbitrageRequest memory request = _twoPoolRequest(200_000e6, 1);
        vm.expectRevert(
            abi.encodeWithSelector(RouteValidator.TradeSizeExceeded.selector, uint256(200_000e6), uint256(100_000e6))
        );
        executor.executeArbitrage(request);
    }

    function test_finishWithoutReturnedFundsReverts() public {
        vm.expectRevert();
        vm.prank(address(executor));
        vault.finishUserFundedArbitrage(10_000e6, 100e6);
    }

    function _seedPool(MockERC20 token0, MockERC20 token1, uint256 amount0, uint256 amount1)
        private
        returns (MockConstantProductPool pool)
    {
        pool = new MockConstantProductPool(address(token0), address(token1));

        token0.mint(address(this), amount0);
        token1.mint(address(this), amount1);
        token0.approve(address(pool), amount0);
        token1.approve(address(pool), amount1);
        pool.seed(amount0, amount1);
    }

    function _twoPoolRequest(uint256 borrowAmount, uint256 minGrossProfit)
        private
        view
        returns (SentrixTypes.ArbitrageRequest memory request)
    {
        SentrixTypes.SwapStep[] memory swaps = new SentrixTypes.SwapStep[](2);
        swaps[0] = SentrixTypes.SwapStep(address(adapterA), address(usdc), address(wbnb), 1, "");
        swaps[1] = SentrixTypes.SwapStep(address(adapterB), address(wbnb), address(usdc), 1, "");

        request = SentrixTypes.ArbitrageRequest(
            address(vault),
            address(usdc),
            borrowAmount,
            minGrossProfit,
            0,
            block.timestamp + 1 hours,
            SentrixTypes.ArbitrageType.TWO_POOL,
            swaps
        );
    }

    function _triangularRequest(uint256 borrowAmount, uint256 minGrossProfit)
        private
        view
        returns (SentrixTypes.ArbitrageRequest memory request)
    {
        SentrixTypes.SwapStep[] memory swaps = new SentrixTypes.SwapStep[](3);
        swaps[0] = SentrixTypes.SwapStep(address(adapterA), address(usdc), address(wbnb), 1, "");
        swaps[1] = SentrixTypes.SwapStep(address(adapterA), address(wbnb), address(wbtc), 1, "");
        swaps[2] = SentrixTypes.SwapStep(address(adapterA), address(wbtc), address(usdc), 1, "");

        request = SentrixTypes.ArbitrageRequest(
            address(vault),
            address(usdc),
            borrowAmount,
            minGrossProfit,
            0,
            block.timestamp + 1 hours,
            SentrixTypes.ArbitrageType.TRIANGULAR,
            swaps
        );
    }

    function _riskConfig(uint16 reinvestmentBps) private pure returns (SentrixTypes.UserRiskConfig memory) {
        return SentrixTypes.UserRiskConfig({
            minNetProfit: 1,
            maxTradeSize: 100_000e6,
            maxGasReimbursement: 25e6,
            maxSlippageBps: 500,
            reinvestmentBps: reinvestmentBps,
            arbitrageEnabled: true,
            flashLoanArbitrageEnabled: false,
            gridEnabled: false
        });
    }
}
