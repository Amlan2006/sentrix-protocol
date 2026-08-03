// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SentrixTypes} from "../libraries/SentrixTypes.sol";

interface IUserVault {
    event Initialized(address indexed owner, address indexed settlementToken);
    event Deposited(address indexed vault, address indexed owner, uint256 amount);
    event Withdrawn(address indexed vault, address indexed owner, address indexed recipient, uint256 amount);
    event RiskConfigUpdated(address indexed vault, SentrixTypes.UserRiskConfig config);
    event ReinvestmentConfigUpdated(address indexed vault, uint16 reinvestmentBps);
    event FlashLoanArbitrageSettingUpdated(address indexed vault, bool enabled);
    event StrategyAuthorized(address indexed vault, address indexed strategy);
    event StrategyRevoked(address indexed vault, address indexed strategy);
    event EmergencyPaused(address indexed vault);
    event EmergencyUnpaused(address indexed vault);
    event EmergencyWithdrawal(address indexed vault, address indexed owner, address indexed recipient, uint256 amount);
    event UserFundedArbitrageStarted(address indexed vault, address indexed strategy, uint256 amount);
    event UserFundedArbitrageSettled(
        address indexed vault,
        address indexed strategy,
        uint256 principalAmount,
        uint256 grossProfit,
        uint256 withdrawableProfit,
        uint256 reinvestmentAmount
    );

    function initialize(address owner_, address settlementToken_, SentrixTypes.UserRiskConfig calldata riskConfig_)
        external;

    function deposit(uint256 amount) external;
    function withdraw(uint256 amount, address recipient) external;
    function emergencyWithdrawIdle(address recipient) external returns (uint256 amount);
    function setRiskConfig(SentrixTypes.UserRiskConfig calldata config) external;
    function setReinvestmentBps(uint16 reinvestmentBps) external;
    function setFlashLoanArbitrageEnabled(bool enabled) external;
    function authorizeStrategy(address strategy) external;
    function revokeStrategy(address strategy) external;
    function pauseEmergency() external;
    function unpauseEmergency() external;
    function startUserFundedArbitrage(uint256 amount, address recipient) external returns (uint256);
    function finishUserFundedArbitrage(uint256 principalAmount, uint256 grossProfit) external;

    function owner() external view returns (address);
    function settlementToken() external view returns (address);
    function initialized() external view returns (bool);
    function emergencyPaused() external view returns (bool);
    function flashLoanArbitrageEnabled() external view returns (bool);
    function isStrategyAuthorized(address strategy) external view returns (bool);
    function riskConfig() external view returns (SentrixTypes.UserRiskConfig memory);
    function accounting() external view returns (SentrixTypes.VaultAccounting memory);
}
