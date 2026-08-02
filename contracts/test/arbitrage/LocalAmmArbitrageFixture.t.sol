// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {MockAmmAdapter} from "../mocks/MockAmmAdapter.sol";
import {MockConstantProductPool} from "../mocks/MockConstantProductPool.sol";
import {MockERC20} from "../mocks/MockERC20.sol";

contract LocalAmmArbitrageFixtureTest is Test {
    address private trader = address(0xA11CE);

    MockERC20 private usdc;
    MockERC20 private weth;
    MockERC20 private wbtc;
    MockAmmAdapter private adapter;

    function setUp() public {
        usdc = new MockERC20("Mock USDC", "mUSDC", 6);
        weth = new MockERC20("Mock WETH", "mWETH", 18);
        wbtc = new MockERC20("Mock WBTC", "mWBTC", 8);
        adapter = new MockAmmAdapter();

        usdc.mint(trader, 1_000_000e6);
        weth.mint(trader, 1_000e18);
        wbtc.mint(trader, 100e8);
    }

    function test_twoPoolProfitableRouteProducesMoreSettlementToken() public {
        MockConstantProductPool cheapWethPool = _seedPool(usdc, weth, 2_000_000e6, 1_000e18);
        MockConstantProductPool expensiveWethPool = _seedPool(usdc, weth, 2_200_000e6, 1_000e18);

        adapter.registerPool(address(usdc), address(weth), address(cheapWethPool));

        uint256 startingAmount = 10_000e6;
        uint256 wethOut = _swap(usdc, weth, startingAmount, 1);

        adapter.registerPool(address(usdc), address(weth), address(expensiveWethPool));
        uint256 finalAmount = _swap(weth, usdc, wethOut, 1);

        assertGt(finalAmount, startingAmount);
    }

    function test_twoPoolNearBreakEvenRouteIsDeterministic() public {
        MockConstantProductPool firstPool = _seedPool(usdc, weth, 2_000_000e6, 1_000e18);
        MockConstantProductPool secondPool = _seedPool(usdc, weth, 2_032_060e6, 1_000e18);

        adapter.registerPool(address(usdc), address(weth), address(firstPool));

        uint256 startingAmount = 10_000e6;
        uint256 wethOut = _swap(usdc, weth, startingAmount, 1);

        adapter.registerPool(address(usdc), address(weth), address(secondPool));
        uint256 finalAmount = _swap(weth, usdc, wethOut, 1);

        assertApproxEqAbs(finalAmount, startingAmount, 1e6);
    }

    function test_twoPoolUnprofitableRouteProducesLessSettlementToken() public {
        MockConstantProductPool firstPool = _seedPool(usdc, weth, 2_000_000e6, 1_000e18);
        MockConstantProductPool secondPool = _seedPool(usdc, weth, 1_950_000e6, 1_000e18);

        adapter.registerPool(address(usdc), address(weth), address(firstPool));

        uint256 startingAmount = 10_000e6;
        uint256 wethOut = _swap(usdc, weth, startingAmount, 1);

        adapter.registerPool(address(usdc), address(weth), address(secondPool));
        uint256 finalAmount = _swap(weth, usdc, wethOut, 1);

        assertLt(finalAmount, startingAmount);
    }

    function test_triangularProfitableRouteProducesMoreSettlementToken() public {
        MockConstantProductPool usdcWethPool = _seedPool(usdc, weth, 2_000_000e6, 1_000e18);
        MockConstantProductPool wethWbtcPool = _seedPool(weth, wbtc, 1_000e18, 50e8);
        MockConstantProductPool wbtcUsdcPool = _seedPool(wbtc, usdc, 50e8, 2_200_000e6);

        adapter.registerPool(address(usdc), address(weth), address(usdcWethPool));
        adapter.registerPool(address(weth), address(wbtc), address(wethWbtcPool));
        adapter.registerPool(address(wbtc), address(usdc), address(wbtcUsdcPool));

        uint256 startingAmount = 10_000e6;
        uint256 wethOut = _swap(usdc, weth, startingAmount, 1);
        uint256 wbtcOut = _swap(weth, wbtc, wethOut, 1);
        uint256 finalAmount = _swap(wbtc, usdc, wbtcOut, 1);

        assertGt(finalAmount, startingAmount);
    }

    function test_unregisteredPoolReverts() public {
        vm.startPrank(trader);
        usdc.approve(address(adapter), 1e6);
        vm.expectRevert(MockAmmAdapter.PoolNotRegistered.selector);
        adapter.swap(address(usdc), address(weth), 1e6, 1, "");
        vm.stopPrank();
    }

    function test_wrongRouteDataPoolReverts() public {
        MockConstantProductPool pool = _seedPool(usdc, weth, 2_000_000e6, 1_000e18);
        MockConstantProductPool wrongPool = _seedPool(usdc, weth, 2_100_000e6, 1_000e18);
        adapter.registerPool(address(usdc), address(weth), address(pool));

        vm.startPrank(trader);
        usdc.approve(address(adapter), 1e6);
        vm.expectRevert(MockAmmAdapter.InvalidRouteData.selector);
        adapter.swap(address(usdc), address(weth), 1e6, 1, abi.encode(address(wrongPool)));
        vm.stopPrank();
    }

    function test_zeroAmountInputReverts() public {
        MockConstantProductPool pool = _seedPool(usdc, weth, 2_000_000e6, 1_000e18);
        adapter.registerPool(address(usdc), address(weth), address(pool));

        vm.expectRevert(MockAmmAdapter.InvalidAmount.selector);
        adapter.swap(address(usdc), address(weth), 0, 1, "");
    }

    function test_slippageFailureReverts() public {
        MockConstantProductPool pool = _seedPool(usdc, weth, 2_000_000e6, 1_000e18);
        adapter.registerPool(address(usdc), address(weth), address(pool));
        uint256 quote = adapter.quote(address(usdc), address(weth), 1_000e6);

        vm.startPrank(trader);
        usdc.approve(address(adapter), 1_000e6);
        vm.expectRevert(abi.encodeWithSelector(MockConstantProductPool.SlippageExceeded.selector, quote, quote + 1));
        adapter.swap(address(usdc), address(weth), 1_000e6, quote + 1, "");
        vm.stopPrank();
    }

    function test_wrongTokenPairReverts() public {
        MockConstantProductPool pool = _seedPool(usdc, weth, 2_000_000e6, 1_000e18);

        vm.startPrank(trader);
        usdc.approve(address(pool), 1_000e6);
        vm.expectRevert(MockConstantProductPool.InvalidTokenPair.selector);
        pool.swap(address(usdc), address(wbtc), 1_000e6, 1, trader);
        vm.stopPrank();
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

    function _swap(MockERC20 tokenIn, MockERC20 tokenOut, uint256 amountIn, uint256 minAmountOut)
        private
        returns (uint256 amountOut)
    {
        vm.startPrank(trader);
        tokenIn.approve(address(adapter), amountIn);
        amountOut = adapter.swap(address(tokenIn), address(tokenOut), amountIn, minAmountOut, "");
        vm.stopPrank();
    }
}
