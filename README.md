🪙 FlatCoin Protocol

<p align="center"> <b>Minimal Overcollateralized Stablecoin Engine</b><br/> <sub>ETH-backed • Chainlink-powered • Liquidation-secured</sub> </p> <p align="center"> <img src="https://img.shields.io/badge/Solidity-^0.8.18-1f425f?style=flat-square&logo=solidity"/> <img src="https://img.shields.io/badge/Foundry-Tested-black?style=flat-square"/> <img src="https://img.shields.io/badge/Status-Experimental-ff9800?style=flat-square"/> <img src="https://img.shields.io/badge/License-MIT-blue?style=flat-square"/> </p>

    “Stablecoins aren’t about stability alone—they’re about enforcing discipline through code.”

🌟 Highlights

1. 🪙 Overcollateralized Minting — Always backed by more value than issued
2. ⚖️ Health Factor Enforcement — Keeps positions safe and measurable
3. 💣 Liquidation Engine — Protects protocol solvency
4. 🔗 Chainlink Oracles — Reliable ETH/USD pricing
5. 🛑 Pause Control — Emergency circuit breaker

ℹ️ Overview

    FlatCoin is a collateral-backed stablecoin protocol where users deposit ETH and mint a USD-pegged asset (FC).

    The system ensures solvency through:

    Strict collateral ratios
    Real-time price feeds
    Automated liquidation of risky positions

    This project is designed as a learning + foundational DeFi primitive, inspired by real-world protocols like MakerDAO and Liquity.

🧱 Architecture

    src/
    ├── FlatCoin.sol          → ERC20 Stablecoin
    ├── FlatCoinEngine.sol    → Core Logic (Mint / Liquidate)
    └── PriceConverter.sol    → Oracle Utility (ETH → USD)

⚙️ Core Mechanism

    🧮 Health Factor
        HF=(Collateral×Threshold)/Debt

    | Condition | Status         |
    | --------- | -------------- |
    | HF ≥ 1    | ✅ Safe         |
    | HF < 1    | ❌ Liquidatable |

🚀 Usage

A quick look at how the protocol behaves in practice:

    // 1. Deposit ETH
    engine.stakeCollateral{value: 1 ether}();

    // 2. Mint FlatCoin
    engine.mintCoins(100e18);

    // 3. Monitor health
    engine.getHealthFactor(msg.sender);

⬇️ Installation

    git clone https://github.com/your-username/flatcoin
    cd flatcoin
    forge install
    forge build

Requirements

1. Solidity ^0.8.18
2. Foundry
3. Chainlink Price Feed

📊 Protocol Parameters

    | Parameter             | Value |
    | --------------------- | ----- |
    | Liquidation Threshold | 80%   |
    | Min Health Factor     | 1.0   |
    | Mint Threshold        | 1.2   |
    | Liquidation Bonus     | 10%   |
    | Protocol Fee          | 2%    |

⚠️ Known Limitations

1. ❌ Mint/Burn not access-controlled
2. ❌ No collateral withdrawal
3. ❌ Single collateral (ETH only)
4. ❌ Debt tracking inconsistency

   ⚡ This is a learning-stage protocol, not production-ready.

🛠 Roadmap

1.  Restrict mint/burn to engine
2.  Add withdrawal & position closing
3.  Multi-collateral support
4.  Stability fee mechanism
5.  Oracle safety checks

✍️ Author
`Supravo Sarkar`

💭 Feedback & Contributing
Have ideas, critiques, or improvements?

1. Open an issue
2. Start a discussion
3. Submit a pull request

All contributions—technical or conceptual—are welcome.

📜 License

MIT License

🧠 Final Note
`This project isn’t just about building a stablecoin—
it’s about understanding why systems fail, and how to design them not to.`
