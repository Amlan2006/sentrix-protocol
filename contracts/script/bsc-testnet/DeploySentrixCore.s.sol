// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {PancakeV2Adapter} from "../../src/adapters/PancakeV2Adapter.sol";
import {RouteValidator} from "../../src/execution/RouteValidator.sol";
import {UserVaultFactory} from "../../src/factory/UserVaultFactory.sol";
import {BscTestnetConfig} from "./BscTestnetConfig.sol";

contract DeploySentrixCore is Script {
    error UnsupportedChain(uint256 actualChainId);

    function run()
        external
        returns (UserVaultFactory vaultFactory, RouteValidator routeValidator, PancakeV2Adapter pancakeAdapter)
    {
        if (block.chainid != BscTestnetConfig.CHAIN_ID) {
            revert UnsupportedChain(block.chainid);
        }

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address owner = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);
        vaultFactory = new UserVaultFactory();
        routeValidator = new RouteValidator(owner);
        pancakeAdapter = new PancakeV2Adapter(
            BscTestnetConfig.PANCAKE_V2_ROUTER, BscTestnetConfig.PANCAKE_V2_FACTORY, BscTestnetConfig.WBNB
        );
        vm.stopBroadcast();
    }
}
