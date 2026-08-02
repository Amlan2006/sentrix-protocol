// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {UserVaultFactory} from "../src/factory/UserVaultFactory.sol";

contract DeployUserVaultFactory is Script {
    uint256 internal constant CELO_SEPOLIA_CHAIN_ID = 11_142_220;

    error UnsupportedChain(uint256 actualChainId);

    function run() external returns (UserVaultFactory factory) {
        if (block.chainid != CELO_SEPOLIA_CHAIN_ID) {
            revert UnsupportedChain(block.chainid);
        }

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        factory = new UserVaultFactory();
        vm.stopBroadcast();
    }
}
