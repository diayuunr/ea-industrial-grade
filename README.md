# Industrial-Grade Multi-Asset EA

**MetaTrader 5 Expert Advisor | Multi-Asset System | Exness | Real-Tick Backtesting**

> A modular and risk-managed Expert Advisor (EA) developed for the Sains Manajemen Industrial-Grade project.

---

## 📌 Project Overview

**Industrial-Grade Multi-Asset EA** is a modular Expert Advisor developed for MetaTrader 5 (MT5). The system is designed to operate across multiple asset classes using a systematic trend-following and breakout approach combined with momentum filtering, volatility-based trade management, and risk-based position sizing.

The project focuses not only on trading performance, but also on **modularity, risk management, reproducibility, optimization, robustness testing, and systematic backtest evaluation**.

The EA is designed to be evaluated using **Exness historical market data** and the MetaTrader 5 Strategy Tester with **Every tick based on real ticks**.

---

## 🎯 Project Objectives

The main objectives of this project are:

- Develop a systematic and rule-based Expert Advisor.
- Support multiple asset classes through a unified EA architecture.
- Implement risk-based position sizing.
- Apply predefined drawdown and loss protection.
- Avoid Martingale, Grid, and HFT mechanisms.
- Establish a reproducible optimization and backtesting workflow.
- Evaluate the strategy using seven years of historical data.
- Analyze monthly and annual performance.
- Evaluate robustness across multiple instruments and market conditions.

---

## 📋 Assignment Requirements

| Requirement | Specification |
|---|---|
| Platform | MetaTrader 5 |
| Broker | Exness |
| Testing Model | **Every tick based on real ticks** |
| Timeframe | H1 |
| Backtest Period | 7 years |
| Asset Classes | Forex, Metals, Indices, Crypto, Energy |
| Instruments | 10 |
| Martingale | ❌ Not used |
| Grid | ❌ Not used |
| HFT | ❌ Not used |
| Position Sizing | Risk-based |
| Drawdown Control | Implemented |
| Optimization | Implemented |
| Out-of-Sample Validation | Implemented in workflow |
| Monthly Analysis | Implemented |
| Annual Analysis | Implemented |

---

# 📊 Asset Universe

The system is designed to be evaluated across **10 instruments from 5 asset classes**.

| No. | Instrument | Asset Class |
|---:|---|---|
| 1 | EURUSD | Forex |
| 2 | USDJPY | Forex |
| 3 | GBPUSD | Forex |
| 4 | XAUUSD | Metals |
| 5 | XAGUSD | Metals |
| 6 | US30 | Indices |
| 7 | JP225 | Indices |
| 8 | BTCUSD | Crypto |
| 9 | ETHUSD | Crypto |
| 10 | USOIL | Energy |

> **Note:** Exness symbol names may contain account-specific suffixes such as `m`. The exact symbol available in the connected MT5 terminal should be used during testing.

---

# 🧠 Trading Strategy

The EA combines trend identification, breakout confirmation, momentum filtering, and volatility-based trade management.

### Strategy Flow

```text
Market Data
     │
     ▼
Trend Identification
EMA Fast / EMA Slow
     │
     ▼
Breakout Detection
Historical High / Low
     │
     ▼
Trend Strength Filter
ADX
     │
     ▼
Volatility Measurement
ATR
     │
     ▼
Risk Management
Position Sizing + SL/TP
     │
     ▼
Trade Execution
     │
     ▼
Position Management
Break-even + ATR Trailing
```

### Core Components

- **EMA** — identifies the dominant market direction.
- **Breakout** — identifies directional price expansion.
- **ADX** — filters weak or non-trending market conditions.
- **ATR** — adapts stop-loss and trailing distance to market volatility.
- **Risk-based sizing** — calculates trade volume according to predefined account risk.

Entry conditions are evaluated on **new bars**, rather than continuously opening trades on every incoming tick.

---

# 🛡️ Risk Management

Risk management is a core component of the EA architecture.

The system includes:

- Fixed fractional risk per trade.
- ATR-based Stop Loss.
- Risk/Reward-based Take Profit.
- Break-even management.
- ATR-based trailing stop.
- Maximum drawdown protection.
- Daily loss protection.
- One active position per symbol.
- Broker-aware volume normalization.

### Prohibited Mechanisms

The EA explicitly does **not** use:

- ❌ Martingale
- ❌ Grid trading
- ❌ Averaging down
- ❌ Loss-based lot multiplication
- ❌ High-Frequency Trading (HFT)

The system aims to maintain a controlled and explainable risk profile rather than increasing exposure after losses.

---

# 🏗️ System Architecture

The project uses a modular architecture to separate configuration, indicator processing, risk management, and trade execution.

```text
EA-Industrial-Grade-Diayu/
│
├── MQL5/
│   ├── Include/
│   │   ├── DiayuConfig.mqh
│   │   ├── DiayuIndicators.mqh
│   │   ├── DiayuRisk.mqh
│   │   └── DiayuExecution.mqh
│   │
│   └── Experts/
│       └── DiayuIndustrialEA.mq5
│
├── config/
│   ├── instruments.csv
│   └── test_matrix.csv
│
├── optimization/
│   ├── baseline/
│   ├── parameter-ranges/
│   └── selected/
│
├── backtest/
│   ├── reports/
│   ├── screenshots/
│   └── results/
│
├── analysis/
│   ├── monthly/
│   └── annual/
│
├── tests/
├── docs/
├── report/
└── tools/
```

### Module Responsibilities

| Module | Responsibility |
|---|---|
| `DiayuConfig.mqh` | System constants and default configuration |
| `DiayuIndicators.mqh` | EMA, ADX, and ATR indicator handling |
| `DiayuRisk.mqh` | Position sizing and account risk controls |
| `DiayuExecution.mqh` | Order execution and position modification |
| `DiayuIndustrialEA.mq5` | Main EA orchestration |

This modular structure allows individual components to be maintained, tested, and modified independently.

---

# 🧪 Backtest Methodology

Backtesting is performed using the **MetaTrader 5 Strategy Tester** with historical data from Exness.

### Standard Configuration

```text
Broker       : Exness
Platform     : MetaTrader 5
Model        : Every tick based on real ticks
Timeframe    : H1
Period       : 7 years
```

The exact testing period, initial deposit, symbol specification, and tester configuration are documented together with each backtest report.

### Data Quality

The project prioritizes **real tick historical data** rather than generated tick simulation.

For validated tests, the Strategy Tester configuration and resulting modeling/history quality are recorded as evidence.

> Performance statistics and modeling quality are never manually fabricated. Reported values must originate from an actual MetaTrader 5 Strategy Tester run.

---

# ⚙️ Optimization Workflow

Optimization is performed after establishing a valid baseline backtest.

```text
Baseline Test
      │
      ▼
Parameter Search
      │
      ▼
Candidate Selection
      │
      ▼
Robustness Analysis
      │
      ▼
Parameter Freeze
      │
      ▼
Out-of-Sample Validation
      │
      ▼
Final Multi-Asset Backtest
```

### Parameters Considered

Typical optimization parameters include:

- Fast EMA period
- Slow EMA period
- Minimum ADX
- Breakout lookback
- ATR Stop Loss multiplier
- Risk/Reward ratio

Risk percentage and drawdown limits are primarily treated as **risk controls**, rather than parameters for artificially maximizing returns.

### Selection Criteria

Optimization candidates are evaluated using multiple metrics:

- Profit Factor
- Net Profit
- Maximum Drawdown
- Recovery Factor
- Number of Trades
- Win Rate
- Annual performance
- Monthly consistency
- Parameter stability
- Out-of-sample performance

The highest Net Profit is **not automatically considered the best configuration**.

---

# 📈 Performance Evaluation

The project evaluates the strategy against the target criteria specified by the assignment.

| Metric | Target |
|---|---:|
| Average Monthly Return | 3–5% |
| Annual Return | 50–70% |
| Maximum Drawdown | ≤ 25–30% |
| Loss Months | ≤ 6 months per year |

These values are treated as **evaluation criteria rather than guaranteed performance**.

Actual performance is reported only after completing the corresponding MT5 backtest.

---

# 📅 Monthly & Annual Analysis

Performance is evaluated at both monthly and annual levels.

The analysis includes:

- Monthly return.
- Number of profitable months.
- Number of loss months.
- Annual return.
- Maximum drawdown.
- Profit Factor.
- Total trades.
- Win rate.
- Equity progression.
- Performance consistency.

The monthly analysis is particularly important for verifying the requirement that no year contains more than six loss months.

---

# 🔬 Reproducibility

To reproduce the experiment:

1. Install MetaTrader 5.
2. Connect to the designated Exness account/server.
3. Verify the exact symbol names available in Market Watch.
4. Copy the EA modules into the MT5 data directory.
5. Compile `DiayuIndustrialEA.mq5` using MetaEditor.
6. Open Strategy Tester.
7. Select the required instrument.
8. Select H1 timeframe.
9. Select **Every tick based on real ticks**.
10. Set the seven-year testing period.
11. Run the baseline test.
12. Perform optimization using the documented parameter ranges.
13. Freeze the selected parameters.
14. Perform out-of-sample validation.
15. Run the final tests across the 10 instruments.
16. Save Strategy Tester reports and screenshots.
17. Record the results in the repository.
18. Run the result validation tools.

---

# 📁 Repository Structure

```text
├── MQL5/
│   ├── Include/
│   └── Experts/
│
├── config/
│   ├── instruments.csv
│   └── test_matrix.csv
│
├── optimization/
│   ├── baseline/
│   ├── parameter-ranges/
│   └── selected/
│
├── backtest/
│   ├── reports/
│   ├── screenshots/
│   └── results/
│
├── analysis/
│   ├── monthly/
│   └── annual/
│
├── tests/
├── docs/
├── report/
└── tools/
```

---

# 📊 Backtest Results

**Status: 🚧 In Progress**

Results are populated progressively using actual MetaTrader 5 Strategy Tester outputs.

| Instrument | Net Profit | Profit Factor | Max DD | Trades | History Quality | Status |
|---|---:|---:|---:|---:|---:|---|
| EURUSD | — | — | — | — | 100%* | Validation |
| USDJPY | — | — | — | — | — | Pending |
| GBPUSD | — | — | — | — | — | Pending |
| XAUUSD | — | — | — | — | — | Pending |
| XAGUSD | — | — | — | — | — | Pending |
| US30 | — | — | — | — | — | Pending |
| JP225 | — | — | — | — | — | Pending |
| BTCUSD | — | — | — | — | — | Pending |
| ETHUSD | — | — | — | — | — | Pending |
| USOIL | — | — | — | — | — | Pending |

\* EURUSDm has reached **100% History Quality** in the current real-tick validation run. Final performance metrics remain subject to optimization and validation.

---

# ⚠️ Result Integrity

This project follows a strict result-integrity principle:

> **No performance number is considered valid unless it originates from an actual Strategy Tester run.**

Therefore, this repository does not use:

- Fabricated returns.
- Fabricated modeling quality.
- Artificially reduced drawdown.
- Fabricated optimization results.
- Unverified performance claims.

Tester reports, screenshots, parameter files, and processed result tables should be retained as supporting evidence.

---

# 📚 Documentation

Additional project documentation:

- [`docs/METHODOLOGY.md`](docs/METHODOLOGY.md)
- [`docs/OPTIMIZATION.md`](docs/OPTIMIZATION.md)
- [`docs/EXNESS_MT5_SETUP.md`](docs/EXNESS_MT5_SETUP.md)
- [`tests/README.md`](tests/README.md)
- [`SUBMISSION_CHECKLIST.md`](SUBMISSION_CHECKLIST.md)

---

# 🧰 Tools

The repository includes supporting tools for result validation and analysis.

Example:

```bash
python tools/validate_results.py
```

The validator can be used to inspect monthly loss counts and identify years that exceed the six-loss-month criterion.

---

# 👤 Project Information

**Project:** Industrial-Grade Multi-Asset EA  
**Platform:** MetaTrader 5  
**Broker:** Exness  
**Primary Timeframe:** H1  
**Testing Model:** Every tick based on real ticks  
**Author:** Diayu  
**Year:** 2026

---

# 🚧 Project Status

**Development & Backtesting**

Current development stages:

- [x] Modular EA architecture
- [x] Risk management framework
- [x] Multi-asset configuration
- [x] Backtest framework
- [x] Real-tick testing configuration
- [x] EURUSDm 7-year history validation
- [x] EURUSDm 100% History Quality validation
- [ ] Baseline optimization
- [ ] Final parameter selection
- [ ] Out-of-sample validation
- [ ] 10-instrument final backtest
- [ ] Monthly performance analysis
- [ ] Annual performance analysis
- [ ] Final report

---

## 📌 Disclaimer

This project is developed for academic and research purposes. Historical backtest performance does not guarantee future trading performance. All performance claims must be supported by reproducible Strategy Tester results.
