// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {RouteValidator} from "../../src/execution/RouteValidator.sol";
import {BscTestnetConfig} from "./BscTestnetConfig.sol";

contract ConfigureRouteValidator is Script {
    error UnsupportedChain(uint256 actualChainId);
    error ZeroAddress();

    function run() external {
        if (block.chainid != BscTestnetConfig.CHAIN_ID) revert UnsupportedChain(block.chainid);

        address routeValidator = vm.envAddress("ROUTE_VALIDATOR");
        address pancakeAdapter = vm.envAddress("PANCAKE_V2_ADAPTER");
        address mockUsdc = vm.envAddress("MOCK_USDC");
        address mockWbtc = vm.envAddress("MOCK_WBTC");

        if (
            routeValidator == address(0) || pancakeAdapter == address(0) || mockUsdc == address(0)
                || mockWbtc == address(0)
        ) {
            revert ZeroAddress();
        }

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        RouteValidator(routeValidator).setAdapterApproval(pancakeAdapter, true);
        RouteValidator(routeValidator).setTokenApproval(mockUsdc, true);
        RouteValidator(routeValidator).setTokenApproval(BscTestnetConfig.WBNB, true);
        RouteValidator(routeValidator).setTokenApproval(mockWbtc, true);
        vm.stopBroadcast();
    }
}
