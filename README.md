# 🪙 FlatCoin Protocol

<p align="center">
  <b>Overcollateralized Stablecoin Engine</b><br/>
  <sub>Multi-Collateral • Chainlink Oracles • Liquidation-secured</sub>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Solidity-^0.8.18-1f425f?style=flat-square&logo=solidity"/>
  <img src="https://img.shields.io/badge/Foundry-Tested-black?style=flat-square"/>
  <img src="https://img.shields.io/badge/Architecture-Modular-6c5ce7?style=flat-square"/>
  <img src="https://img.shields.io/badge/Status-Prototype-ff9800?style=flat-square"/>
  <img src="https://img.shields.io/badge/License-MIT-blue?style=flat-square"/>
</p>

<p align="center">
  <i>“Stablecoins aren’t about stability alone—they’re about enforcing discipline through code.”</i>
</p>

---

## 🌟 Highlights

- 🪙 **Overcollateralized Minting** — Always backed by excess collateral
- ⚖️ **Health Factor Enforcement** — Continuous solvency monitoring
- 💣 **Liquidation Engine** — Incentivized third-party liquidations
- 🔗 **Chainlink Oracles** — Reliable, decentralized price feeds
- 🛑 **Pause Mechanism** — Emergency circuit breaker
- 🧱 **Modular Architecture** — Engine + Token separation
- 🧪 **Tested with Foundry** — Unit + Integration coverage
- 🚀 **Deployment Ready** — Scripts for local + Sepolia + Mainnet

---

## ℹ️ Overview

**FlatCoin** is a decentralized, overcollateralized stablecoin protocol where users:

1. Deposit collateral (e.g., ETH, WBTC)
2. Mint a USD-pegged asset (**FC**)
3. Maintain a safe collateral ratio to avoid liquidation

The system maintains solvency through:

- Strict collateralization thresholds
- Real-time oracle pricing
- Automated liquidation of undercollateralized positions

Inspired by systems like MakerDAO and Liquity, FlatCoin focuses on **clarity, modularity, and risk enforcement**.

---

## 🧱 Architecture

    src/

├── FlatCoin.sol → ERC20 Stablecoin (Engine-controlled)
├── FlatCoinEngine.sol → Core Protocol Logic
└── PriceConverter.sol → Oracle Utilities

### 🔑 Design Principles

- **Separation of Concerns**
  - Token ≠ Logic
- **Protocol-Enforced Safety**
  - No trust assumptions
- **Composable Structure**
  - Extendable to multi-collateral + fees

---

## ⚙️ Core Mechanism

### 🧮 Health Factor

    HF = (Collateral Value × Liquidation Threshold) / Debt

| Condition | Status          |
| --------- | --------------- |
| HF ≥ 1    | ✅ Safe         |
| HF < 1    | ❌ Liquidatable |

---

## 🔁 Protocol Flow

```solidity
// 1. Deposit Collateral
engine.deposit(token, amount);

// 2. Mint Stablecoin
engine.mint(amount);

// 3. Monitor Position
engine.getHealthFactor(user);

// 4. Burn to reduce debt
engine.burn(amount);

// 5. Withdraw collateral
engine.withdraw(token, amount);
```

🧪 Testing

FlatCoin uses Foundry for high-performance testing.

Test Coverage Includes:
✅ Collateral deposit / withdrawal
✅ Minting constraints & health factor
✅ Liquidation flows
✅ Multi-user interactions
✅ Interest / time-based scenarios

    forge test -vv

🚀 Deployment
Local (Anvil)
make anvil
make deploy-local

Sepolia
make deploy-sepolia

Interact (Live Network)
make interact-sepolia

⚙️ Configuration

Environment variables (.env):

    SEPOLIA_RPC_URL=...
    MAINNET_RPC_URL=...
    PRIVATE_KEY=...
    ETHERSCAN_API_KEY=...

📊 Protocol Parameters
| Parameter | Value |
| --------------------- | ----- |
| Liquidation Threshold | 80% |
| Min Health Factor | 1.0 |
| Mint Threshold | 1.2 |
| Liquidation Bonus | 10% |
| Protocol Fee | 2% |

⚠️ Risks & Considerations 1. Oracle dependency (Chainlink) 2. Extreme volatility → liquidation cascades 3. No stability fee yet (no peg pressure control) 4. Prototype-level economic design

⚡ This is a research & prototype system, not production-ready.

🛠 Roadmap

🔒 Short Term
Engine-controlled mint/burn
Collateral withdrawal logic
Multi-collateral support
Liquidation incentives

🚧 Mid Term
Stability fee / interest model
Oracle fallback / circuit breakers
Peg stability mechanisms
Frontend dashboard

🧠 Advanced
Cross-chain collateral
L2 deployment
Governance layer
Risk parameter automation

🎯 Why This Matters

    FlatCoin is not just a stablecoin—

    It’s a minimal, transparent implementation of collateralized debt systems, designed to explore:

    1. Risk management in DeFi
    2. Incentive-driven liquidation systems
    3. Protocol-level safety guarantees

👤 Author

    Supravo Sarkar

💭 Contributing

    Have ideas or improvements?

    1. Open an issue
    2. Start a discussion
    3. Submit a PR

All contributions are welcome.

📜 License

    MIT License

🧠 Final Note

    “Good DeFi systems don’t rely on trust—
    they rely on constraints that cannot be broken.”
