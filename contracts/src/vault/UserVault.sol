// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IUserVault} from "../interfaces/IUserVault.sol";
import {SentrixTypes} from "../libraries/SentrixTypes.sol";

contract UserVault is IUserVault, ReentrancyGuard {
    using SafeERC20 for IERC20;

    error AlreadyInitialized();
    error NotInitialized();
    error Unauthorized();
    error ZeroAddress();
    error InvalidAmount();
    error InsufficientIdleBalance();
    error InvalidRecipient();
    error InvalidBasisPoints();
    error StrategyAlreadyAuthorized();
    error StrategyNotAuthorized();
    error PausedOperation();

    address public override owner;
    address public override settlementToken;
    bool public override initialized;
    bool public override emergencyPaused;
    bool public override flashLoanArbitrageEnabled;

    SentrixTypes.UserRiskConfig private _riskConfig;
    SentrixTypes.VaultAccounting private _accounting;
    mapping(address strategy => bool authorized) private _authorizedStrategies;

    modifier onlyInitialized() {
        if (!initialized) revert NotInitialized();
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    modifier whenAutomationNotPaused() {
        if (emergencyPaused) revert PausedOperation();
        _;
    }

    function initialize(address owner_, address settlementToken_, SentrixTypes.UserRiskConfig calldata riskConfig_)
        external
        override
    {
        if (initialized) revert AlreadyInitialized();
        if (owner_ == address(0) || settlementToken_ == address(0)) revert ZeroAddress();
        _validateRiskConfig(riskConfig_);

        initialized = true;
        owner = owner_;
        settlementToken = settlementToken_;
        _riskConfig = riskConfig_;
        _riskConfig.flashLoanArbitrageEnabled = false;
        flashLoanArbitrageEnabled = false;

        emit Initialized(owner_, settlementToken_);
        emit RiskConfigUpdated(address(this), _riskConfig);
        emit FlashLoanArbitrageSettingUpdated(address(this), false);
    }

    function deposit(uint256 amount) external override onlyInitialized whenAutomationNotPaused nonReentrant {
        if (amount == 0) revert InvalidAmount();

        _accounting.principalDeposited += amount;
        _accounting.idleSettlementBalance += amount;

        IERC20(settlementToken).safeTransferFrom(msg.sender, address(this), amount);

        emit Deposited(address(this), msg.sender, amount);
    }

    function withdraw(uint256 amount, address recipient) external override onlyInitialized onlyOwner nonReentrant {
        _withdrawIdle(amount, recipient);
        emit Withdrawn(address(this), msg.sender, recipient, amount);
    }

    function emergencyWithdrawIdle(address recipient)
        external
        override
        onlyInitialized
        onlyOwner
        nonReentrant
        returns (uint256 amount)
    {
        amount = _accounting.idleSettlementBalance;
        _withdrawIdle(amount, recipient);
        emit EmergencyWithdrawal(address(this), msg.sender, recipient, amount);
    }

    function setRiskConfig(SentrixTypes.UserRiskConfig calldata config) external override onlyInitialized onlyOwner {
        _validateRiskConfig(config);
        _riskConfig = config;
        flashLoanArbitrageEnabled = config.flashLoanArbitrageEnabled;

        emit RiskConfigUpdated(address(this), config);
        emit FlashLoanArbitrageSettingUpdated(address(this), config.flashLoanArbitrageEnabled);
    }

    function setReinvestmentBps(uint16 reinvestmentBps) external override onlyInitialized onlyOwner {
        if (reinvestmentBps > 10_000) revert InvalidBasisPoints();
        _riskConfig.reinvestmentBps = reinvestmentBps;

        emit ReinvestmentConfigUpdated(address(this), reinvestmentBps);
        emit RiskConfigUpdated(address(this), _riskConfig);
    }

    function setFlashLoanArbitrageEnabled(bool enabled) external override onlyInitialized onlyOwner {
        flashLoanArbitrageEnabled = enabled;
        _riskConfig.flashLoanArbitrageEnabled = enabled;

        emit FlashLoanArbitrageSettingUpdated(address(this), enabled);
        emit RiskConfigUpdated(address(this), _riskConfig);
    }

    function authorizeStrategy(address strategy) external override onlyInitialized onlyOwner whenAutomationNotPaused {
        if (strategy == address(0)) revert ZeroAddress();
        if (_authorizedStrategies[strategy]) revert StrategyAlreadyAuthorized();

        _authorizedStrategies[strategy] = true;

        emit StrategyAuthorized(address(this), strategy);
    }

    function revokeStrategy(address strategy) external override onlyInitialized onlyOwner {
        if (strategy == address(0)) revert ZeroAddress();
        if (!_authorizedStrategies[strategy]) revert StrategyNotAuthorized();

        _authorizedStrategies[strategy] = false;

        emit StrategyRevoked(address(this), strategy);
    }

    function pauseEmergency() external override onlyInitialized onlyOwner {
        emergencyPaused = true;
        emit EmergencyPaused(address(this));
    }

    function unpauseEmergency() external override onlyInitialized onlyOwner {
        emergencyPaused = false;
        emit EmergencyUnpaused(address(this));
    }

    function isStrategyAuthorized(address strategy) external view override returns (bool) {
        return _authorizedStrategies[strategy];
    }

    function riskConfig() external view override returns (SentrixTypes.UserRiskConfig memory) {
        return _riskConfig;
    }

    function accounting() external view override returns (SentrixTypes.VaultAccounting memory) {
        return _accounting;
    }

    function _withdrawIdle(uint256 amount, address recipient) private {
        if (recipient == address(0)) revert InvalidRecipient();
        if (amount == 0) revert InvalidAmount();
        if (amount > _accounting.idleSettlementBalance) revert InsufficientIdleBalance();

        _accounting.idleSettlementBalance -= amount;
        _accounting.principalWithdrawn += amount;

        IERC20(settlementToken).safeTransfer(recipient, amount);
    }

    function _validateRiskConfig(SentrixTypes.UserRiskConfig calldata config) private pure {
        if (config.maxSlippageBps > 10_000 || config.reinvestmentBps > 10_000) {
            revert InvalidBasisPoints();
        }
    }
}
