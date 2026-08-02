// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {IPancakeV2Factory} from "../../src/interfaces/IPancakeV2Factory.sol";
import {BscTestnetConfig} from "./BscTestnetConfig.sol";

contract CreatePancakePools is Script {
    error UnsupportedChain(uint256 actualChainId);
    error ZeroAddress();

    function run() external returns (address usdcWbnbPair, address wbnbWbtcPair, address wbtcUsdcPair) {
        if (block.chainid != BscTestnetConfig.CHAIN_ID) revert UnsupportedChain(block.chainid);

        address usdc = vm.envAddress("MOCK_USDC");
        address wbtc = vm.envAddress("MOCK_WBTC");
        if (usdc == address(0) || wbtc == address(0)) revert ZeroAddress();

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        IPancakeV2Factory factory = IPancakeV2Factory(BscTestnetConfig.PANCAKE_V2_FACTORY);

        vm.startBroadcast(deployerPrivateKey);
        usdcWbnbPair = _getOrCreatePair(factory, usdc, BscTestnetConfig.WBNB);
        wbnbWbtcPair = _getOrCreatePair(factory, BscTestnetConfig.WBNB, wbtc);
        wbtcUsdcPair = _getOrCreatePair(factory, wbtc, usdc);
        vm.stopBroadcast();
    }

    function _getOrCreatePair(IPancakeV2Factory factory, address tokenA, address tokenB)
        private
        returns (address pair)
    {
        pair = factory.getPair(tokenA, tokenB);
        if (pair == address(0)) {
            pair = factory.createPair(tokenA, tokenB);
        }
    }
}
