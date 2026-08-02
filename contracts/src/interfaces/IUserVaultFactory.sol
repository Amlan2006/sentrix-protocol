// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SentrixTypes} from "../libraries/SentrixTypes.sol";

interface IUserVaultFactory {
    event VaultCreated(address indexed owner, address indexed vault, address indexed settlementToken, uint256 index);

    error VaultAlreadyExists(address owner, address settlementToken, address vault);

    function createVault(address settlementToken, SentrixTypes.UserRiskConfig calldata riskConfig)
        external
        returns (address vault);

    function getVaults(address owner) external view returns (address[] memory);
    function getVault(address owner, address settlementToken) external view returns (address);
    function isVault(address vault) external view returns (bool);
    function vaultCount(address owner) external view returns (uint256);
}
