// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Script} from "forge-std/Script.sol";
import {ArbitrageExecutor} from "../../src/arbitrage/ArbitrageExecutor.sol";
import {ControlledTestToken} from "../../src/testnet/ControlledTestToken.sol";
import {IUserVault} from "../../src/interfaces/IUserVault.sol";
import {IUserVaultFactory} from "../../src/interfaces/IUserVaultFactory.sol";
import {SentrixTypes} from "../../src/libraries/SentrixTypes.sol";
import {BscTestnetConfig} from "./BscTestnetConfig.sol";

contract SmokeTestUserFundedArbitrage is Script {
    using SafeERC20 for IERC20;

    struct CoreAddresses {
        address userVaultFactory;
        address routeValidator;
        address pancakeAdapter;
        address arbitrageExecutor;
        address mockUsdc;
        address mockWbtc;
    }

    struct SmokeConfig {
        uint256 depositAmount;
        uint256 borrowAmount;
        uint256 minGrossProfit;
        uint256 deadline;
    }

    error UnsupportedChain(uint256 actualChainId);
    error ZeroAddress();
    error InsufficientTokenBalance(address token, uint256 requiredAmount, uint256 actualAmount);
    error MissingVault();
    error AccountingDidNotIncrease(uint256 beforeProfit, uint256 afterProfit);

    function run() external returns (address vault, uint256 grossProfit) {
        if (block.chainid != BscTestnetConfig.CHAIN_ID) {
            revert UnsupportedChain(block.chainid);
        }

        CoreAddresses memory core = _coreAddresses();
        SmokeConfig memory config = _smokeConfig();

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);
        vault = _getOrCreateVault(core.userVaultFactory, deployer, core.mockUsdc);
        _authorizeExecutorIfNeeded(vault, core.arbitrageExecutor);
        _ensureDeposit(vault, core.mockUsdc, deployer, config.depositAmount, config.borrowAmount);

        uint256 beforeGrossProfit = IUserVault(vault).accounting().grossArbitrageProfit;
        SentrixTypes.ArbitrageRequest memory request = _triangularRequest(vault, core, config);
        grossProfit = ArbitrageExecutor(core.arbitrageExecutor).executeArbitrage(request);
        uint256 afterGrossProfit = IUserVault(vault).accounting().grossArbitrageProfit;

        if (afterGrossProfit <= beforeGrossProfit) {
            revert AccountingDidNotIncrease(beforeGrossProfit, afterGrossProfit);
        }
        vm.stopBroadcast();

        core.routeValidator;
    }

    function _coreAddresses() private view returns (CoreAddresses memory core) {
        core = CoreAddresses({
            userVaultFactory: vm.envAddress("USER_VAULT_FACTORY"),
            routeValidator: vm.envAddress("ROUTE_VALIDATOR"),
            pancakeAdapter: vm.envAddress("PANCAKE_V2_ADAPTER"),
            arbitrageExecutor: vm.envAddress("ARBITRAGE_EXECUTOR"),
            mockUsdc: vm.envAddress("MOCK_USDC"),
            mockWbtc: vm.envAddress("MOCK_WBTC")
        });

        if (
            core.userVaultFactory == address(0) || core.routeValidator == address(0)
                || core.pancakeAdapter == address(0) || core.arbitrageExecutor == address(0)
                || core.mockUsdc == address(0) || core.mockWbtc == address(0)
        ) {
            revert ZeroAddress();
        }
    }

    function _smokeConfig() private view returns (SmokeConfig memory config) {
        config = SmokeConfig({
            depositAmount: vm.envOr("SMOKE_DEPOSIT_AMOUNT", uint256(1_000e6)),
            borrowAmount: vm.envOr("SMOKE_BORROW_AMOUNT", uint256(100e6)),
            minGrossProfit: vm.envOr("SMOKE_MIN_GROSS_PROFIT", uint256(1)),
            deadline: block.timestamp + vm.envOr("SMOKE_DEADLINE_SECONDS", uint256(30 minutes))
        });
    }

    function _getOrCreateVault(address userVaultFactory, address deployer, address mockUsdc)
        private
        returns (address vault)
    {
        IUserVaultFactory factory = IUserVaultFactory(userVaultFactory);
        vault = factory.getVault(deployer, mockUsdc);
        if (vault != address(0)) return vault;

        vault = factory.createVault(mockUsdc, _riskConfig());
        if (vault == address(0)) revert MissingVault();
    }

    function _authorizeExecutorIfNeeded(address vault, address arbitrageExecutor) private {
        if (!IUserVault(vault).isStrategyAuthorized(arbitrageExecutor)) {
            IUserVault(vault).authorizeStrategy(arbitrageExecutor);
        }
    }

    function _ensureDeposit(
        address vault,
        address mockUsdc,
        address deployer,
        uint256 depositAmount,
        uint256 borrowAmount
    ) private {
        SentrixTypes.VaultAccounting memory accounting = IUserVault(vault).accounting();
        if (accounting.idleSettlementBalance >= borrowAmount) return;

        uint256 deployerBalance = IERC20(mockUsdc).balanceOf(deployer);
        if (deployerBalance < depositAmount) {
            try ControlledTestToken(mockUsdc).mint(deployer, depositAmount - deployerBalance) {} catch {}
        }

        deployerBalance = IERC20(mockUsdc).balanceOf(deployer);
        if (deployerBalance < depositAmount) {
            revert InsufficientTokenBalance(mockUsdc, depositAmount, deployerBalance);
        }

        IERC20(mockUsdc).forceApprove(vault, depositAmount);
        IUserVault(vault).deposit(depositAmount);
        IERC20(mockUsdc).forceApprove(vault, 0);
    }

    function _triangularRequest(address vault, CoreAddresses memory core, SmokeConfig memory config)
        private
        pure
        returns (SentrixTypes.ArbitrageRequest memory request)
    {
        SentrixTypes.SwapStep[] memory swaps = new SentrixTypes.SwapStep[](3);
        swaps[0] = SentrixTypes.SwapStep({
            adapter: core.pancakeAdapter,
            tokenIn: core.mockUsdc,
            tokenOut: BscTestnetConfig.WBNB,
            minAmountOut: 1,
            routeData: _routeData(core.mockUsdc, BscTestnetConfig.WBNB, config.deadline)
        });
        swaps[1] = SentrixTypes.SwapStep({
            adapter: core.pancakeAdapter,
            tokenIn: BscTestnetConfig.WBNB,
            tokenOut: core.mockWbtc,
            minAmountOut: 1,
            routeData: _routeData(BscTestnetConfig.WBNB, core.mockWbtc, config.deadline)
        });
        swaps[2] = SentrixTypes.SwapStep({
            adapter: core.pancakeAdapter,
            tokenIn: core.mockWbtc,
            tokenOut: core.mockUsdc,
            minAmountOut: 1,
            routeData: _routeData(core.mockWbtc, core.mockUsdc, config.deadline)
        });

        request = SentrixTypes.ArbitrageRequest({
            vault: vault,
            settlementToken: core.mockUsdc,
            borrowAmount: config.borrowAmount,
            minGrossProfit: config.minGrossProfit,
            maxGasReimbursement: 0,
            deadline: config.deadline,
            arbitrageType: SentrixTypes.ArbitrageType.TRIANGULAR,
            swaps: swaps
        });
    }

    function _routeData(address tokenIn, address tokenOut, uint256 deadline) private pure returns (bytes memory) {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        return abi.encode(path, deadline);
    }

    function _riskConfig() private pure returns (SentrixTypes.UserRiskConfig memory) {
        return SentrixTypes.UserRiskConfig({
            minNetProfit: 1,
            maxTradeSize: 1_000e6,
            maxGasReimbursement: 0,
            maxSlippageBps: 500,
            reinvestmentBps: 0,
            arbitrageEnabled: true,
            flashLoanArbitrageEnabled: false,
            gridEnabled: false
        });
    }
}
