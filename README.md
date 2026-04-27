🪙 FlatCoin Protocol

A minimal overcollateralized stablecoin system built with Solidity.
FlatCoin (FC) is a USD-pegged stablecoin backed by ETH collateral and enforced through a health factor mechanism.

📌 Overview

FlatCoin is designed to maintain a soft peg of 1 FC ≈ $1 using:

Overcollateralization (users deposit more value than they mint)
Real-time price feeds (via Chainlink)
Liquidation mechanism for undercollateralized positions

The system consists of three core components:

FlatCoin.sol → ERC20 stablecoin
FlatCoinEngine.sol → Core protocol logic (minting, staking, liquidation)
PriceConverter.sol → ETH ↔ USD conversion using Chainlink
🏗 Architecture

1. FlatCoin (ERC20 Token)
   Standard ERC20 token
   Minting & burning controlled externally
   Pausable transfers
   Owned by deployer

⚠️ Important Note:
Currently, anyone can mint and burn tokens, which is unsafe for production.

2. FlatCoinEngine (Core Logic)

Handles:

Collateral staking (ETH)
Minting FlatCoin
Health factor enforcement
Liquidation of risky positions 3. PriceConverter (Library)
Fetches ETH/USD price from Chainlink
Converts ETH amount → USD value
⚙️ Key Concepts
🧮 Health Factor (HF)

The most important safety metric in the protocol.

HF = (Collateral Value × Liquidation Threshold) / Debt
If HF ≥ 1 → Safe
If HF < 1 → Liquidatable
📊 Parameters
Parameter Value Description
Liquidation Threshold 80% Max borrow limit
Min Health Factor 1.0 Below this → liquidation
Mint Threshold 1.2 Required to mint
Liquidation Bonus 10% Incentive for liquidators
Protocol Fee 2% Goes to treasury
🚀 How It Works

1. Deposit Collateral
   stakeCollateral()
   Users deposit ETH
   Stored in s_collateralDeposited
2. Mint FlatCoin
   mintCoins(amount)

Requirements:

Must maintain Health Factor ≥ 1.2 3. Liquidation
liquidate(user, debtToCover)

Triggered when:

User’s HF < 1

Process:

Liquidator repays user’s debt
Receives:
Equivalent collateral
+10% bonus
Protocol takes 2% fee
🔥 Example
Action Value
Deposit $120 ETH
Mint $100 FC
HF 0.96 (after threshold adjustment)

➡️ Position becomes liquidatable

⚠️ Critical Issues (Must Fix)
❌ 1. Unrestricted Minting/Burning
function mint(address \_minter, uint256 \_amount) external
Anyone can mint unlimited tokens
Breaks entire system

✅ Fix:

modifier onlyEngine() {
require(msg.sender == address(engine));
\_;
}
❌ 2. Health Factor Bug
uint256 totalMinted = i_flatCoin.balanceOf(user);
Uses wallet balance instead of debt

✅ Should be:

uint256 totalMinted = s_tokensMinted[user];
❌ 3. Liquidation Doesn’t Reduce Debt
s_tokensMinted[user] is NOT updated

✅ Fix:

s_tokensMinted[user] -= debtToCover;
❌ 4. No Collateral Withdrawal Logic

Users cannot:

Withdraw ETH
Close positions
❌ 5. No Multi-Collateral Support

Only ETH is supported
(Not scalable for real systems)

🛠 Suggested Improvements
Restrict mint/burn to Engine
Add collateral withdrawal
Add multi-asset collateral (WBTC, LINK)
Add interest/stability fees
Add liquidation penalty tuning
Add oracle safety checks (stale price)
🔐 Security Features
Reentrancy protection (ReentrancyGuard)
Health factor enforcement
Chainlink price feeds
Liquidation incentives
📦 Deployment
Requirements
Solidity ^0.8.18
Chainlink Price Feed (ETH/USD)
Steps
Deploy FlatCoin
Deploy FlatCoinEngine
Link both contracts
Set price feed address
🧪 Future Scope
DAO governance
Stability pool
Cross-chain deployment
Yield integration
Peg stabilization mechanisms
🧠 Inspiration

This protocol is inspired by:

MakerDAO (DAI)
Liquity (LUSD)
Overcollateralized DeFi primitives
🤝 Contributing

Feel free to fork, test, and improve the protocol.

📜 License

MIT License
