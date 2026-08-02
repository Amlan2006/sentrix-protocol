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
        _validateNewVault(msg.sender, settlementToken);
        vault = vaultImplementation.clone();
        _registerVault(msg.sender, settlementToken, riskConfig, vault);
    }

    function createVaultDeterministic(
        address settlementToken,
        SentrixTypes.UserRiskConfig calldata riskConfig,
        bytes32 salt
    ) external override returns (address vault) {
        _validateNewVault(msg.sender, settlementToken);
        vault = vaultImplementation.cloneDeterministic(_vaultSalt(msg.sender, settlementToken, salt));
        _registerVault(msg.sender, settlementToken, riskConfig, vault);
    }

    function predictVaultAddress(address owner, address settlementToken, bytes32 salt)
        external
        view
        override
        returns (address vault)
    {
        if (owner == address(0) || settlementToken == address(0)) revert ZeroAddress();
        return vaultImplementation.predictDeterministicAddress(_vaultSalt(owner, settlementToken, salt), address(this));
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

    function _registerVault(
        address owner,
        address settlementToken,
        SentrixTypes.UserRiskConfig calldata riskConfig,
        address vault
    ) private {
        _ownerVaults[owner].push(vault);
        _ownerSettlementVault[owner][settlementToken] = vault;
        isVault[vault] = true;

        UserVault(vault).initialize(owner, settlementToken, riskConfig);

        emit VaultCreated(owner, vault, settlementToken, _ownerVaults[owner].length - 1);
    }

    function _validateNewVault(address owner, address settlementToken) private view {
        if (settlementToken == address(0)) revert ZeroAddress();
        address existingVault = _ownerSettlementVault[owner][settlementToken];
        if (existingVault != address(0)) {
            revert VaultAlreadyExists(owner, settlementToken, existingVault);
        }
    }

    function _vaultSalt(address owner, address settlementToken, bytes32 salt) private pure returns (bytes32) {
        return keccak256(abi.encode(owner, settlementToken, salt));
    }
}
