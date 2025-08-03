//+------------------------------------------------------------------+
//|                                           TriangularArbitrage_EA.mq5 |
//|                                                   Triangular Arbitrage EA |
//|                                               Expert Advisor for EUR/USD, GBP/USD, EUR/GBP |
//+------------------------------------------------------------------+
#property copyright   "Triangular Arbitrage EA"
#property version     "1.00"
#property description "Expert Advisor for triangular arbitrage opportunities with EUR/USD, GBP/USD, and EUR/GBP pairs"

//--- Include necessary libraries
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>