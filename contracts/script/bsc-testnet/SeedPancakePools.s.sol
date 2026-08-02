// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Script} from "forge-std/Script.sol";
import {IPancakeV2Router} from "../../src/interfaces/IPancakeV2Router.sol";
import {BscTestnetConfig} from "./BscTestnetConfig.sol";

interface IPancakeV2LiquidityRouter is IPancakeV2Router {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);
}

interface IWBNB is IERC20 {
    function deposit() external payable;
}

contract SeedPancakePools is Script {
    using SafeERC20 for IERC20;

    error UnsupportedChain(uint256 actualChainId);
    error ZeroAddress();

    function run() external {
        if (block.chainid != BscTestnetConfig.CHAIN_ID) revert UnsupportedChain(block.chainid);

        address usdc = vm.envAddress("MOCK_USDC");
        address wbtc = vm.envAddress("MOCK_WBTC");
        if (usdc == address(0) || wbtc == address(0)) revert ZeroAddress();

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address liquidityOwner = vm.addr(deployerPrivateKey);
        IPancakeV2LiquidityRouter router = IPancakeV2LiquidityRouter(BscTestnetConfig.PANCAKE_V2_ROUTER);
        uint256 deadline = block.timestamp + 30 minutes;

        uint256 usdcWbnbUsdc = vm.envOr("USDC_WBNB_USDC_AMOUNT", uint256(20_000e6));
        uint256 usdcWbnbWbnb = vm.envOr("USDC_WBNB_WBNB_AMOUNT", uint256(10e18));
        uint256 wbnbWbtcWbnb = vm.envOr("WBNB_WBTC_WBNB_AMOUNT", uint256(10e18));
        uint256 wbnbWbtcWbtc = vm.envOr("WBNB_WBTC_WBTC_AMOUNT", uint256(5e7));
        uint256 wbtcUsdcWbtc = vm.envOr("WBTC_USDC_WBTC_AMOUNT", uint256(5e7));
        uint256 wbtcUsdcUsdc = vm.envOr("WBTC_USDC_USDC_AMOUNT", uint256(22_000e6));
        uint256 requiredWbnb = usdcWbnbWbnb + wbnbWbtcWbnb;

        vm.startBroadcast(deployerPrivateKey);
        _wrapMissingWbnb(liquidityOwner, requiredWbnb);
        _approveAndAddLiquidity(
            router, usdc, BscTestnetConfig.WBNB, usdcWbnbUsdc, usdcWbnbWbnb, liquidityOwner, deadline
        );
        _approveAndAddLiquidity(
            router, BscTestnetConfig.WBNB, wbtc, wbnbWbtcWbnb, wbnbWbtcWbtc, liquidityOwner, deadline
        );
        _approveAndAddLiquidity(router, wbtc, usdc, wbtcUsdcWbtc, wbtcUsdcUsdc, liquidityOwner, deadline);
        vm.stopBroadcast();
    }

    function _wrapMissingWbnb(address liquidityOwner, uint256 requiredWbnb) private {
        uint256 currentWbnb = IERC20(BscTestnetConfig.WBNB).balanceOf(liquidityOwner);
        if (currentWbnb < requiredWbnb) {
            IWBNB(BscTestnetConfig.WBNB).deposit{value: requiredWbnb - currentWbnb}();
        }
    }

    function _approveAndAddLiquidity(
        IPancakeV2LiquidityRouter router,
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        address liquidityOwner,
        uint256 deadline
    ) private {
        IERC20(tokenA).forceApprove(address(router), amountA);
        IERC20(tokenB).forceApprove(address(router), amountB);
        router.addLiquidity(tokenA, tokenB, amountA, amountB, 0, 0, liquidityOwner, deadline);
        IERC20(tokenA).forceApprove(address(router), 0);
        IERC20(tokenB).forceApprove(address(router), 0);
    }
}
