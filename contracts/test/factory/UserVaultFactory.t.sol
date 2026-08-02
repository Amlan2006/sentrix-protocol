// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {SentrixTypes} from "../../src/libraries/SentrixTypes.sol";
import {IUserVault} from "../../src/interfaces/IUserVault.sol";
import {IUserVaultFactory} from "../../src/interfaces/IUserVaultFactory.sol";
import {UserVaultFactory} from "../../src/factory/UserVaultFactory.sol";
import {MockERC20} from "../mocks/MockERC20.sol";

contract UserVaultFactoryTest is Test {
    address private owner = address(0xA11CE);
    address private otherOwner = address(0xB0B);

    MockERC20 private token;
    MockERC20 private secondToken;
    UserVaultFactory private factory;

    function setUp() public {
        token = new MockERC20("USD Coin", "USDC", 6);
        secondToken = new MockERC20("Wrapped Ether", "WETH", 18);
        factory = new UserVaultFactory();
    }

    function test_createVaultRegistersOwnerVault() public {
        vm.prank(owner);
        address vault = factory.createVault(address(token), _riskConfig());

        assertTrue(factory.isVault(vault));
        assertTrue(factory.vaultImplementation() != address(0));
        assertTrue(vault != factory.vaultImplementation());
        assertEq(factory.vaultCount(owner), 1);
        assertEq(factory.getVault(owner, address(token)), vault);

        address[] memory vaults = factory.getVaults(owner);
        assertEq(vaults.length, 1);
        assertEq(vaults[0], vault);

        assertEq(IUserVault(vault).owner(), owner);
        assertEq(IUserVault(vault).settlementToken(), address(token));
        assertFalse(IUserVault(vault).flashLoanArbitrageEnabled());
    }

    function test_createVaultRejectsZeroSettlementToken() public {
        vm.prank(owner);
        vm.expectRevert(UserVaultFactory.ZeroAddress.selector);
        factory.createVault(address(0), _riskConfig());
    }

    function test_createVaultAllowsMultipleIsolatedVaultsForSameOwner() public {
        vm.startPrank(owner);
        address firstVault = factory.createVault(address(token), _riskConfig());
        address secondVault = factory.createVault(address(secondToken), _riskConfig());
        vm.stopPrank();

        assertTrue(firstVault != secondVault);
        assertEq(factory.vaultCount(owner), 2);
        assertEq(factory.getVault(owner, address(token)), firstVault);
        assertEq(factory.getVault(owner, address(secondToken)), secondVault);

        address[] memory vaults = factory.getVaults(owner);
        assertEq(vaults[0], firstVault);
        assertEq(vaults[1], secondVault);
    }

    function test_createVaultRejectsDuplicateOwnerSettlementToken() public {
        vm.startPrank(owner);
        address vault = factory.createVault(address(token), _riskConfig());

        vm.expectRevert(
            abi.encodeWithSelector(IUserVaultFactory.VaultAlreadyExists.selector, owner, address(token), vault)
        );
        factory.createVault(address(token), _riskConfig());
        vm.stopPrank();
    }

    function test_createVaultAllowsDifferentOwnersForSameSettlementToken() public {
        vm.prank(owner);
        address ownerVault = factory.createVault(address(token), _riskConfig());

        vm.prank(otherOwner);
        address otherVault = factory.createVault(address(token), _riskConfig());

        assertTrue(ownerVault != otherVault);
        assertEq(factory.getVault(owner, address(token)), ownerVault);
        assertEq(factory.getVault(otherOwner, address(token)), otherVault);
    }

    function _riskConfig() private pure returns (SentrixTypes.UserRiskConfig memory config) {
        config.minNetProfit = 1e6;
        config.maxTradeSize = 10_000e6;
        config.maxGasReimbursement = 25e6;
        config.maxSlippageBps = 100;
        config.reinvestmentBps = 2_500;
        config.arbitrageEnabled = true;
        config.flashLoanArbitrageEnabled = true;
        config.gridEnabled = false;
    }
}
