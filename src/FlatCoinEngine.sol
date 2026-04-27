// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {FlatCoin} from "./FlatCoin.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract FlatCoinEngine is Ownable, ReentrancyGuard {
    using PriceConverter for uint256;

    /* Types & Constants */
    uint256 private constant LIQUIDATION_THRESHOLD = 80; // 80% collateralized
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1e18;
    uint256 private constant LIQUIDATION_BONUS = 10; // 10% bonus for liquidators
    uint256 private constant PRECISION = 1e18;
    uint256 private constant PROTOCOL_FEE = 2;
    uint256 private constant MINT_HEALTH_FACTOR_THRESHOLD = 12e17; // 1.2 in 18-decimal precision

    address private s_treasury;

    /* State Variables */
    FlatCoin private immutable i_flatCoin;
    AggregatorV3Interface private immutable i_priceFeed;
    mapping(address => uint256) private s_collateralDeposited;
    mapping(address => uint256) s_tokensMinted;

    /* Events & Errors */
    event CollateralDeposited(address indexed user, uint256 amount);
    event TokensMinted(address indexed user, uint256 amount);
    event Liquidation(
        address indexed liquidator, address indexed staker, uint256 amountRepaid, uint256 collateralTaken
    );

    error FlatCoinEngine__NeedsMoreThanZero();
    error FlatCoinEngine__BreaksHealthFactor(uint256 healthFactor);
    error FlatCoinEngine__HealthFactorOk();
    error FlatCoinEngine__HealthFactorNotImproved();
    error FlatCoinEngine__TransferFailed();
    error FlatCoinEngine__BelowSafetyBarrier(uint256 healthFactor);

    /* Modifiers */
    modifier moreThanZero(uint256 amount) {
        if (amount == 0) revert FlatCoinEngine__NeedsMoreThanZero();
        _;
    }

    constructor(address priceFeed, address flatCoinAddress) Ownable(msg.sender) {
        i_priceFeed = AggregatorV3Interface(priceFeed);
        i_flatCoin = FlatCoin(flatCoinAddress);
        s_treasury = msg.sender;
    }

    /* External Functions */

    function stakeCollateral() public payable moreThanZero(msg.value) {
        s_collateralDeposited[msg.sender] += msg.value;
        emit CollateralDeposited(msg.sender, msg.value);
    }

    function mintCoins(uint256 amountToMint) public moreThanZero(amountToMint) nonReentrant {
        s_tokensMinted[msg.sender] += amountToMint;
        i_flatCoin.mint(msg.sender, amountToMint);

        uint256 hp = getHealthFactor(msg.sender);
        if (hp < MINT_HEALTH_FACTOR_THRESHOLD) {
            revert FlatCoinEngine__BelowSafetyBarrier(hp);
        }
        _revertIfHealthFactorIsBroken(msg.sender);
        emit TokensMinted(msg.sender, amountToMint);
    }

    /**
     * @param user The undercollateralized user to liquidate
     * @param debtToCover The amount of FlatCoin the liquidator wants to burn
     */
    function liquidate(address user, uint256 debtToCover) external moreThanZero(debtToCover) nonReentrant {
        uint256 startingHealthFactor = getHealthFactor(user);
        if (startingHealthFactor >= MIN_HEALTH_FACTOR) revert FlatCoinEngine__HealthFactorOk();

        // 1. Calculate how much ETH the debt is worth
        uint256 ethPrice = PriceConverter.getPrice(i_priceFeed);
        // (Debt / Price)
        uint256 collateralBase = (debtToCover * PRECISION) / ethPrice;

        // 2. Calculate Bonus (10%) and Fee (2%)
        uint256 liquidatorBonus = (collateralBase * LIQUIDATION_BONUS) / LIQUIDATION_PRECISION;
        uint256 protocolFeeAmount = (collateralBase * PROTOCOL_FEE) / LIQUIDATION_PRECISION;
        uint256 totalCollateralToTake = collateralBase + liquidatorBonus + protocolFeeAmount;

        // 3. State Updates
        s_collateralDeposited[user] -= totalCollateralToTake;
        s_collateralDeposited[msg.sender] += (collateralBase + liquidatorBonus);
        s_collateralDeposited[s_treasury] += protocolFeeAmount;

        // 4. THE CRITICAL STEP: Burn the Debt
        // Move tokens from liquidator to the engine and burn them
        bool success = i_flatCoin.transferFrom(msg.sender, address(this), debtToCover);
        if (!success) revert FlatCoinEngine__TransferFailed();
        i_flatCoin.burn(address(this), debtToCover);

        // 5. Final check: HF must improve!
        uint256 endingHealthFactor = getHealthFactor(user);
        if (endingHealthFactor <= startingHealthFactor) revert FlatCoinEngine__HealthFactorNotImproved();
    }

    /* Private & View Functions */

    function getHealthFactor(address user) public view returns (uint256) {
        uint256 totalMinted = i_flatCoin.balanceOf(user);
        if (totalMinted == 0) return type(uint256).max;

        uint256 collateralValueInUsd = getCollateralValueInUsd(user);
        uint256 collateralAdjustedForThreshold = (collateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;

        return (collateralAdjustedForThreshold * PRECISION) / totalMinted;
    }

    function getCollateralValueInUsd(address user) public view returns (uint256) {
        return s_collateralDeposited[user].getConversionRate(i_priceFeed);
    }

    function _revertIfHealthFactorIsBroken(address user) internal view {
        uint256 healthFactor = getHealthFactor(user);
        if (healthFactor < MIN_HEALTH_FACTOR) revert FlatCoinEngine__BreaksHealthFactor(healthFactor);
    }

    function getCollateralStaked(address user) external view returns (uint256) {
        return s_collateralDeposited[user];
    }
}
