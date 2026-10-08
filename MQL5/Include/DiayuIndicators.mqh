#property strict
class DiayuIndicators {
 int hFast,hSlow,hADX,hATR; string sym; ENUM_TIMEFRAMES tf;
public:
 DiayuIndicators(string s,ENUM_TIMEFRAMES t,int fast,int slow,int adxP,int atrP){sym=s;tf=t;hFast=iMA(s,t,fast,0,MODE_EMA,PRICE_CLOSE);hSlow=iMA(s,t,slow,0,MODE_EMA,PRICE_CLOSE);hADX=iADX(s,t,adxP);hATR=iATR(s,t,atrP);}
 ~DiayuIndicators(){if(hFast!=INVALID_HANDLE)IndicatorRelease(hFast);if(hSlow!=INVALID_HANDLE)IndicatorRelease(hSlow);if(hADX!=INVALID_HANDLE)IndicatorRelease(hADX);if(hATR!=INVALID_HANDLE)IndicatorRelease(hATR);}
 bool Read(double &fast,double &slow,double &adx,double &atr){double a[1],b[1],c[1],d[1];if(CopyBuffer(hFast,0,1,1,a)!=1)return false;if(CopyBuffer(hSlow,0,1,1,b)!=1)return false;if(CopyBuffer(hADX,0,1,1,c)!=1)return false;if(CopyBuffer(hATR,0,1,1,d)!=1)return false;fast=a[0];slow=b[0];adx=c[0];atr=d[0];return atr>0;}
};
