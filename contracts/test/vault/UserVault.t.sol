// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {SentrixTypes} from "../../src/libraries/SentrixTypes.sol";
import {UserVault} from "../../src/vault/UserVault.sol";
import {MockERC20} from "../mocks/MockERC20.sol";

contract UserVaultTest is Test {
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

    function test_depositUpdatesAccounting() public {
        _deposit(owner, 500e6);

        SentrixTypes.VaultAccounting memory accounting = vault.accounting();
        assertEq(accounting.principalDeposited, 500e6);
        assertEq(accounting.idleSettlementBalance, 500e6);
        assertEq(token.balanceOf(address(vault)), 500e6);
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

    function test_nonOwnerCannotWithdraw() public {
        _deposit(owner, 500e6);

        vm.prank(other);
        vm.expectRevert(UserVault.Unauthorized.selector);
        vault.withdraw(100e6, recipient);
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

    function test_setRiskConfigCanEnableFlashLoanButOnlyOwner() public {
        vm.prank(other);
        vm.expectRevert(UserVault.Unauthorized.selector);
        vault.setRiskConfig(_riskConfig(true));

        vm.prank(owner);
        vault.setRiskConfig(_riskConfig(true));

        assertTrue(vault.flashLoanArbitrageEnabled());
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
