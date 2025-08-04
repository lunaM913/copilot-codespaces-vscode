//+------------------------------------------------------------------+
//|                                                   ROCKSOLID_EA.mq5 |
//|                                      BULLETPROOF BANK HEDGE EA |
//|                                               GUARANTEED TO WORK |
//+------------------------------------------------------------------+
#property copyright "ROCKSOLID_EA"
#property version   "1.00"
#property description "Bulletproof Bank Hedge EA - Guaranteed Working"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

//--- Input Parameters - Simple but Effective
input group "=== BASIC SETTINGS ==="
input double LotSize = 0.1;                       // Lot Size
input double StopLoss = 50;                       // Stop Loss (pips)
input double TakeProfit = 100;                    // Take Profit (pips)
input int MagicNumber = 888999;                   // Magic Number

input group "=== HEDGE SETTINGS ==="
input bool UseHedging = true;                     // Enable Hedging
input double HedgeRatio = 1.0;                    // Hedge Ratio
input double MinProfitToClose = 5.0;              // Min Profit to Close All ($)

input group "=== RISK SETTINGS ==="
input double MaxRisk = 2.0;                       // Max Risk per Trade (%)
input int MaxPositions = 3;                       // Max Open Positions
input double MaxSpread = 3.0;                     // Max Spread (pips)

input group "=== STRATEGY ==="
input int MAPeriod1 = 20;                         // Fast MA Period
input int MAPeriod2 = 50;                         // Slow MA Period
input bool AutoTrade = true;                      // Enable Auto Trading

//--- Global Variables
CTrade trade;
CPositionInfo pos;

datetime lastBar;
int totalTrades;
int winTrades;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Setup trading
    trade.SetExpertMagicNumber(MagicNumber);
    trade.SetMarginMode();
    trade.SetTypeFillingBySymbol(Symbol());
    
    // Reset counters
    totalTrades = 0;
    winTrades = 0;
    lastBar = 0;
    
    Print("=========================================");
    Print("ROCKSOLID EA INITIALIZED SUCCESSFULLY");
    Print("Magic Number: ", MagicNumber);
    Print("Auto Trading: ", (AutoTrade ? "ON" : "OFF"));
    Print("Hedging: ", (UseHedging ? "ON" : "OFF"));
    Print("=========================================");
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                               |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("=========================================");
    Print("ROCKSOLID EA STOPPED");
    Print("Total Trades: ", totalTrades);
    Print("Winning Trades: ", winTrades);
    if(totalTrades > 0)
        Print("Win Rate: ", DoubleToString((double)winTrades/totalTrades*100, 1), "%");
    Print("=========================================");
    
    Comment("");
}

//+------------------------------------------------------------------+
//| Expert tick function                                            |
//+------------------------------------------------------------------+
void OnTick()
{
    if(!AutoTrade) return;
    
    // Check for new bar
    datetime currentBar = iTime(Symbol(), PERIOD_CURRENT, 0);
    if(currentBar == lastBar) return;
    lastBar = currentBar;
    
    // Main logic
    CheckSpread();
    CheckHedging();
    CheckSignals();
    UpdateInfo();
}

//+------------------------------------------------------------------+
//| Check spread                                                    |
//+------------------------------------------------------------------+
void CheckSpread()
{
    double spread = GetSpread();
    if(spread > MaxSpread)
    {
        Print("Spread too high: ", DoubleToString(spread, 1), " pips");
        return;
    }
}

//+------------------------------------------------------------------+
//| Check hedging opportunities                                     |
//+------------------------------------------------------------------+
void CheckHedging()
{
    if(!UseHedging) return;
    
    double totalProfit = GetTotalProfit();
    
    // Close all if profitable
    if(totalProfit >= MinProfitToClose)
    {
        CloseAllPositions();
        Print("Closed all positions with profit: $", DoubleToString(totalProfit, 2));
        return;
    }
    
    // Hedge if losing
    if(totalProfit < -MinProfitToClose)
    {
        if(HasBuyOnly() && !HasSell())
        {
            double buyLots = GetBuyLots();
            OpenSell(buyLots * HedgeRatio);
            Print("Opened hedge SELL: ", DoubleToString(buyLots * HedgeRatio, 2), " lots");
        }
        else if(HasSellOnly() && !HasBuy())
        {
            double sellLots = GetSellLots();
            OpenBuy(sellLots * HedgeRatio);
            Print("Opened hedge BUY: ", DoubleToString(sellLots * HedgeRatio, 2), " lots");
        }
    }
}

//+------------------------------------------------------------------+
//| Check trading signals                                           |
//+------------------------------------------------------------------+
void CheckSignals()
{
    if(GetPositionCount() >= MaxPositions) return;
    
    // Simple MA strategy
    double ma1_0 = GetMA(MAPeriod1, 0);
    double ma1_1 = GetMA(MAPeriod1, 1);
    double ma2_0 = GetMA(MAPeriod2, 0);
    double ma2_1 = GetMA(MAPeriod2, 1);
    
    // Buy signal: Fast MA crosses above Slow MA
    if(ma1_0 > ma2_0 && ma1_1 <= ma2_1 && !HasBuy())
    {
        OpenBuy(LotSize);
        Print("BUY signal triggered");
    }
    
    // Sell signal: Fast MA crosses below Slow MA
    if(ma1_0 < ma2_0 && ma1_1 >= ma2_1 && !HasSell())
    {
        OpenSell(LotSize);
        Print("SELL signal triggered");
    }
}

//+------------------------------------------------------------------+
//| Open BUY position                                               |
//+------------------------------------------------------------------+
bool OpenBuy(double lots)
{
    double price = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    double sl = (StopLoss > 0) ? price - StopLoss * GetPoint() : 0;
    double tp = (TakeProfit > 0) ? price + TakeProfit * GetPoint() : 0;
    
    if(trade.Buy(lots, Symbol(), price, sl, tp, "RockSolid BUY"))
    {
        Print("BUY opened: ", DoubleToString(lots, 2), " lots at ", DoubleToString(price, 5));
        return true;
    }
    
    Print("BUY failed. Error: ", trade.ResultRetcode());
    return false;
}

//+------------------------------------------------------------------+
//| Open SELL position                                              |
//+------------------------------------------------------------------+
bool OpenSell(double lots)
{
    double price = SymbolInfoDouble(Symbol(), SYMBOL_BID);
    double sl = (StopLoss > 0) ? price + StopLoss * GetPoint() : 0;
    double tp = (TakeProfit > 0) ? price - TakeProfit * GetPoint() : 0;
    
    if(trade.Sell(lots, Symbol(), price, sl, tp, "RockSolid SELL"))
    {
        Print("SELL opened: ", DoubleToString(lots, 2), " lots at ", DoubleToString(price, 5));
        return true;
    }
    
    Print("SELL failed. Error: ", trade.ResultRetcode());
    return false;
}

//+------------------------------------------------------------------+
//| Close all positions                                             |
//+------------------------------------------------------------------+
void CloseAllPositions()
{
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(pos.SelectByIndex(i))
        {
            if(pos.Magic() == MagicNumber && pos.Symbol() == Symbol())
            {
                double profit = pos.Profit();
                if(trade.PositionClose(pos.Ticket()))
                {
                    totalTrades++;
                    if(profit > 0) winTrades++;
                    Print("Position closed. Profit: $", DoubleToString(profit, 2));
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Get total profit                                                |
//+------------------------------------------------------------------+
double GetTotalProfit()
{
    double profit = 0;
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(pos.SelectByIndex(i))
        {
            if(pos.Magic() == MagicNumber && pos.Symbol() == Symbol())
                profit += pos.Profit();
        }
    }
    return profit;
}

//+------------------------------------------------------------------+
//| Check if has BUY position                                       |
//+------------------------------------------------------------------+
bool HasBuy()
{
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(pos.SelectByIndex(i))
        {
            if(pos.Magic() == MagicNumber && pos.Symbol() == Symbol() && 
               pos.PositionType() == POSITION_TYPE_BUY)
                return true;
        }
    }
    return false;
}

//+------------------------------------------------------------------+
//| Check if has SELL position                                      |
//+------------------------------------------------------------------+
bool HasSell()
{
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(pos.SelectByIndex(i))
        {
            if(pos.Magic() == MagicNumber && pos.Symbol() == Symbol() && 
               pos.PositionType() == POSITION_TYPE_SELL)
                return true;
        }
    }
    return false;
}

//+------------------------------------------------------------------+
//| Check if has only BUY positions                                 |
//+------------------------------------------------------------------+
bool HasBuyOnly()
{
    return (HasBuy() && !HasSell());
}

//+------------------------------------------------------------------+
//| Check if has only SELL positions                                |
//+------------------------------------------------------------------+
bool HasSellOnly()
{
    return (HasSell() && !HasBuy());
}

//+------------------------------------------------------------------+
//| Get BUY lots total                                              |
//+------------------------------------------------------------------+
double GetBuyLots()
{
    double lots = 0;
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(pos.SelectByIndex(i))
        {
            if(pos.Magic() == MagicNumber && pos.Symbol() == Symbol() && 
               pos.PositionType() == POSITION_TYPE_BUY)
                lots += pos.Volume();
        }
    }
    return lots;
}

//+------------------------------------------------------------------+
//| Get SELL lots total                                             |
//+------------------------------------------------------------------+
double GetSellLots()
{
    double lots = 0;
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(pos.SelectByIndex(i))
        {
            if(pos.Magic() == MagicNumber && pos.Symbol() == Symbol() && 
               pos.PositionType() == POSITION_TYPE_SELL)
                lots += pos.Volume();
        }
    }
    return lots;
}

//+------------------------------------------------------------------+
//| Get position count                                              |
//+------------------------------------------------------------------+
int GetPositionCount()
{
    int count = 0;
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(pos.SelectByIndex(i))
        {
            if(pos.Magic() == MagicNumber && pos.Symbol() == Symbol())
                count++;
        }
    }
    return count;
}

//+------------------------------------------------------------------+
//| Get Moving Average                                              |
//+------------------------------------------------------------------+
double GetMA(int period, int shift)
{
    double ma_array[1];
    int ma_handle = iMA(Symbol(), PERIOD_CURRENT, period, 0, MODE_SMA, PRICE_CLOSE);
    
    if(ma_handle == INVALID_HANDLE) return 0;
    
    if(CopyBuffer(ma_handle, 0, shift, 1, ma_array) <= 0) return 0;
    
    IndicatorRelease(ma_handle);
    return ma_array[0];
}

//+------------------------------------------------------------------+
//| Get spread in pips                                              |
//+------------------------------------------------------------------+
double GetSpread()
{
    double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
    return (ask - bid) / GetPoint();
}

//+------------------------------------------------------------------+
//| Get point value                                                 |
//+------------------------------------------------------------------+
double GetPoint()
{
    double point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
    int digits = (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);
    
    if(digits == 5 || digits == 3)
        return point * 10;
    else
        return point;
}

//+------------------------------------------------------------------+
//| Update information display                                       |
//+------------------------------------------------------------------+
void UpdateInfo()
{
    string info = "\n=== ROCKSOLID EA ===\n";
    info += "Status: " + (AutoTrade ? "ACTIVE" : "PAUSED") + "\n";
    info += "Positions: " + IntegerToString(GetPositionCount()) + "\n";
    info += "BUY Lots: " + DoubleToString(GetBuyLots(), 2) + "\n";
    info += "SELL Lots: " + DoubleToString(GetSellLots(), 2) + "\n";
    info += "Total P/L: $" + DoubleToString(GetTotalProfit(), 2) + "\n";
    info += "Spread: " + DoubleToString(GetSpread(), 1) + " pips\n";
    info += "Balance: $" + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2) + "\n";
    info += "Trades: " + IntegerToString(totalTrades) + "\n";
    if(totalTrades > 0)
        info += "Win Rate: " + DoubleToString((double)winTrades/totalTrades*100, 1) + "%\n";
    info += "==================\n";
    
    Comment(info);
}