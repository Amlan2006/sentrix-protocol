// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {SentrixTypes} from "../../src/libraries/SentrixTypes.sol";
import {UserVault} from "../../src/vault/UserVault.sol";
import {FalseReturnERC20} from "../mocks/FalseReturnERC20.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {NoReturnERC20} from "../mocks/NoReturnERC20.sol";
import {ReentrantToken} from "../mocks/ReentrantToken.sol";

contract UserVaultTest is Test {
    event Initialized(address indexed owner, address indexed settlementToken);
    event Deposited(address indexed vault, address indexed owner, uint256 amount);
    event Withdrawn(address indexed vault, address indexed owner, address indexed recipient, uint256 amount);
    event RiskConfigUpdated(address indexed vault, SentrixTypes.UserRiskConfig config);
    event ReinvestmentConfigUpdated(address indexed vault, uint16 reinvestmentBps);
    event FlashLoanArbitrageSettingUpdated(address indexed vault, bool enabled);
    event StrategyAuthorized(address indexed vault, address indexed strategy);
    event StrategyRevoked(address indexed vault, address indexed strategy);
    event EmergencyPaused(address indexed vault);
    event EmergencyUnpaused(address indexed vault);
    event EmergencyWithdrawal(address indexed vault, address indexed owner, address indexed recipient, uint256 amount);

    address private owner = address(0xA11CE);
    address private other = address(0xB0B);
    address private recipient = address(0xCAFE);
    address private strategy = address(0x5157);

    MockERC20 private token;
    UserVault private vault;

    function setUp() public {
        token = new MockERC20("USD Coin", "USDC", 6);
        vault = new UserVault();
        vault.initialize(owner, address(token), _riskConfig(false));
        token.mint(owner, 1_000_000e6);
    }

    function test_initializeSetsOwnerTokenAndFlashLoanDefault() public view {
        assertEq(vault.owner(), owner);
        assertEq(vault.settlementToken(), address(token));
        assertTrue(vault.initialized());
        assertFalse(vault.flashLoanArbitrageEnabled());

        SentrixTypes.UserRiskConfig memory config = vault.riskConfig();
        assertFalse(config.flashLoanArbitrageEnabled);
    }

    function test_initializeEmitsCriticalEvents() public {
        UserVault freshVault = new UserVault();
        SentrixTypes.UserRiskConfig memory config = _riskConfig(false);

        vm.expectEmit(true, true, false, true, address(freshVault));
        emit Initialized(owner, address(token));
        vm.expectEmit(true, false, false, true, address(freshVault));
        emit RiskConfigUpdated(address(freshVault), config);
        vm.expectEmit(true, false, false, true, address(freshVault));
        emit FlashLoanArbitrageSettingUpdated(address(freshVault), false);

        freshVault.initialize(owner, address(token), config);
    }

    function test_initializeRevertsTwice() public {
        vm.expectRevert(UserVault.AlreadyInitialized.selector);
        vault.initialize(owner, address(token), _riskConfig(false));
    }

    function test_initializeRejectsZeroOwner() public {
        UserVault freshVault = new UserVault();
        vm.expectRevert(UserVault.ZeroAddress.selector);
        freshVault.initialize(address(0), address(token), _riskConfig(false));
    }

    function test_initializeRejectsZeroSettlementToken() public {
        UserVault freshVault = new UserVault();
        vm.expectRevert(UserVault.ZeroAddress.selector);
        freshVault.initialize(owner, address(0), _riskConfig(false));
    }

    function test_uninitializedVaultRejectsStateChangingCalls() public {
        UserVault freshVault = new UserVault();

        vm.expectRevert(UserVault.NotInitialized.selector);
        freshVault.deposit(1);

        vm.expectRevert(UserVault.NotInitialized.selector);
        freshVault.withdraw(1, recipient);

        vm.expectRevert(UserVault.NotInitialized.selector);
        freshVault.pauseEmergency();
    }

    function test_initializeRejectsInvalidMaxSlippageBps() public {
        UserVault freshVault = new UserVault();
        SentrixTypes.UserRiskConfig memory config = _riskConfig(false);
        config.maxSlippageBps = 10_001;

        vm.expectRevert(UserVault.InvalidBasisPoints.selector);
        freshVault.initialize(owner, address(token), config);
    }

    function test_initializeRejectsInvalidReinvestmentBps() public {
        UserVault freshVault = new UserVault();
        SentrixTypes.UserRiskConfig memory config = _riskConfig(false);
        config.reinvestmentBps = 10_001;

        vm.expectRevert(UserVault.InvalidBasisPoints.selector);
        freshVault.initialize(owner, address(token), config);
    }

    function test_depositUpdatesAccounting() public {
        _deposit(owner, 500e6);

        SentrixTypes.VaultAccounting memory accounting = vault.accounting();
        assertEq(accounting.principalDeposited, 500e6);
        assertEq(accounting.idleSettlementBalance, 500e6);
        assertEq(token.balanceOf(address(vault)), 500e6);
    }

    function test_depositRejectsZeroAmount() public {
        vm.prank(owner);
        vm.expectRevert(UserVault.InvalidAmount.selector);
        vault.deposit(0);
    }

    function test_depositRejectsWhilePaused() public {
        vm.prank(owner);
        vault.pauseEmergency();

        vm.prank(owner);
        vm.expectRevert(UserVault.PausedOperation.selector);
        vault.deposit(1);
    }

    function test_depositEmitsEvent() public {
        uint256 amount = 500e6;

        vm.startPrank(owner);
        token.approve(address(vault), amount);

        vm.expectEmit(true, true, false, true, address(vault));
        emit Deposited(address(vault), owner, amount);
        vault.deposit(amount);
        vm.stopPrank();
    }

    function test_withdrawUpdatesAccountingAndTransfersToRecipient() public {
        _deposit(owner, 500e6);

        vm.prank(owner);
        vault.withdraw(200e6, recipient);

        SentrixTypes.VaultAccounting memory accounting = vault.accounting();
        assertEq(accounting.principalDeposited, 500e6);
        assertEq(accounting.principalWithdrawn, 200e6);
        assertEq(accounting.idleSettlementBalance, 300e6);
        assertEq(token.balanceOf(recipient), 200e6);
        assertEq(token.balanceOf(address(vault)), 300e6);
    }

    function test_withdrawEmitsEvent() public {
        _deposit(owner, 500e6);

        vm.prank(owner);
        vm.expectEmit(true, true, true, true, address(vault));
        emit Withdrawn(address(vault), owner, recipient, 200e6);
        vault.withdraw(200e6, recipient);
    }

    function testFuzz_depositAndWithdrawAccounting(uint256 depositAmount, uint256 withdrawAmount) public {
        depositAmount = bound(depositAmount, 1, 1_000_000e6);
        withdrawAmount = bound(withdrawAmount, 1, depositAmount);

        _deposit(owner, depositAmount);

        vm.prank(owner);
        vault.withdraw(withdrawAmount, recipient);

        SentrixTypes.VaultAccounting memory accounting = vault.accounting();
        assertEq(accounting.principalDeposited, depositAmount);
        assertEq(accounting.principalWithdrawn, withdrawAmount);
        assertEq(accounting.idleSettlementBalance, depositAmount - withdrawAmount);
        assertEq(token.balanceOf(address(vault)), accounting.idleSettlementBalance);
        assertEq(token.balanceOf(recipient), withdrawAmount);
        assertLe(accounting.idleSettlementBalance, token.balanceOf(address(vault)));
    }

    function test_nonOwnerCannotWithdraw() public {
        _deposit(owner, 500e6);

        vm.prank(other);
        vm.expectRevert(UserVault.Unauthorized.selector);
        vault.withdraw(100e6, recipient);
    }

    function test_withdrawRejectsZeroAmount() public {
        _deposit(owner, 500e6);

        vm.prank(owner);
        vm.expectRevert(UserVault.InvalidAmount.selector);
        vault.withdraw(0, recipient);
    }

    function test_withdrawRejectsZeroRecipient() public {
        _deposit(owner, 500e6);

        vm.prank(owner);
        vm.expectRevert(UserVault.InvalidRecipient.selector);
        vault.withdraw(100e6, address(0));
    }

    function test_cannotWithdrawMoreThanIdleBalance() public {
        _deposit(owner, 500e6);

        vm.prank(owner);
        vm.expectRevert(UserVault.InsufficientIdleBalance.selector);
        vault.withdraw(501e6, recipient);
    }

    function test_onlyOwnerCanToggleFlashLoanArbitrage() public {
        vm.prank(other);
        vm.expectRevert(UserVault.Unauthorized.selector);
        vault.setFlashLoanArbitrageEnabled(true);

        vm.prank(owner);
        vault.setFlashLoanArbitrageEnabled(true);

        assertTrue(vault.flashLoanArbitrageEnabled());
        SentrixTypes.UserRiskConfig memory config = vault.riskConfig();
        assertTrue(config.flashLoanArbitrageEnabled);
    }

    function test_setRiskConfigEmitsEvents() public {
        SentrixTypes.UserRiskConfig memory config = _riskConfig(true);

        vm.prank(owner);
        vm.expectEmit(true, false, false, true, address(vault));
        emit RiskConfigUpdated(address(vault), config);
        vm.expectEmit(true, false, false, true, address(vault));
        emit FlashLoanArbitrageSettingUpdated(address(vault), true);
        vault.setRiskConfig(config);
    }

    function test_setReinvestmentBpsEmitsEvents() public {
        SentrixTypes.UserRiskConfig memory config = _riskConfig(false);
        config.reinvestmentBps = 4_000;

        vm.prank(owner);
        vm.expectEmit(true, false, false, true, address(vault));
        emit ReinvestmentConfigUpdated(address(vault), 4_000);
        vm.expectEmit(true, false, false, true, address(vault));
        emit RiskConfigUpdated(address(vault), config);
        vault.setReinvestmentBps(4_000);
    }

    function test_setFlashLoanArbitrageEnabledEmitsEvents() public {
        SentrixTypes.UserRiskConfig memory config = _riskConfig(true);

        vm.prank(owner);
        vm.expectEmit(true, false, false, true, address(vault));
        emit FlashLoanArbitrageSettingUpdated(address(vault), true);
        vm.expectEmit(true, false, false, true, address(vault));
        emit RiskConfigUpdated(address(vault), config);
        vault.setFlashLoanArbitrageEnabled(true);
    }

    function test_setRiskConfigCanEnableFlashLoanButOnlyOwner() public {
        vm.prank(other);
        vm.expectRevert(UserVault.Unauthorized.selector);
        vault.setRiskConfig(_riskConfig(true));

        vm.prank(owner);
        vault.setRiskConfig(_riskConfig(true));

        assertTrue(vault.flashLoanArbitrageEnabled());
    }

    function test_setRiskConfigRejectsInvalidBasisPoints() public {
        SentrixTypes.UserRiskConfig memory config = _riskConfig(false);
        config.maxSlippageBps = 10_001;

        vm.prank(owner);
        vm.expectRevert(UserVault.InvalidBasisPoints.selector);
        vault.setRiskConfig(config);
    }

    function test_setReinvestmentBpsRejectsInvalidBasisPoints() public {
        vm.prank(owner);
        vm.expectRevert(UserVault.InvalidBasisPoints.selector);
        vault.setReinvestmentBps(10_001);
    }

    function test_onlyOwnerCanAuthorizeAndRevokeStrategy() public {
        vm.prank(other);
        vm.expectRevert(UserVault.Unauthorized.selector);
        vault.authorizeStrategy(strategy);

        vm.prank(owner);
        vault.authorizeStrategy(strategy);
        assertTrue(vault.isStrategyAuthorized(strategy));

        vm.prank(other);
        vm.expectRevert(UserVault.Unauthorized.selector);
        vault.revokeStrategy(strategy);

        vm.prank(owner);
        vault.revokeStrategy(strategy);
        assertFalse(vault.isStrategyAuthorized(strategy));
    }

    function test_authorizeStrategyRejectsDuplicateStrategy() public {
        vm.startPrank(owner);
        vault.authorizeStrategy(strategy);

        vm.expectRevert(UserVault.StrategyAlreadyAuthorized.selector);
        vault.authorizeStrategy(strategy);
        vm.stopPrank();
    }

    function test_revokeStrategyRejectsUnauthorizedStrategy() public {
        vm.prank(owner);
        vm.expectRevert(UserVault.StrategyNotAuthorized.selector);
        vault.revokeStrategy(strategy);
    }

    function test_authorizeStrategyRejectsZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(UserVault.ZeroAddress.selector);
        vault.authorizeStrategy(address(0));
    }

    function test_revokeStrategyRejectsZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(UserVault.ZeroAddress.selector);
        vault.revokeStrategy(address(0));
    }

    function test_nonOwnerCannotPauseOrUnpause() public {
        vm.prank(other);
        vm.expectRevert(UserVault.Unauthorized.selector);
        vault.pauseEmergency();

        vm.prank(owner);
        vault.pauseEmergency();

        vm.prank(other);
        vm.expectRevert(UserVault.Unauthorized.selector);
        vault.unpauseEmergency();
    }

    function test_strategyAuthorizationEmitsEvents() public {
        vm.prank(owner);
        vm.expectEmit(true, true, false, true, address(vault));
        emit StrategyAuthorized(address(vault), strategy);
        vault.authorizeStrategy(strategy);

        vm.prank(owner);
        vm.expectEmit(true, true, false, true, address(vault));
        emit StrategyRevoked(address(vault), strategy);
        vault.revokeStrategy(strategy);
    }

    function test_pausedVaultBlocksAutomationButAllowsOwnerWithdrawals() public {
        _deposit(owner, 500e6);

        vm.prank(owner);
        vault.pauseEmergency();

        assertTrue(vault.emergencyPaused());

        vm.prank(owner);
        vm.expectRevert(UserVault.PausedOperation.selector);
        vault.authorizeStrategy(strategy);

        vm.prank(owner);
        vault.withdraw(100e6, recipient);

        assertEq(token.balanceOf(recipient), 100e6);
    }

    function test_emergencyPauseAndUnpauseEmitEvents() public {
        vm.prank(owner);
        vm.expectEmit(true, false, false, true, address(vault));
        emit EmergencyPaused(address(vault));
        vault.pauseEmergency();

        vm.prank(owner);
        vm.expectEmit(true, false, false, true, address(vault));
        emit EmergencyUnpaused(address(vault));
        vault.unpauseEmergency();
    }

    function test_emergencyWithdrawIdleWithdrawsAllIdleSettlement() public {
        _deposit(owner, 500e6);

        vm.prank(owner);
        uint256 amount = vault.emergencyWithdrawIdle(recipient);

        SentrixTypes.VaultAccounting memory accounting = vault.accounting();
        assertEq(amount, 500e6);
        assertEq(accounting.idleSettlementBalance, 0);
        assertEq(accounting.principalWithdrawn, 500e6);
        assertEq(token.balanceOf(recipient), 500e6);
    }

    function test_emergencyWithdrawIdleEmitsEvent() public {
        _deposit(owner, 500e6);

        vm.prank(owner);
        vm.expectEmit(true, true, true, true, address(vault));
        emit EmergencyWithdrawal(address(vault), owner, recipient, 500e6);
        vault.emergencyWithdrawIdle(recipient);
    }

    function test_noReturnTokenDepositAndWithdrawSucceeds() public {
        NoReturnERC20 noReturnToken = new NoReturnERC20();
        UserVault noReturnVault = new UserVault();
        noReturnVault.initialize(owner, address(noReturnToken), _riskConfig(false));
        noReturnToken.mint(owner, 500e6);

        vm.startPrank(owner);
        noReturnToken.approve(address(noReturnVault), 500e6);
        noReturnVault.deposit(500e6);
        noReturnVault.withdraw(200e6, recipient);
        vm.stopPrank();

        SentrixTypes.VaultAccounting memory accounting = noReturnVault.accounting();
        assertEq(accounting.idleSettlementBalance, 300e6);
        assertEq(noReturnToken.balanceOf(address(noReturnVault)), 300e6);
        assertEq(noReturnToken.balanceOf(recipient), 200e6);
    }

    function test_falseReturnTokenDepositReverts() public {
        FalseReturnERC20 falseReturnToken = new FalseReturnERC20();
        UserVault falseReturnVault = new UserVault();
        falseReturnVault.initialize(owner, address(falseReturnToken), _riskConfig(false));
        falseReturnToken.mint(owner, 500e6);

        vm.startPrank(owner);
        falseReturnToken.approve(address(falseReturnVault), 500e6);
        vm.expectRevert();
        falseReturnVault.deposit(500e6);
        vm.stopPrank();
    }

    function test_reentrantDepositAttemptIsBlocked() public {
        ReentrantToken reentrantToken = new ReentrantToken();
        UserVault reentrantVault = new UserVault();
        reentrantVault.initialize(owner, address(reentrantToken), _riskConfig(false));
        reentrantToken.mint(owner, 500e6);
        reentrantToken.setAttack(reentrantVault, true);

        vm.startPrank(owner);
        reentrantToken.approve(address(reentrantVault), 500e6);
        reentrantVault.deposit(500e6);
        vm.stopPrank();

        SentrixTypes.VaultAccounting memory accounting = reentrantVault.accounting();
        assertTrue(reentrantToken.reentryBlocked());
        assertEq(accounting.principalDeposited, 500e6);
        assertEq(accounting.idleSettlementBalance, 500e6);
        assertEq(reentrantToken.balanceOf(address(reentrantVault)), 500e6);
    }

    function test_idleBalanceNeverExceedsActualTokenBalance() public {
        _deposit(owner, 500e6);
        vm.prank(owner);
        vault.withdraw(125e6, recipient);

        SentrixTypes.VaultAccounting memory accounting = vault.accounting();
        assertLe(accounting.idleSettlementBalance, token.balanceOf(address(vault)));
    }

    function _deposit(address from, uint256 amount) private {
        vm.startPrank(from);
        token.approve(address(vault), amount);
        vault.deposit(amount);
        vm.stopPrank();
    }

    function _riskConfig(bool flashLoanEnabled) private pure returns (SentrixTypes.UserRiskConfig memory config) {
        config.minNetProfit = 1e6;
        config.maxTradeSize = 10_000e6;
        config.maxGasReimbursement = 25e6;
        config.maxSlippageBps = 100;
        config.reinvestmentBps = 2_500;
        config.arbitrageEnabled = true;
        config.flashLoanArbitrageEnabled = flashLoanEnabled;
        config.gridEnabled = false;
    }
}
