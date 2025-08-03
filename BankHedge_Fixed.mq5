//+------------------------------------------------------------------+
//|                                                BankHedge_Fixed.mq5 |
//|                                                   Bank Hedge EA |
//+------------------------------------------------------------------+
#property copyright "Bank Hedge"
#property version   "1.00"

#include <Trade\Trade.mqh>

input double Lots = 0.1;
input double StopLoss = 50;
input double TakeProfit = 100;
input int Magic = 555;

CTrade trade;

int OnInit()
{
   trade.SetExpertMagicNumber(Magic);
   Print("Bank Hedge Started");
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   Print("Bank Hedge Stopped");
}

void OnTick()
{
   // Strategy logic here
}