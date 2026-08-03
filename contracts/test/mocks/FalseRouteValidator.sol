// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IRouteValidator} from "../../src/interfaces/IRouteValidator.sol";
import {SentrixTypes} from "../../src/libraries/SentrixTypes.sol";

contract FalseRouteValidator is IRouteValidator {
    function validateRoute(SentrixTypes.ArbitrageRequest calldata, SentrixTypes.UserRiskConfig calldata, bool)
        external
        pure
        returns (bool)
    {
        return false;
    }
}
