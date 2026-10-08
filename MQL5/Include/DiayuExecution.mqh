#property strict
#include <Trade/Trade.mqh>
class DiayuExecution { CTrade trade; public: DiayuExecution(){trade.SetExpertMagicNumber(26100801);trade.SetDeviationInPoints(20);} bool Buy(string s,double v,double sl,double tp){return trade.Buy(v,s,0,sl,tp,"DIAYU-LONG");} bool Sell(string s,double v,double sl,double tp){return trade.Sell(v,s,0,sl,tp,"DIAYU-SHORT");} bool Modify(string s,double sl,double tp){return trade.PositionModify(s,sl,tp);} };
