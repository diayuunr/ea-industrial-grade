//+------------------------------------------------------------------+
//| IndustrialTrendEA.mq5                                            |
//| Multi-asset trend-following EA - no Martingale/Grid/HFT          |
//| Baseline design: EMA trend + breakout + ADX + ATR risk control   |
//+------------------------------------------------------------------+
#property strict
#property version   "1.00"
#property description "Industrial-grade baseline EA: trend breakout, volatility sizing, hard risk limits."

#include <Trade/Trade.mqh>

CTrade trade;

//--- Minimal user inputs
input ulong  MagicNumber        = 26092301;
input double RiskPerTradePct    = 0.50;   // risk per trade (% equity)
input double MaxDrawdownPct     = 25.0;   // hard equity drawdown stop
input int    TrendEMA           = 200;    // trend filter
input int    BreakoutBars       = 20;     // breakout lookback
input int    ATRPeriod          = 14;     // volatility period
input double MinADX             = 20.0;   // minimum trend strength
input double RiskReward         = 2.50;   // TP = SL x RR

//--- Internal safety constants (kept out of Inputs to reduce clutter)
#define MAX_DAILY_LOSS_PCT 2.0
#define MAX_EXPOSURE_MULT  1.0
#define SL_ATR_MULT        2.0
#define BE_ATR_MULT        1.0
#define TRAIL_ATR_MULT     1.5
#define DEVIATION_POINTS   20

int hEMA = INVALID_HANDLE;
int hATR = INVALID_HANDLE;
int hADX = INVALID_HANDLE;

datetime lastBarTime = 0;
double initialBalance = 0.0;
double peakEquity = 0.0;
int dayKey = -1;
double dayStartEquity = 0.0;
bool hardStop = false;

//+------------------------------------------------------------------+
//| Utility                                                           |
//+------------------------------------------------------------------+
int CurrentDayKey()
{
   MqlDateTime t;
   TimeToStruct(TimeCurrent(), t);
   return t.year*10000 + t.mon*100 + t.day;
}

void ResetDailyEquity()
{
   int k = CurrentDayKey();
   if(k != dayKey)
   {
      dayKey = k;
      dayStartEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   }
}

bool DailyLossExceeded()
{
   ResetDailyEquity();
   if(dayStartEquity <= 0.0) return false;

   double eq = AccountInfoDouble(ACCOUNT_EQUITY);
   double lossPct = (dayStartEquity - eq) / dayStartEquity * 100.0;
   return (lossPct >= MAX_DAILY_LOSS_PCT);
}

bool MaxDrawdownExceeded()
{
   double eq = AccountInfoDouble(ACCOUNT_EQUITY);

   if(initialBalance <= 0.0)
      initialBalance = eq;

   if(peakEquity <= 0.0)
      peakEquity = eq;

   if(eq > peakEquity)
      peakEquity = eq;

   double ddFromPeak = (peakEquity - eq) / peakEquity * 100.0;
   double ddFromInitial = (initialBalance - eq) / initialBalance * 100.0;

   if(ddFromPeak >= MaxDrawdownPct || ddFromInitial >= MaxDrawdownPct)
      return true;

   return false;
}

bool IsNewBar()
{
   datetime t = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(t == 0) return false;

   if(t != lastBarTime)
   {
      lastBarTime = t;
      return true;
   }
   return false;
}

bool HasOurPosition()
{
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;

      if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
         (ulong)PositionGetInteger(POSITION_MAGIC) == MagicNumber)
         return true;
   }
   return false;
}

double NormalizeVolume(double volume)
{
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(step <= 0.0) return 0.0;

   volume = MathMin(volume, maxLot);
   volume = MathFloor(volume / step) * step;

   if(volume < minLot)
      return 0.0;

   int digits = 0;
   double s = step;
   while(s < 1.0 && digits < 8)
   {
      s *= 10.0;
      digits++;
   }

   return NormalizeDouble(volume, digits);
}

double RiskLot(double entry, double stop)
{
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double riskMoney = equity * RiskPerTradePct / 100.0;

   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);

   if(equity <= 0.0 || riskMoney <= 0.0 || tickSize <= 0.0 || tickValue <= 0.0)
      return 0.0;

   double stopDistance = MathAbs(entry - stop);
   if(stopDistance <= 0.0) return 0.0;

   double lossPerLot = (stopDistance / tickSize) * tickValue;
   if(lossPerLot <= 0.0) return 0.0;

   double lotByRisk = riskMoney / lossPerLot;

   // Hard exposure cap: notional value <= 1x equity.
   // This prevents the EA from deliberately using broker leverage.
   double contractSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   if(contractSize > 0.0 && entry > 0.0)
   {
      double maxNotional = equity * MAX_EXPOSURE_MULT;
      double lotByExposure = maxNotional / (entry * contractSize);
      lotByRisk = MathMin(lotByRisk, lotByExposure);
   }

   return NormalizeVolume(lotByRisk);
}

bool MarginOK(ENUM_ORDER_TYPE type, double volume, double price)
{
   double margin = 0.0;
   if(!OrderCalcMargin(type, _Symbol, volume, price, margin))
      return false;

   return margin <= AccountInfoDouble(ACCOUNT_MARGIN_FREE) * 0.90;
}

bool GetIndicators(double &ema, double &atr, double &adx)
{
   double bEMA[2], bATR[2], bADX[2];

   ArraySetAsSeries(bEMA, true);
   ArraySetAsSeries(bATR, true);
   ArraySetAsSeries(bADX, true);

   if(CopyBuffer(hEMA, 0, 0, 2, bEMA) < 2) return false;
   if(CopyBuffer(hATR, 0, 0, 2, bATR) < 2) return false;
   if(CopyBuffer(hADX, 0, 0, 2, bADX) < 2) return false;

   // Use the last fully closed candle.
   ema = bEMA[1];
   atr = bATR[1];
   adx = bADX[1];

   return (ema > 0.0 && atr > 0.0 && adx >= 0.0);
}

bool GetBreakoutSignal(bool &buy, bool &sell)
{
   buy = false;
   sell = false;

   if(Bars(_Symbol, PERIOD_CURRENT) < TrendEMA + BreakoutBars + 20)
      return false;

   double ema, atr, adx;
   if(!GetIndicators(ema, atr, adx))
      return false;

   if(adx < MinADX)
      return true; // valid data, but no signal

   double close1 = iClose(_Symbol, PERIOD_CURRENT, 1);
   double open1  = iOpen(_Symbol, PERIOD_CURRENT, 1);

   double highest = -DBL_MAX;
   double lowest  = DBL_MAX;

   // Compare the last closed candle against the previous N candles,
   // excluding candle #1 from the breakout range.
   for(int i = 2; i < BreakoutBars + 2; i++)
   {
      highest = MathMax(highest, iHigh(_Symbol, PERIOD_CURRENT, i));
      lowest  = MathMin(lowest, iLow(_Symbol, PERIOD_CURRENT, i));
   }

   if(close1 > ema && close1 > highest && close1 > open1)
      buy = true;

   if(close1 < ema && close1 < lowest && close1 < open1)
      sell = true;

   return true;
}

void ManagePosition()
{
   double atr;
   double ema, adx;
   if(!GetIndicators(ema, atr, adx))
      return;

   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;

      if(PositionGetString(POSITION_SYMBOL) != _Symbol ||
         (ulong)PositionGetInteger(POSITION_MAGIC) != MagicNumber)
         continue;

      long type = PositionGetInteger(POSITION_TYPE);
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl = PositionGetDouble(POSITION_SL);
      double tp = PositionGetDouble(POSITION_TP);

      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

      double newSL = sl;

      if(type == POSITION_TYPE_BUY)
      {
         double profitDistance = bid - openPrice;

         if(profitDistance >= atr * BE_ATR_MULT)
         {
            double be = openPrice;
            if(sl < be || sl == 0.0)
               newSL = be;
         }

         double trail = bid - atr * TRAIL_ATR_MULT;
         if(profitDistance >= atr * BE_ATR_MULT && trail > newSL)
            newSL = trail;

         if(newSL > 0.0 && newSL < bid)
         {
            if(sl == 0.0 || newSL > sl + _Point)
               trade.PositionModify(ticket, NormalizeDouble(newSL, _Digits), tp);
         }
      }
      else if(type == POSITION_TYPE_SELL)
      {
         double profitDistance = openPrice - ask;

         if(profitDistance >= atr * BE_ATR_MULT)
         {
            double be = openPrice;
            if(sl > be || sl == 0.0)
               newSL = be;
         }

         double trail = ask + atr * TRAIL_ATR_MULT;
         if(profitDistance >= atr * BE_ATR_MULT && (newSL == 0.0 || trail < newSL))
            newSL = trail;

         if(newSL > ask)
         {
            if(sl == 0.0 || newSL < sl - _Point)
               trade.PositionModify(ticket, NormalizeDouble(newSL, _Digits), tp);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Expert initialization                                             |
//+------------------------------------------------------------------+
int OnInit()
{
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(DEVIATION_POINTS);
   trade.SetTypeFillingBySymbol(_Symbol);

   hEMA = iMA(_Symbol, PERIOD_CURRENT, TrendEMA, 0, MODE_EMA, PRICE_CLOSE);
   hATR = iATR(_Symbol, PERIOD_CURRENT, ATRPeriod);
   hADX = iADX(_Symbol, PERIOD_CURRENT, 14);

   if(hEMA == INVALID_HANDLE || hATR == INVALID_HANDLE || hADX == INVALID_HANDLE)
      return INIT_FAILED;

   initialBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   peakEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   dayKey = CurrentDayKey();
   dayStartEquity = peakEquity;

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization                                           |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(hEMA != INVALID_HANDLE) IndicatorRelease(hEMA);
   if(hATR != INVALID_HANDLE) IndicatorRelease(hATR);
   if(hADX != INVALID_HANDLE) IndicatorRelease(hADX);
}

//+------------------------------------------------------------------+
//| Expert tick                                                       |
//+------------------------------------------------------------------+
void OnTick()
{
   // Always manage an existing position.
   ManagePosition();

   if(hardStop)
      return;

   if(MaxDrawdownExceeded())
   {
      hardStop = true;
      return;
   }

   if(DailyLossExceeded())
      return;

   // Only evaluate entries once per new bar.
   if(!IsNewBar())
      return;

   if(HasOurPosition())
      return;

   bool buy=false, sell=false;
   if(!GetBreakoutSignal(buy, sell))
      return;

   double ema, atr, adx;
   if(!GetIndicators(ema, atr, adx))
      return;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   if(ask <= 0.0 || bid <= 0.0 || atr <= 0.0)
      return;

   if(buy)
   {
      double sl = ask - atr * SL_ATR_MULT;
      double tp = ask + atr * SL_ATR_MULT * RiskReward;
      sl = NormalizeDouble(sl, _Digits);
      tp = NormalizeDouble(tp, _Digits);

      double lot = RiskLot(ask, sl);
      if(lot <= 0.0) return;
      if(!MarginOK(ORDER_TYPE_BUY, lot, ask)) return;

      trade.Buy(lot, _Symbol, 0.0, sl, tp, "IMAB BUY");
   }
   else if(sell)
   {
      double sl = bid + atr * SL_ATR_MULT;
      double tp = bid - atr * SL_ATR_MULT * RiskReward;
      sl = NormalizeDouble(sl, _Digits);
      tp = NormalizeDouble(tp, _Digits);

      double lot = RiskLot(bid, sl);
      if(lot <= 0.0) return;
      if(!MarginOK(ORDER_TYPE_SELL, lot, bid)) return;

      trade.Sell(lot, _Symbol, 0.0, sl, tp, "IMAB SELL");
   }
}
//+------------------------------------------------------------------+
