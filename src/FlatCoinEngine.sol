// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {FlatCoin} from "./FlatCoin.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract FlatCoinEngine is Ownable, ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                            STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct CollateralConfig {
        address priceFeed;
        uint256 liquidationThreshold; // e.g. 80
        uint256 liquidationBonus; // e.g. 10
        bool enabled;
    }

    struct UserPosition {
        uint256 debt;
        uint256 lastUpdated;
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 private constant PRECISION = 1e18;
    uint256 private constant LIQ_PRECISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1e18;
    uint256 private constant ORACLE_TIMEOUT = 3 hours;

    uint256 private constant STABILITY_FEE = 5e16; // 5% APR scaled

    /*//////////////////////////////////////////////////////////////
                            STORAGE
    //////////////////////////////////////////////////////////////*/

    FlatCoin private immutable i_flatCoin;
    address private immutable i_treasury;

    address[] private s_tokens;

    mapping(address => CollateralConfig) private s_config;
    mapping(address => mapping(address => uint256)) private s_collateral;
    mapping(address => UserPosition) private s_positions;

    mapping(address => uint256) private s_protocolFees;

    /*//////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    event CollateralDeposited(address user, address token, uint256 amount);
    event CollateralWithdrawn(address user, address token, uint256 amount);
    event Minted(address user, uint256 amount);
    event Burned(address user, uint256 amount);
    event Liquidated(address liquidator, address user, address token, uint256 debtCovered);

    /*//////////////////////////////////////////////////////////////
                            ERRORS
    //////////////////////////////////////////////////////////////*/

    error InvalidAmount();
    error TokenNotSupported();
    error TransferFailed();
    error BreaksHealthFactor(uint256 hf);
    error HealthFactorOk();
    error OracleFailure();
    error NotEnoughCollateral();

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address flatCoin, address treasury) Ownable(msg.sender) {
        i_flatCoin = FlatCoin(flatCoin);
        i_treasury = treasury;
    }

    /*//////////////////////////////////////////////////////////////
                        ADMIN CONFIG
    //////////////////////////////////////////////////////////////*/

    function addCollateral(address token, address priceFeed, uint256 liqThreshold, uint256 liqBonus)
        external
        onlyOwner
    {
        s_config[token] = CollateralConfig(priceFeed, liqThreshold, liqBonus, true);
        s_tokens.push(token);
    }

    /*//////////////////////////////////////////////////////////////
                        USER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function deposit(address token, uint256 amount) external nonReentrant {
        if (amount == 0) revert InvalidAmount();
        if (!s_config[token].enabled) revert TokenNotSupported();

        s_collateral[msg.sender][token] += amount;

        emit CollateralDeposited(msg.sender, token, amount);

        bool success = IERC20(token).transferFrom(msg.sender, address(this), amount);
        if (!success) revert TransferFailed();
    }

    function mint(uint256 amount) external nonReentrant {
        if (amount == 0) revert InvalidAmount();

        _accrueInterest(msg.sender);

        uint256 newDebt = s_positions[msg.sender].debt + amount;

        if (_healthFactor(msg.sender, newDebt) < MIN_HEALTH_FACTOR) {
            revert BreaksHealthFactor(_healthFactor(msg.sender, newDebt));
        }

        s_positions[msg.sender].debt = newDebt;

        i_flatCoin.mint(msg.sender, amount);

        emit Minted(msg.sender, amount);
    }

    function burn(uint256 amount) external nonReentrant {
        _accrueInterest(msg.sender);

        s_positions[msg.sender].debt -= amount;

        bool success = i_flatCoin.transferFrom(msg.sender, address(this), amount);
        if (!success) revert TransferFailed();

        i_flatCoin.burn(address(this), amount);

        emit Burned(msg.sender, amount);
    }

    function withdraw(address token, uint256 amount) external nonReentrant {
        if (s_collateral[msg.sender][token] < amount) revert NotEnoughCollateral();

        s_collateral[msg.sender][token] -= amount;

        if (_healthFactor(msg.sender, s_positions[msg.sender].debt) < MIN_HEALTH_FACTOR) {
            revert BreaksHealthFactor(_healthFactor(msg.sender, s_positions[msg.sender].debt));
        }

        emit CollateralWithdrawn(msg.sender, token, amount);

        bool success = IERC20(token).transfer(msg.sender, amount);
        if (!success) revert TransferFailed();
    }

    /*//////////////////////////////////////////////////////////////
                        LIQUIDATION
    //////////////////////////////////////////////////////////////*/

    function liquidate(address user, address token, uint256 debtToCover) external nonReentrant {
        _accrueInterest(user);

        if (_healthFactor(user, s_positions[user].debt) >= MIN_HEALTH_FACTOR) {
            revert HealthFactorOk();
        }

        CollateralConfig memory cfg = s_config[token];

        uint256 price = _getPrice(cfg.priceFeed);

        uint256 collateralValue = (debtToCover * PRECISION) / price;

        uint256 bonus = (collateralValue * cfg.liquidationBonus) / LIQ_PRECISION;

        uint256 totalSeize = collateralValue + bonus;

        if (totalSeize > s_collateral[user][token]) {
            totalSeize = s_collateral[user][token];
        }

        s_collateral[user][token] -= totalSeize;
        s_positions[user].debt -= debtToCover;

        s_collateral[msg.sender][token] += totalSeize;

        bool success = i_flatCoin.transferFrom(msg.sender, address(this), debtToCover);
        if (!success) revert TransferFailed();

        i_flatCoin.burn(address(this), debtToCover);

        emit Liquidated(msg.sender, user, token, debtToCover);
    }

    /*//////////////////////////////////////////////////////////////
                        INTEREST LOGIC
    //////////////////////////////////////////////////////////////*/

    function _accrueInterest(address user) internal {
        UserPosition storage pos = s_positions[user];

        if (pos.debt == 0) {
            pos.lastUpdated = block.timestamp;
            return;
        }

        uint256 timeElapsed = block.timestamp - pos.lastUpdated;

        uint256 interest = (pos.debt * STABILITY_FEE * timeElapsed) / (365 days * PRECISION);

        pos.debt += interest;
        s_protocolFees[address(i_flatCoin)] += interest;

        pos.lastUpdated = block.timestamp;
    }

    /*//////////////////////////////////////////////////////////////
                        VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _healthFactor(address user, uint256 debt) internal view returns (uint256) {
        if (debt == 0) return type(uint256).max;

        uint256 totalCollateralUsd;

        for (uint256 i = 0; i < s_tokens.length; i++) {
            address token = s_tokens[i];
            uint256 amount = s_collateral[user][token];

            if (amount == 0) continue;

            CollateralConfig memory cfg = s_config[token];

            uint256 price = _getPrice(cfg.priceFeed);

            uint256 value = (amount * price) / PRECISION;

            uint256 adjusted = (value * cfg.liquidationThreshold) / LIQ_PRECISION;

            totalCollateralUsd += adjusted;
        }

        return (totalCollateralUsd * PRECISION) / debt;
    }

    function _getPrice(address feed) internal view returns (uint256) {
        (, int256 answer,, uint256 updatedAt,) = AggregatorV3Interface(feed).latestRoundData();

        if (answer <= 0) revert OracleFailure();
        if (block.timestamp - updatedAt > ORACLE_TIMEOUT) revert OracleFailure();

        return uint256(answer) * 1e10;
    }

    function getHealthFactor(address user) external view returns (uint256) {
        return _healthFactor(user, s_positions[user].debt);
    }

    function getDebt(address user) external view returns (uint256) {
        return s_positions[user].debt;
    }

    function getCollateral(address user, address token) external view returns (uint256) {
        return s_collateral[user][token];
    }
}
