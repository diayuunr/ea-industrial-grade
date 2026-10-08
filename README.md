# Industrial-Grade Multi-Asset EA

**MetaTrader 5 Expert Advisor | Multi-Asset System | Exness | Real-Tick Backtesting**

> A modular and risk-managed Expert Advisor project developed for the Sains Manajemen Industrial-Grade assignment.

---

## 📌 Project Overview

**Industrial-Grade Multi-Asset EA** is a modular Expert Advisor (EA) developed for MetaTrader 5 (MT5). The system is designed to operate across multiple asset classes using a systematic trend-following and breakout approach combined with volatility filtering and risk-based position sizing.

The project emphasizes not only trading performance, but also **software modularity, reproducibility, risk control, parameter optimization, and systematic backtest evaluation**.

The EA is designed to be tested using **Exness historical market data** and the MetaTrader 5 Strategy Tester with **Every tick based on real ticks**.

---

## 🎯 Project Objectives

The project aims to develop and evaluate an Expert Advisor that:

- Supports multiple asset classes.
- Uses a systematic and rule-based trading strategy.
- Applies risk-based position sizing.
- Implements predefined drawdown and loss controls.
- Avoids Martingale, Grid, and HFT mechanisms.
- Can be optimized and validated through a reproducible workflow.
- Can be evaluated over a seven-year historical period.
- Provides transparent monthly and annual performance analysis.

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
| Out-of-Sample Validation | Planned / Implemented |
| Monthly Analysis | Implemented |
| Annual Analysis | Implemented |

---

# 📊 Asset Universe

The system is evaluated across **10 instruments from 5 asset classes**.

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

The EA uses a combination of **trend identification, breakout confirmation, momentum filtering, and volatility-based trade management**.

### Signal Components

```text
Market Data
     │
     ▼
Trend Filter
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
