// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {IUserVaultFactory} from "../interfaces/IUserVaultFactory.sol";
import {SentrixTypes} from "../libraries/SentrixTypes.sol";
import {UserVault} from "../vault/UserVault.sol";

contract UserVaultFactory is IUserVaultFactory {
    using Clones for address;

    error ZeroAddress();

    address public immutable vaultImplementation;

    mapping(address owner => address[] vaults) private _ownerVaults;
    mapping(address owner => mapping(address settlementToken => address vault)) private _ownerSettlementVault;
    mapping(address vault => bool valid) public override isVault;

    constructor() {
        vaultImplementation = address(new UserVault());
    }

    function createVault(address settlementToken, SentrixTypes.UserRiskConfig calldata riskConfig)
        external
        override
        returns (address vault)
    {
        if (settlementToken == address(0)) revert ZeroAddress();
        address existingVault = _ownerSettlementVault[msg.sender][settlementToken];
        if (existingVault != address(0)) {
            revert VaultAlreadyExists(msg.sender, settlementToken, existingVault);
        }

        vault = vaultImplementation.clone();
        UserVault(vault).initialize(msg.sender, settlementToken, riskConfig);

        _ownerVaults[msg.sender].push(vault);
        _ownerSettlementVault[msg.sender][settlementToken] = vault;
        isVault[vault] = true;

        emit VaultCreated(msg.sender, vault, settlementToken, _ownerVaults[msg.sender].length - 1);
    }

    function getVaults(address owner) external view override returns (address[] memory) {
        return _ownerVaults[owner];
    }

    function getVault(address owner, address settlementToken) external view override returns (address) {
        return _ownerSettlementVault[owner][settlementToken];
    }

    function vaultCount(address owner) external view override returns (uint256) {
        return _ownerVaults[owner].length;
    }
}
