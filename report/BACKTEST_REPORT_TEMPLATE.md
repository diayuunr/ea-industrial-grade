# Laporan Backtest & Optimasi — IndustrialTrendEA

## A. Identitas Proyek
- Nama EA: IndustrialTrendEA
- Platform: MetaTrader 5
- Broker/data source: Exness
- Model: Every tick based on real ticks
- Timeframe: H1
- Periode: [ISI SESUAI TANGGAL PENGUJIAN]
- Initial deposit: USD 10,000

## B. Strategi
Jelaskan EMA + breakout + ADX + ATR dan mekanisme position sizing serta proteksi drawdown.

## C. Instrumen
| No | Instrumen | Kelas | Profit | Return | Max DD | PF | Trade | Profit Months | Loss Months | Real-tick result | Status |
|---:|---|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| 1 | EURUSD | Forex | | | | | | | | | |
| 2 | USDJPY | Forex | | | | | | | | | |
| 3 | GBPUSD | Forex | | | | | | | | | |
| 4 | XAUUSD | Metal | | | | | | | | | |
| 5 | XAGUSD | Metal | | | | | | | | | |
| 6 | JP225 | Index | | | | | | | | | |
| 7 | US500 | Index | | | | | | | | | |
| 8 | BTCUSD | Crypto | | | | | | | | | |
| 9 | ETHUSD | Crypto | | | | | | | | | |
| 10 | USOIL | Energy | | | | | | | | | |

## D. Optimasi
Tuliskan parameter yang dioptimasi, rentang, objective/ranking, dan alasan pemilihan parameter final.

## E. Robustness
Bandingkan in-sample vs out-of-sample. Jelaskan apakah performa tetap stabil ketika parameter digeser sedikit.

## F. Monthly Performance
Lampirkan tabel profit/loss per bulan dan hitung jumlah bulan loss per tahun. Jangan menyatakan “tidak ada bulan loss > 6” tanpa tabel pendukung.

## G. Kesimpulan
Nyatakan secara eksplisit instrumen mana yang memenuhi seluruh target dan mana yang tidak. Target return adalah target tugas, bukan jaminan kinerja.

## H. Bukti
Lampirkan screenshot Strategy Tester, report MT5, parameter `.set`, dan grafik equity untuk setiap pengujian final.
