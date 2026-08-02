// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {IPancakeV2Router} from "../../src/interfaces/IPancakeV2Router.sol";
import {BscTestnetConfig} from "./BscTestnetConfig.sol";

contract SmokeTestPancakeConfig is Script {
    error UnsupportedChain(uint256 actualChainId);
    error UnexpectedFactory(address actualFactory);
    error UnexpectedWbnb(address actualWbnb);

    function run() external view {
        if (block.chainid != BscTestnetConfig.CHAIN_ID) revert UnsupportedChain(block.chainid);

        IPancakeV2Router router = IPancakeV2Router(BscTestnetConfig.PANCAKE_V2_ROUTER);
        address actualFactory = router.factory();
        if (actualFactory != BscTestnetConfig.PANCAKE_V2_FACTORY) revert UnexpectedFactory(actualFactory);

        address actualWbnb = router.WETH();
        if (actualWbnb != BscTestnetConfig.WBNB) revert UnexpectedWbnb(actualWbnb);
    }
}
