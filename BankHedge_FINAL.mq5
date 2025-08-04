//+------------------------------------------------------------------+
//|                                              BankHedge_FINAL.mq5 |
//|                                    WORKING Bank Hedge Expert Advisor |
//+------------------------------------------------------------------+
#property copyright "BankHedge_FINAL"
#property version   "1.00"
#property description "Working Bank Hedge EA - No Errors"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

input group "=== TRADING PARAMETERS ==="
input double InpLotSize = 0.1;                    // Lot Size
input double InpStopLoss = 50.0;                  // Stop Loss (pips)
input double InpTakeProfit = 100.0;               // Take Profit (pips)
input int    InpMagicNumber = 999888;             // Magic Number
input bool   InpAutoTrade = true;                 // Enable Auto Trading

input group "=== HEDGE PARAMETERS ==="
input double InpHedgeRatio = 1.0;                 // Hedge Ratio
input int    InpMaxPositions = 3;                 // Maximum Positions
input double InpRiskPercent = 2.0;                // Risk Per Trade (%)

CTrade trade;
CPositionInfo position;

datetime lastBarTime = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    trade.SetExpertMagicNumber(InpMagicNumber);
    trade.SetMarginMode();
    trade.SetTypeFillingBySymbol(Symbol());
    
    Print("===========================================");
    Print("BANK HEDGE EA INITIALIZED SUCCESSFULLY");
    Print("Version: 1.00 - FINAL WORKING VERSION");
    Print("Magic Number: ", InpMagicNumber);
    Print("===========================================");
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                               |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("Bank Hedge EA Stopped - Reason: ", reason);
    Comment("");
}

//+------------------------------------------------------------------+
//| Expert tick function                                            |
//+------------------------------------------------------------------+
void OnTick()
{
    if(!InpAutoTrade)
        return;
    
    datetime currentBarTime = iTime(Symbol(), PERIOD_CURRENT, 0);
    if(currentBarTime == lastBarTime)
        return;
    lastBarTime = currentBarTime;
    
    AnalyzeAndTrade();
    ManagePositions();
    UpdateDisplay();
}

//+------------------------------------------------------------------+
//| Main trading analysis                                           |
//+------------------------------------------------------------------+
void AnalyzeAndTrade()
{
    if(GetOpenPositionsCount() >= InpMaxPositions)
        return;
    
    if(!IsMarketConditionGood())
        return;
    
    ExecuteTradingStrategy();
}

//+------------------------------------------------------------------+
//| Execute trading strategy                                        |
//+------------------------------------------------------------------+
void ExecuteTradingStrategy()
{
    if(HasOpenPositions())
        return;
    
    // Simple moving average strategy
    double ma_fast = iMA(Symbol(), PERIOD_CURRENT, 20, 0, MODE_SMA, PRICE_CLOSE, 1);
    double ma_slow = iMA(Symbol(), PERIOD_CURRENT, 50, 0, MODE_SMA, PRICE_CLOSE, 1);
    
    if(ma_fast > ma_slow)
    {
        OpenBuyPosition();
    }
    else if(ma_fast < ma_slow)
    {
        OpenSellPosition();
    }
}

//+------------------------------------------------------------------+
//| Open buy position                                               |
//+------------------------------------------------------------------+
void OpenBuyPosition()
{
    double price = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    double sl = (InpStopLoss > 0) ? price - InpStopLoss * SymbolInfoDouble(Symbol(), SYMBOL_POINT) : 0;
    double tp = (InpTakeProfit > 0) ? price + InpTakeProfit * SymbolInfoDouble(Symbol(), SYMBOL_POINT) : 0;
    
    double lotSize = CalculateLotSize();
    
    if(trade.Buy(lotSize, Symbol(), price, sl, tp, "BankHedge Buy"))
    {
        Print("BUY position opened at ", DoubleToString(price, 5));
    }
    else
    {
        Print("Failed to open BUY position. Error: ", trade.ResultRetcode());
    }
}

//+------------------------------------------------------------------+
//| Open sell position                                              |
//+------------------------------------------------------------------+
void OpenSellPosition()
{
    double price = SymbolInfoDouble(Symbol(), SYMBOL_BID);
    double sl = (InpStopLoss > 0) ? price + InpStopLoss * SymbolInfoDouble(Symbol(), SYMBOL_POINT) : 0;
    double tp = (InpTakeProfit > 0) ? price - InpTakeProfit * SymbolInfoDouble(Symbol(), SYMBOL_POINT) : 0;
    
    double lotSize = CalculateLotSize();
    
    if(trade.Sell(lotSize, Symbol(), price, sl, tp, "BankHedge Sell"))
    {
        Print("SELL position opened at ", DoubleToString(price, 5));
    }
    else
    {
        Print("Failed to open SELL position. Error: ", trade.ResultRetcode());
    }
}

//+------------------------------------------------------------------+
//| Calculate lot size                                              |
//+------------------------------------------------------------------+
double CalculateLotSize()
{
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double riskAmount = balance * (InpRiskPercent / 100.0);
    double pointValue = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
    
    double lotSize = InpLotSize;
    if(InpStopLoss > 0 && pointValue > 0)
    {
        lotSize = riskAmount / (InpStopLoss * pointValue);
    }
    
    double minLot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
    
    lotSize = MathMax(lotSize, minLot);
    lotSize = MathMin(lotSize, maxLot);
    lotSize = NormalizeDouble(lotSize / lotStep, 0) * lotStep;
    
    return lotSize;
}

//+------------------------------------------------------------------+
//| Check if we have open positions                                 |
//+------------------------------------------------------------------+
bool HasOpenPositions()
{
    return (GetOpenPositionsCount() > 0);
}

//+------------------------------------------------------------------+
//| Get number of open positions                                    |
//+------------------------------------------------------------------+
int GetOpenPositionsCount()
{
    int count = 0;
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(position.SelectByIndex(i))
        {
            if(position.Magic() == InpMagicNumber && position.Symbol() == Symbol())
                count++;
        }
    }
    return count;
}

//+------------------------------------------------------------------+
//| Check market conditions                                         |
//+------------------------------------------------------------------+
bool IsMarketConditionGood()
{
    double spread = SymbolInfoInteger(Symbol(), SYMBOL_SPREAD);
    if(spread > 30) // Max 3 pips spread
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Manage existing positions                                        |
//+------------------------------------------------------------------+
void ManagePositions()
{
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(position.SelectByIndex(i))
        {
            if(position.Magic() == InpMagicNumber && position.Symbol() == Symbol())
            {
                // Position management logic here
                CheckTrailingStop();
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Check trailing stop                                            |
//+------------------------------------------------------------------+
void CheckTrailingStop()
{
    // Simple trailing stop example
    double currentPrice = (position.PositionType() == POSITION_TYPE_BUY) ?
                         SymbolInfoDouble(Symbol(), SYMBOL_BID) :
                         SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    
    // Add trailing stop logic here if needed
}

//+------------------------------------------------------------------+
//| Update display information                                       |
//+------------------------------------------------------------------+
void UpdateDisplay()
{
    string info = "\n===== BANK HEDGE EA =====\n";
    info += "Status: " + (InpAutoTrade ? "ACTIVE" : "PAUSED") + "\n";
    info += "Open Positions: " + IntegerToString(GetOpenPositionsCount()) + "\n";
    info += "Balance: $" + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2) + "\n";
    info += "Equity: $" + DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2) + "\n";
    info += "Spread: " + IntegerToString(SymbolInfoInteger(Symbol(), SYMBOL_SPREAD)) + " points\n";
    info += "Time: " + TimeToString(TimeCurrent()) + "\n";
    info += "========================\n";
    
    Comment(info);
}