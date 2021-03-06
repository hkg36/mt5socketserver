//+------------------------------------------------------------------+
//|                                                socketconnect.mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#include "SocketClient.mqh"
int connectsocket=0;
string host="127.0.0.1";
uint port=8080;

class MySocketClient:public SocketClient{
public:
   void MySocketClient(string host,uint port):SocketClient(host,port){
   }
   virtual void onRecvMessage(uchar &buf[]){
      string rest=CharArrayToString(buf,0,ArraySize(buf),CP_UTF8);
      Print("read :",rest);
   }
};
      
MySocketClient sc(host,port);
int OnInit()
  {
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
datetime lasttime=0;
uint checkgap=10;
void OnTick()
  {
   datetime nowtime=TimeCurrent();
   if(nowtime-lasttime>checkgap)
   {
      onProcess();
      lasttime=nowtime;
   }
   sc.TickCheck();
  }
//+------------------------------------------------------------------+
string symbols[]={"XAUUSD","XAGUSD","USOUSD","UKOUSD"};
ENUM_TIMEFRAMES timeframes[]={PERIOD_M1,PERIOD_M5,PERIOD_M30,PERIOD_H1};
void onProcess(){
      int datacount=2;
      if(sc.isNewConnect){
         datacount=500;
         sc.isNewConnect=false;
      }
      for(int i=ArraySize(symbols)-1;i>=0;i--)
         for(int j=ArraySize(timeframes)-1;j>=0;j--)
         {
            string message=BuildHistoryString(symbols[i],timeframes[j],0,datacount);
            sc.SendString(message);
         }
}

string BuildHistoryString(string symbol,ENUM_TIMEFRAMES period,int start=0,int hist_count=1){
   datetime time[];
   double open[];
   double close[];
   double high[];
   double low[];
   CopyTime(symbol,period,start,hist_count,time);
   CopyOpen(symbol,period,start,hist_count,open);
   CopyClose(symbol,period,start,hist_count,close);
   CopyHigh(symbol,period,start,hist_count,high);
   CopyLow(symbol,period,start,hist_count,low);
   string message=StringFormat("%s,%d$",symbol,period);
   for(int i=hist_count-1;i>=0;i--){
      StringAdd(message,StringFormat("%d,%f,%f,%f,%f;",time[i],open[i],close[i],high[i],low[i]));
   }
   return message;
}