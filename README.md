# Diayu Industrial-Grade Multi-Asset EA

Proyek Sains Manajemen — Expert Advisor MetaTrader 5 dengan arsitektur modular, risk management, optimization workflow, dan audit backtest.

## Target Tugas
- 10 instrumen lintas Forex, Logam, Index, Crypto, Energi
- Exness
- 7 tahun pengujian
- Every tick based on real ticks
- Tidak menggunakan Martingale, Grid, atau HFT
- Risk-based sizing dan pembatasan drawdown
- Target evaluasi: 3–5%/bulan, 50–70%/tahun, max DD 25–30%, dan <=6 bulan loss/tahun

> Angka performa dan modeling quality hanya boleh diisi dari Strategy Tester MT5 yang benar-benar dijalankan.

## Struktur
```text
MQL5/Include/      modul konfigurasi, indikator, risk, execution
MQL5/Experts/      EA utama
config/            matriks instrumen dan pengujian
optimization/      baseline, ranges, parameter final
backtest/          report, screenshot, hasil CSV
analysis/          analisis bulanan dan tahunan
tests/             checklist verifikasi
docs/              metodologi dan reproduksibilitas
report/            laporan final
tools/             validator hasil
```

## Instrumen
EURUSD, USDJPY, GBPUSD, XAUUSD, XAGUSD, US30, JP225, BTCUSD, ETHUSD, USOIL.

## Instalasi
Salin `MQL5/Include/*.mqh` ke folder Include MT5 dan `MQL5/Experts/DiayuIndustrialEA.mq5` ke Experts. Compile dengan MetaEditor F7.

## Backtest
Gunakan Strategy Tester MT5, H1, periode tugas 7 tahun, Exness, dan **Every tick based on real ticks**. Simpan report dan screenshot. Verifikasi nama simbol pada Market Watch karena suffix Exness dapat berbeda.

## Optimization
Optimasi tidak memilih Net Profit saja. Pertimbangkan Profit Factor, Max Drawdown, Recovery Factor, jumlah trade, kestabilan antar-subperiode, dan out-of-sample validation.
