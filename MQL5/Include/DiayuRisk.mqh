#property strict
class DiayuRisk {
 double riskPct,maxDD;
public:
 DiayuRisk(double r,double dd){riskPct=r;maxDD=dd;}
 bool DrawdownOK(){double e=AccountInfoDouble(ACCOUNT_EQUITY),b=AccountInfoDouble(ACCOUNT_BALANCE);return b>0 && (b-e)/b*100.0<maxDD;}
 double Volume(string s,double entry,double stop){double eq=AccountInfoDouble(ACCOUNT_EQUITY),tv=SymbolInfoDouble(s,SYMBOL_TRADE_TICK_VALUE),ts=SymbolInfoDouble(s,SYMBOL_TRADE_TICK_SIZE);double dist=MathAbs(entry-stop);if(eq<=0||tv<=0||ts<=0||dist<=0)return 0;double loss=dist/ts*tv;if(loss<=0)return 0;double v=eq*(riskPct/100.0)/loss,vmin=SymbolInfoDouble(s,SYMBOL_VOLUME_MIN),vmax=SymbolInfoDouble(s,SYMBOL_VOLUME_MAX),step=SymbolInfoDouble(s,SYMBOL_VOLUME_STEP);if(step<=0)step=vmin;v=MathFloor(v/step)*step;return MathMax(vmin,MathMin(vmax,v));}
};
