#property strict
#property version "1.00"
#property description "Diayu Industrial Grade: Trend + Breakout + ADX + ATR Risk"
#include <Trade/Trade.mqh>
#include "../Include/DiayuConfig.mqh"
#include "../Include/DiayuIndicators.mqh"
#include "../Include/DiayuRisk.mqh"
#include "../Include/DiayuExecution.mqh"
input ENUM_TIMEFRAMES InpTF=PERIOD_H1;
input int InpFastEMA=21;
input int InpSlowEMA=200;
input int InpADXPeriod=14;
input double InpMinADX=20.0;
input int InpATRPeriod=14;
input int InpBreakoutBars=20;
input double InpRiskPercent=0.50;
input double InpATRSL=2.20;
input double InpRR=1.80;
input double InpMaxDD=25.0;
input bool InpBreakEven=true;
input double InpBreakEvenR=1.0;
input bool InpTrailing=true;
input double InpTrailATR=2.0;
DiayuIndicators *ind=NULL; DiayuRisk *risk=NULL; DiayuExecution *exec=NULL; datetime lastBar=0;
bool NewBar(){datetime t=iTime(_Symbol,InpTF,0);if(t==0||t==lastBar)return false;lastBar=t;return true;}
bool OurPosition(){return PositionSelect(_Symbol)&&((long)PositionGetInteger(POSITION_MAGIC)==DiayuConfig::MAGIC);}
double HH(int n,int shift){double x=-DBL_MAX;for(int i=shift;i<shift+n;i++)x=MathMax(x,iHigh(_Symbol,InpTF,i));return x;}
double LL(int n,int shift){double x=DBL_MAX;for(int i=shift;i<shift+n;i++)x=MathMin(x,iLow(_Symbol,InpTF,i));return x;}
void Manage(){if(!OurPosition())return;double f,s,a,atr;if(!ind.Read(f,s,a,atr))return;long type=PositionGetInteger(POSITION_TYPE);double open=PositionGetDouble(POSITION_PRICE_OPEN),sl=PositionGetDouble(POSITION_SL),tp=PositionGetDouble(POSITION_TP);double px=(type==POSITION_TYPE_BUY?SymbolInfoDouble(_Symbol,SYMBOL_BID):SymbolInfoDouble(_Symbol,SYMBOL_ASK));double rd=MathAbs(open-sl);if(rd<=0)return;double r=(type==POSITION_TYPE_BUY?(px-open):(open-px))/rd;double ns=sl;if(InpBreakEven&&r>=InpBreakEvenR)ns=open;if(InpTrailing){if(type==POSITION_TYPE_BUY)ns=MathMax(ns,px-InpTrailATR*atr);else ns=(ns==0?px+InpTrailATR*atr:MathMin(ns,px+InpTrailATR*atr));}int d=(int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS);ns=NormalizeDouble(ns,d);if(type==POSITION_TYPE_BUY&&ns>sl&&ns<px)exec.Modify(_Symbol,ns,tp);if(type==POSITION_TYPE_SELL&&(sl==0||ns<sl)&&ns>px)exec.Modify(_Symbol,ns,tp);}
void Entry(){if(OurPosition()||!risk.DrawdownOK())return;double f,s,a,atr;if(!ind.Read(f,s,a,atr)||a<InpMinADX)return;double c=iClose(_Symbol,InpTF,1),up=HH(InpBreakoutBars,2),lo=LL(InpBreakoutBars,2);int d=(int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS);double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK),bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);if(f>s&&c>up){double sl=NormalizeDouble(ask-InpATRSL*atr,d),tp=NormalizeDouble(ask+(ask-sl)*InpRR,d),v=risk.Volume(_Symbol,ask,sl);if(v>0)exec.Buy(_Symbol,v,sl,tp);}else if(f<s&&c<lo){double sl=NormalizeDouble(bid+InpATRSL*atr,d),tp=NormalizeDouble(bid-(sl-bid)*InpRR,d),v=risk.Volume(_Symbol,bid,sl);if(v>0)exec.Sell(_Symbol,v,sl,tp);}}
int OnInit(){ind=new DiayuIndicators(_Symbol,InpTF,InpFastEMA,InpSlowEMA,InpADXPeriod,InpATRPeriod);risk=new DiayuRisk(InpRiskPercent,InpMaxDD);exec=new DiayuExecution();return(ind!=NULL&&risk!=NULL&&exec!=NULL)?INIT_SUCCEEDED:INIT_FAILED;}
void OnDeinit(const int reason){delete ind;delete risk;delete exec;}
void OnTick(){Manage();if(NewBar())Entry();}
