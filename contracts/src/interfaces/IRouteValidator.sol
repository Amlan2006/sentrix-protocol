// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SentrixTypes} from "../libraries/SentrixTypes.sol";

interface IRouteValidator {
    function validateRoute(
        SentrixTypes.ArbitrageRequest calldata request,
        SentrixTypes.UserRiskConfig calldata riskConfig,
        bool usesFlashLoan
    ) external view returns (bool);
}
