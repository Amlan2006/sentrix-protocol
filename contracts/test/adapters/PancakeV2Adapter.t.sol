// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {PancakeV2Adapter} from "../../src/adapters/PancakeV2Adapter.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {MockPancakeV2Factory} from "../mocks/MockPancakeV2Factory.sol";
import {MockPancakeV2Pair} from "../mocks/MockPancakeV2Pair.sol";
import {MockPancakeV2Router} from "../mocks/MockPancakeV2Router.sol";

contract PancakeV2AdapterTest is Test {
    address private trader = address(0xA11CE);

    MockERC20 private usdc;
    MockERC20 private wbnb;
    MockERC20 private wbtc;
    MockPancakeV2Factory private factory;
    MockPancakeV2Router private router;
    PancakeV2Adapter private adapter;

    function setUp() public {
        usdc = new MockERC20("Mock USDC", "mUSDC", 6);
        wbnb = new MockERC20("Wrapped BNB", "WBNB", 18);
        wbtc = new MockERC20("Mock WBTC", "mWBTC", 8);

        factory = new MockPancakeV2Factory();
        router = new MockPancakeV2Router(address(factory), address(wbnb));
        adapter = new PancakeV2Adapter(address(router), address(factory), address(wbnb));

        usdc.mint(trader, 1_000_000e6);
        wbnb.mint(trader, 1_000e18);
        wbtc.mint(trader, 100e8);
    }

    function test_constructorPinsRouterFactoryAndWbnb() public view {
        assertEq(adapter.router(), address(router));
        assertEq(adapter.factory(), address(factory));
        assertEq(adapter.wbnb(), address(wbnb));
    }

    function test_constructorRejectsZeroAddress() public {
        vm.expectRevert(PancakeV2Adapter.ZeroAddress.selector);
        new PancakeV2Adapter(address(0), address(factory), address(wbnb));

        vm.expectRevert(PancakeV2Adapter.ZeroAddress.selector);
        new PancakeV2Adapter(address(router), address(0), address(wbnb));

        vm.expectRevert(PancakeV2Adapter.ZeroAddress.selector);
        new PancakeV2Adapter(address(router), address(factory), address(0));
    }

    function test_constructorRejectsWrongFactory() public {
        MockPancakeV2Factory wrongFactory = new MockPancakeV2Factory();

        vm.expectRevert(
            abi.encodeWithSelector(
                PancakeV2Adapter.RouterFactoryMismatch.selector, address(wrongFactory), address(factory)
            )
        );
        new PancakeV2Adapter(address(router), address(wrongFactory), address(wbnb));
    }

    function test_constructorRejectsWrongWbnb() public {
        MockERC20 wrongWbnb = new MockERC20("Wrong WBNB", "wWBNB", 18);

        vm.expectRevert(
            abi.encodeWithSelector(PancakeV2Adapter.RouterWbnbMismatch.selector, address(wrongWbnb), address(wbnb))
        );
        new PancakeV2Adapter(address(router), address(factory), address(wrongWbnb));
    }

    function test_quoteReturnsPancakeRouterOutput() public {
        _seedPair(usdc, wbnb, 2_000_000e6, 1_000e18);

        address[] memory path = _path(address(usdc), address(wbnb));
        uint256 amountOut = adapter.quote(address(usdc), address(wbnb), 10_000e6, abi.encode(path));

        assertGt(amountOut, 0);
    }

    function test_swapTransfersOutputToCaller() public {
        _seedPair(usdc, wbnb, 2_000_000e6, 1_000e18);

        address[] memory path = _path(address(usdc), address(wbnb));
        uint256 amountIn = 10_000e6;
        uint256 quote = adapter.quote(address(usdc), address(wbnb), amountIn, abi.encode(path));

        vm.startPrank(trader);
        usdc.approve(address(adapter), amountIn);
        uint256 amountOut =
            adapter.swap(address(usdc), address(wbnb), amountIn, quote, abi.encode(path, block.timestamp));
        vm.stopPrank();

        assertEq(amountOut, quote);
        assertEq(wbnb.balanceOf(trader), 1_000e18 + quote);
    }

    function test_triangularQuoteAndSwapUsesWbnbPath() public {
        _seedPair(usdc, wbnb, 2_000_000e6, 1_000e18);
        _seedPair(wbnb, wbtc, 1_000e18, 50e8);

        address[] memory path = _path(address(usdc), address(wbnb), address(wbtc));
        uint256 amountIn = 10_000e6;
        uint256 quote = adapter.quote(address(usdc), address(wbtc), amountIn, abi.encode(path));

        vm.startPrank(trader);
        usdc.approve(address(adapter), amountIn);
        uint256 amountOut =
            adapter.swap(address(usdc), address(wbtc), amountIn, quote, abi.encode(path, block.timestamp));
        vm.stopPrank();

        assertEq(amountOut, quote);
        assertEq(wbtc.balanceOf(trader), 100e8 + quote);
    }

    function test_swapRejectsZeroAmount() public {
        address[] memory path = _path(address(usdc), address(wbnb));

        vm.expectRevert(PancakeV2Adapter.InvalidAmount.selector);
        adapter.swap(address(usdc), address(wbnb), 0, 1, abi.encode(path, block.timestamp));
    }

    function test_quoteRejectsInvalidPath() public {
        address[] memory path = _path(address(wbnb), address(usdc));

        vm.expectRevert(PancakeV2Adapter.InvalidPath.selector);
        adapter.quote(address(usdc), address(wbnb), 1e6, abi.encode(path));
    }

    function test_swapRejectsExpiredDeadline() public {
        _seedPair(usdc, wbnb, 2_000_000e6, 1_000e18);
        address[] memory path = _path(address(usdc), address(wbnb));

        vm.expectRevert(
            abi.encodeWithSelector(PancakeV2Adapter.ExpiredDeadline.selector, block.timestamp - 1, block.timestamp)
        );
        adapter.swap(address(usdc), address(wbnb), 1e6, 1, abi.encode(path, block.timestamp - 1));
    }

    function test_missingPairReverts() public {
        address[] memory path = _path(address(usdc), address(wbnb));

        vm.expectRevert(abi.encodeWithSelector(PancakeV2Adapter.PairNotFound.selector, address(usdc), address(wbnb)));
        adapter.quote(address(usdc), address(wbnb), 1e6, abi.encode(path));
    }

    function _seedPair(MockERC20 tokenA, MockERC20 tokenB, uint256 amountA, uint256 amountB)
        private
        returns (MockPancakeV2Pair pair)
    {
        address pairAddress = factory.getPair(address(tokenA), address(tokenB));
        if (pairAddress == address(0)) {
            pairAddress = factory.createPair(address(tokenA), address(tokenB));
        }

        pair = MockPancakeV2Pair(pairAddress);
        tokenA.mint(address(this), amountA);
        tokenB.mint(address(this), amountB);

        uint256 amount0 = pair.token0() == address(tokenA) ? amountA : amountB;
        uint256 amount1 = pair.token1() == address(tokenB) ? amountB : amountA;

        MockERC20(pair.token0()).approve(pairAddress, amount0);
        MockERC20(pair.token1()).approve(pairAddress, amount1);
        pair.seed(amount0, amount1);
    }

    function _path(address tokenA, address tokenB) private pure returns (address[] memory path) {
        path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;
    }

    function _path(address tokenA, address tokenB, address tokenC) private pure returns (address[] memory path) {
        path = new address[](3);
        path[0] = tokenA;
        path[1] = tokenB;
        path[2] = tokenC;
    }
}
