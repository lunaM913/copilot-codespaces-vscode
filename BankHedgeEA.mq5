//+------------------------------------------------------------------+
//|                                                   BankHedgeEA.mq5 |
//|                                     Professional Bank Hedge EA |
//|                                                 MQ5 Expert Advisor |
//+------------------------------------------------------------------+
#property copyright "BankHedgeEA"
#property version   "1.00"
#property description "Bank Hedging Expert Advisor for MetaTrader 5"

//--- Include trading libraries
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>

//--- Input parameters
input group "=== TRADING SETTINGS ==="
input double InpLotSize = 0.1;                    // Lot Size
input double InpStopLoss = 50.0;                  // Stop Loss (pips)
input double InpTakeProfit = 100.0;               // Take Profit (pips)
input int    InpSlippage = 3;                     // Max Slippage (pips)
input bool   InpAutoTrade = true;                 // Enable Auto Trading

input group "=== HEDGE SETTINGS ==="
input double InpHedgeRatio = 1.0;                 // Hedge Ratio
input double InpCorrelationThreshold = 0.8;       // Correlation Threshold
input int    InpMaxPositions = 5;                 // Maximum Positions

input group "=== RISK MANAGEMENT ==="
input double InpMaxRiskPercent = 2.0;             // Max Risk Per Trade (%)
input double InpMaxDrawdown = 20.0;               // Max Drawdown (%)
input bool   InpUseMoneyManagement = true;        // Use Money Management

input group "=== SYSTEM SETTINGS ==="
input int    InpMagicNumber = 777888;             // Magic Number
input bool   InpShowPanel = true;                 // Show Info Panel
input color  InpPanelColor = clrDarkBlue;         // Panel Color

//--- Global variables
CTrade trade;
CPositionInfo position;
COrderInfo order;

string symbols[] = {"EURUSD", "GBPUSD", "USDJPY", "USDCHF"};
int symbolCount = 4;

datetime lastBarTime = 0;
double accountStartBalance = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Initialize trading class
    trade.SetExpertMagicNumber(InpMagicNumber);
    trade.SetMarginMode();
    trade.SetTypeFillingBySymbol(Symbol());
    
    // Store initial account balance
    accountStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    
    // Validate input parameters
    if(InpLotSize <= 0)
    {
        Print("ERROR: Invalid lot size!");
        return INIT_PARAMETERS_INCORRECT;
    }
    
    if(InpMagicNumber <= 0)
    {
        Print("ERROR: Invalid magic number!");
        return INIT_PARAMETERS_INCORRECT;
    }
    
    // Initialize symbols
    for(int i = 0; i < symbolCount; i++)
    {
        if(!SymbolSelect(symbols[i], true))
        {
            Print("WARNING: Could not select symbol: ", symbols[i]);
        }
    }
    
    Print("===================================");
    Print("BANK HEDGE EA INITIALIZED SUCCESSFULLY");
    Print("Version: 1.00");
    Print("Magic Number: ", InpMagicNumber);
    Print("Auto Trade: ", (InpAutoTrade ? "ENABLED" : "DISABLED"));
    Print("===================================");
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                               |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("===================================");
    Print("BANK HEDGE EA STOPPED");
    Print("Reason: ", GetDeInitReasonText(reason));
    Print("===================================");
    
    // Clean up
    Comment("");
}

//+------------------------------------------------------------------+
//| Expert tick function                                            |
//+------------------------------------------------------------------+
void OnTick()
{
    // Check if auto trading is enabled
    if(!InpAutoTrade)
        return;
        
    // Check if new bar formed
    datetime currentBarTime = iTime(Symbol(), PERIOD_CURRENT, 0);
    if(currentBarTime == lastBarTime)
        return;
    lastBarTime = currentBarTime;
    
    // Main trading logic
    AnalyzeMarket();
    ManagePositions();
    
    // Update info panel
    if(InpShowPanel)
        UpdateInfoPanel();
}

//+------------------------------------------------------------------+
//| Analyze market conditions                                       |
//+------------------------------------------------------------------+
void AnalyzeMarket()
{
    // Check risk limits
    if(!CheckRiskLimits())
        return;
        
    // Check maximum positions
    if(GetOpenPositions() >= InpMaxPositions)
        return;
    
    // Bank hedge strategy logic
    ExecuteBankHedgeStrategy();
}

//+------------------------------------------------------------------+
//| Execute bank hedge strategy                                     |
//+------------------------------------------------------------------+
void ExecuteBankHedgeStrategy()
{
    // Get current market data
    double currentPrice = SymbolInfoDouble(Symbol(), SYMBOL_BID);
    double spread = SymbolInfoInteger(Symbol(), SYMBOL_SPREAD) * SymbolInfoDouble(Symbol(), SYMBOL_POINT);
    
    // Simple hedge strategy example
    // You can replace this with your specific bank hedge logic
    
    if(!HasOpenPositions())
    {
        // Example: Open positions based on market conditions
        if(IsUptrend())
        {
            OpenBuyPosition();
        }
        else if(IsDowntrend())
        {
            OpenSellPosition();
        }
    }
}

//+------------------------------------------------------------------+
//| Check if market is in uptrend                                   |
//+------------------------------------------------------------------+
bool IsUptrend()
{
    // Simple trend detection using moving averages
    double ma20 = iMA(Symbol(), PERIOD_CURRENT, 20, 0, MODE_SMA, PRICE_CLOSE, 1);
    double ma50 = iMA(Symbol(), PERIOD_CURRENT, 50, 0, MODE_SMA, PRICE_CLOSE, 1);
    
    return (ma20 > ma50);
}

//+------------------------------------------------------------------+
//| Check if market is in downtrend                                 |
//+------------------------------------------------------------------+
bool IsDowntrend()
{
    // Simple trend detection using moving averages
    double ma20 = iMA(Symbol(), PERIOD_CURRENT, 20, 0, MODE_SMA, PRICE_CLOSE, 1);
    double ma50 = iMA(Symbol(), PERIOD_CURRENT, 50, 0, MODE_SMA, PRICE_CLOSE, 1);
    
    return (ma20 < ma50);
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
    
    if(trade.Buy(lotSize, Symbol(), price, sl, tp, "Bank Hedge Buy"))
    {
        Print("BUY order opened successfully at ", price);
    }
    else
    {
        Print("Failed to open BUY order. Error: ", trade.ResultRetcode());
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
    
    if(trade.Sell(lotSize, Symbol(), price, sl, tp, "Bank Hedge Sell"))
    {
        Print("SELL order opened successfully at ", price);
    }
    else
    {
        Print("Failed to open SELL order. Error: ", trade.ResultRetcode());
    }
}

//+------------------------------------------------------------------+
//| Calculate lot size based on risk management                     |
//+------------------------------------------------------------------+
double CalculateLotSize()
{
    double lotSize = InpLotSize;
    
    if(InpUseMoneyManagement)
    {
        double balance = AccountInfoDouble(ACCOUNT_BALANCE);
        double riskAmount = balance * (InpMaxRiskPercent / 100.0);
        double pointValue = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
        
        if(InpStopLoss > 0 && pointValue > 0)
        {
            lotSize = riskAmount / (InpStopLoss * pointValue);
        }
    }
    
    // Normalize lot size
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
    return (GetOpenPositions() > 0);
}

//+------------------------------------------------------------------+
//| Get number of open positions                                    |
//+------------------------------------------------------------------+
int GetOpenPositions()
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
                // Position management logic
                ManagePosition();
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Manage individual position                                       |
//+------------------------------------------------------------------+
void ManagePosition()
{
    // Example: Trailing stop logic
    double currentPrice = (position.PositionType() == POSITION_TYPE_BUY) ? 
                         SymbolInfoDouble(Symbol(), SYMBOL_BID) : 
                         SymbolInfoDouble(Symbol(), SYMBOL_ASK);
                         
    // Add your position management logic here
    // Trailing stops, partial closes, hedge management, etc.
}

//+------------------------------------------------------------------+
//| Check risk limits                                               |
//+------------------------------------------------------------------+
bool CheckRiskLimits()
{
    double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    double drawdown = ((accountStartBalance - currentBalance) / accountStartBalance) * 100.0;
    
    if(drawdown > InpMaxDrawdown)
    {
        Print("WARNING: Maximum drawdown exceeded: ", DoubleToString(drawdown, 2), "%");
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Update information panel                                         |
//+------------------------------------------------------------------+
void UpdateInfoPanel()
{
    string info = "\n===== BANK HEDGE EA =====\n";
    info += "Status: " + (InpAutoTrade ? "ACTIVE" : "PAUSED") + "\n";
    info += "Open Positions: " + IntegerToString(GetOpenPositions()) + "\n";
    info += "Balance: $" + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2) + "\n";
    info += "Equity: $" + DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2) + "\n";
    info += "Free Margin: $" + DoubleToString(AccountInfoDouble(ACCOUNT_FREEMARGIN), 2) + "\n";
    info += "Time: " + TimeToString(TimeCurrent()) + "\n";
    info += "========================\n";
    
    Comment(info);
}

//+------------------------------------------------------------------+
//| Get deinitialization reason text                                |
//+------------------------------------------------------------------+
string GetDeInitReasonText(int reason)
{
    string text = "";
    switch(reason)
    {
        case REASON_ACCOUNT: text = "Account changed"; break;
        case REASON_CHARTCHANGE: text = "Chart changed"; break;
        case REASON_CHARTCLOSE: text = "Chart closed"; break;
        case REASON_PARAMETERS: text = "Parameters changed"; break;
        case REASON_RECOMPILE: text = "Recompiled"; break;
        case REASON_REMOVE: text = "Removed from chart"; break;
        case REASON_TEMPLATE: text = "Template changed"; break;
        default: text = "Unknown reason"; break;
    }
    return text;
}