import csv
from collections import defaultdict
from pathlib import Path
R=Path(__file__).resolve().parents[1]
summary=R/'backtest/results/backtest_summary.csv'; monthly=R/'backtest/results/monthly_returns.csv'
symbols=[r['symbol'] for r in csv.DictReader(summary.open(encoding='utf-8'))]
d=defaultdict(list)
for r in csv.DictReader(monthly.open(encoding='utf-8')):
    if not r.get('symbol'): continue
    try: d[(r['symbol'],r['year'])].append(float(r['return_pct']))
    except: pass
print('DIAYU RESULT VALIDATOR')
for s in symbols:
    rows=[(y,v) for (sym,y),v in d.items() if sym==s]
    if not rows: print(f'{s}: PENDING'); continue
    worst=max(sum(x<0 for x in v) for y,v in rows)
    print(f'{s}: worst loss months/year = {worst} -> '+('PASS' if worst<=6 else 'FAIL'))
