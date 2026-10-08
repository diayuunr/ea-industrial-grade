//+------------------------------------------------------------------+
//| IndustrialTrendEA.mq5                                            |
//| Industrial-grade trend-following Expert Advisor                  |
//| Design constraints: NO Martingale / NO Grid / NO HFT             |
//| Strategy: EMA trend + Donchian breakout + ADX + ATR risk control |
//+------------------------------------------------------------------+
#property strict
#property version   "2.00"
#property description "Industrial-grade multi-asset trend EA for MT5 backtesting."

#include <Trade/Trade.mqh>
CTrade trade;

//---------------------------- Inputs -------------------------------
input group "Identity"
input ulong  InpMagicNumber       = 20261008;
input string InpStrategyName      = "IndustrialTrendEA";

input group "Signal Engine"
input ENUM_TIMEFRAMES InpTF       = PERIOD_H1;
input int    InpTrendEMA           = 200;
input int    InpBreakoutBars       = 20;
input int    InpADXPeriod          = 14;
input double InpMinADX             = 20.0;

input group "Risk Management"
input double InpRiskPerTradePct   = 0.50;
input double InpMaxDrawdownPct     = 25.0;
input double InpMaxDailyLossPct    = 2.0;
input double InpATRSLMultiplier    = 2.0;
input double InpRiskReward         = 2.5;
input double InpMaxSpreadPoints    = 0.0; // 0 = disabled; set per symbol if desired
input int    InpDeviationPoints    = 20;

input group "Position Management"
input bool   InpUseBreakEven       = true;
input double InpBreakEvenATR       = 1.0;
input bool   InpUseTrailing        = true;
input double InpTrailingATR        = 1.5;
input bool   InpOnePositionOnly    = true;

//--------------------------- Handles --------------------------------
int hEMA = INVALID_HANDLE;
int hATR = INVALID_HANDLE;
int hADX = INVALID_HANDLE;
datetime lastBar = 0;
double initialEquity = 0.0;
double peakEquity = 0.0;
double dayStartEquity = 0.0;
int dayKey = -1;
bool hardStop = false;

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
   return ((dayStartEquity-eq)/dayStartEquity*100.0 >= InpMaxDailyLossPct);
}

bool MaxDrawdownExceeded()
{
   double eq = AccountInfoDouble(ACCOUNT_EQUITY);
   if(eq > peakEquity) peakEquity = eq;
   if(peakEquity <= 0.0) return false;
   return ((peakEquity-eq)/peakEquity*100.0 >= InpMaxDrawdownPct);
}

bool NewBar()
{
   datetime t = iTime(_Symbol, InpTF, 0);
   if(t == 0 || t == lastBar) return false;
   lastBar = t;
   return true;
}

bool SpreadOK()
{
   if(InpMaxSpreadPoints <= 0.0) return true;
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(point <= 0.0) return false;
   return ((ask-bid)/point <= InpMaxSpreadPoints);
}

bool HasOurPosition()
{
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
         (ulong)PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
         return true;
   }
   return false;
}

// Return ATR value on closed candle.
double GetATR()
{
   double b[2];
   ArraySetAsSeries(b,true);
   if(CopyBuffer(hATR,0,1,1,b) != 1) return 0.0;
   return b[0];
}

bool GetSignal(int &direction)
{
   direction = 0;
   if(Bars(_Symbol,InpTF) < InpTrendEMA+InpBreakoutBars+50) return false;

   double ema[2], adx[2];
   ArraySetAsSeries(ema,true);
   ArraySetAsSeries(adx,true);
   if(CopyBuffer(hEMA,0,1,1,ema) != 1) return false;
   if(CopyBuffer(hADX,0,1,1,adx) != 1) return false;

   double close1 = iClose(_Symbol,InpTF,1);
   double high1  = iHigh(_Symbol,InpTF,1);
   double low1   = iLow(_Symbol,InpTF,1);
   if(close1 <= 0.0) return false;

   double priorHigh = -DBL_MAX;
   double priorLow  = DBL_MAX;
   for(int i=2;i<InpBreakoutBars+2;i++)
   {
      priorHigh = MathMax(priorHigh,iHigh(_Symbol,InpTF,i));
      priorLow  = MathMin(priorLow,iLow(_Symbol,InpTF,i));
   }

   if(adx[0] < InpMinADX) return true;
   if(close1 > ema[0] && high1 > priorHigh) direction = 1;
   if(close1 < ema[0] && low1 < priorLow) direction = -1;
   return true;
}

int VolumeDigits()
{
   double step = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   int d=0;
   while(step < 1.0 && d < 8) { step*=10.0; d++; }
   return d;
}

double NormalizeVolume(double lots)
{
   double vmin = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double vmax = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   double step = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   if(step <= 0.0) return 0.0;
   lots = MathFloor(lots/step)*step;
   lots = MathMax(vmin,MathMin(vmax,lots));
   return NormalizeDouble(lots,VolumeDigits());
}

double LotsForRisk(double entry,double sl)
{
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double riskMoney = equity * InpRiskPerTradePct/100.0;
   double tickSize = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE_LOSS);
   if(tickValue <= 0.0) tickValue = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
   if(tickSize <= 0.0 || tickValue <= 0.0 || riskMoney <= 0.0) return 0.0;
   double lossPerLot = MathAbs(entry-sl)/tickSize*tickValue;
   if(lossPerLot <= 0.0) return 0.0;
   return NormalizeVolume(riskMoney/lossPerLot);
}

void OpenTrade(int direction)
{
   if(direction == 0 || hardStop || DailyLossExceeded() || MaxDrawdownExceeded()) return;
   if(!SpreadOK()) return;
   if(InpOnePositionOnly && HasOurPosition()) return;

   double atr = GetATR();
   if(atr <= 0.0) return;

   double point = SymbolInfoDouble(_Symbol,SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS);
   double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double entry = direction > 0 ? ask : bid;
   double slDist = atr * InpATRSLMultiplier;
   double tpDist = slDist * InpRiskReward;
   double sl = direction > 0 ? entry-slDist : entry+slDist;
   double tp = direction > 0 ? entry+tpDist : entry-tpDist;
   sl = NormalizeDouble(sl,digits);
   tp = NormalizeDouble(tp,digits);

   double lots = LotsForRisk(entry,sl);
   if(lots <= 0.0) return;

   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(InpDeviationPoints);
   trade.SetTypeFillingBySymbol(_Symbol);

   bool ok=false;
   string comment = InpStrategyName + " | " + _Symbol;
   if(direction > 0) ok = trade.Buy(lots,_Symbol,0.0,sl,tp,comment);
   else              ok = trade.Sell(lots,_Symbol,0.0,sl,tp,comment);
   if(!ok) Print("Order failed: ",trade.ResultRetcodeDescription());
}

void ManagePosition()
{
   if(!HasOurPosition()) return;
   double atr = GetATR();
   if(atr <= 0.0) return;
   double point = SymbolInfoDouble(_Symbol,SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS);

   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol ||
         (ulong)PositionGetInteger(POSITION_MAGIC)!=InpMagicNumber) continue;

      long type = PositionGetInteger(POSITION_TYPE);
      double open = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl = PositionGetDouble(POSITION_SL);
      double tp = PositionGetDouble(POSITION_TP);
      double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
      double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      double price = type==POSITION_TYPE_BUY ? bid : ask;
      double profitDist = type==POSITION_TYPE_BUY ? price-open : open-price;
      double newSL = sl;

      if(InpUseBreakEven && profitDist >= atr*InpBreakEvenATR)
      {
         if(type==POSITION_TYPE_BUY && (sl < open || sl==0.0)) newSL=open;
         if(type==POSITION_TYPE_SELL && (sl > open || sl==0.0)) newSL=open;
      }
      if(InpUseTrailing && profitDist > atr*InpTrailingATR)
      {
         double trail = type==POSITION_TYPE_BUY ? price-atr*InpTrailingATR : price+atr*InpTrailingATR;
         if(type==POSITION_TYPE_BUY) newSL=MathMax(newSL,trail);
         else if(newSL==0.0) newSL=trail;
         else newSL=MathMin(newSL,trail);
      }
      newSL=NormalizeDouble(newSL,digits);
      if(newSL>0.0 && MathAbs(newSL-sl)>point)
         trade.PositionModify(ticket,newSL,tp);
   }
}

//+------------------------------------------------------------------+
int OnInit()
{
   hEMA = iMA(_Symbol,InpTF,InpTrendEMA,0,MODE_EMA,PRICE_CLOSE);
   hATR = iATR(_Symbol,InpTF,14);
   hADX = iADX(_Symbol,InpTF,InpADXPeriod);
   if(hEMA==INVALID_HANDLE || hATR==INVALID_HANDLE || hADX==INVALID_HANDLE)
   {
      Print("Indicator initialization failed.");
      return INIT_FAILED;
   }
   initialEquity=AccountInfoDouble(ACCOUNT_EQUITY);
   peakEquity=initialEquity;
   ResetDailyEquity();
   trade.SetExpertMagicNumber(InpMagicNumber);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   if(hEMA!=INVALID_HANDLE) IndicatorRelease(hEMA);
   if(hATR!=INVALID_HANDLE) IndicatorRelease(hATR);
   if(hADX!=INVALID_HANDLE) IndicatorRelease(hADX);
}

void OnTick()
{
   ResetDailyEquity();
   if(MaxDrawdownExceeded()) hardStop=true;
   if(DailyLossExceeded()) return;
   ManagePosition();
   if(hardStop) return;
   if(!NewBar()) return; // deliberately low-frequency: one decision per bar
   int direction=0;
   if(GetSignal(direction)) OpenTrade(direction);
}
//+------------------------------------------------------------------+
