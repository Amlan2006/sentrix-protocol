// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {ControlledTestToken} from "../../src/testnet/ControlledTestToken.sol";
import {BscTestnetConfig} from "./BscTestnetConfig.sol";

contract DeployMockTokens is Script {
    error UnsupportedChain(uint256 actualChainId);

    function run() external returns (ControlledTestToken mockUsdc, ControlledTestToken mockWbtc) {
        if (block.chainid != BscTestnetConfig.CHAIN_ID) revert UnsupportedChain(block.chainid);

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address owner = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);
        mockUsdc = new ControlledTestToken("Sentrix Test USDC", "sUSDC", 6, owner);
        mockWbtc = new ControlledTestToken("Sentrix Test WBTC", "sWBTC", 8, owner);
        vm.stopBroadcast();
    }
}
