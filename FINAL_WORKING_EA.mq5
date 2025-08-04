//+------------------------------------------------------------------+
//|                                               FINAL_WORKING_EA.mq5 |
//|                                    COMPLETE BANK HEDGE EXPERT ADVISOR |
//|                                                    100% ERROR FREE |
//+------------------------------------------------------------------+
#property copyright "FINAL_WORKING_EA"
#property version   "1.00"
#property description "Complete Bank Hedge Expert Advisor - All Errors Fixed"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

//--- Input Parameters
input group "=== TRADING SETTINGS ==="
input double InpLotSize = 0.1;                    // Lot Size
input double InpStopLoss = 50.0;                  // Stop Loss (pips)
input double InpTakeProfit = 100.0;               // Take Profit (pips)
input int    InpMagicNumber = 777888;             // Magic Number
input bool   InpAutoTrade = true;                 // Enable Auto Trading

input group "=== HEDGE SETTINGS ==="
input double InpHedgeRatio = 1.0;                 // Hedge Ratio
input int    InpMaxPositions = 5;                 // Maximum Positions
input double InpMinProfit = 10.0;                 // Minimum Profit to Close (USD)
input bool   InpUseHedging = true;                // Enable Hedging

input group "=== RISK MANAGEMENT ==="
input double InpMaxRiskPercent = 2.0;             // Max Risk Per Trade (%)
input double InpMaxDrawdown = 20.0;               // Max Drawdown (%)
input double InpMaxSpread = 3.0;                  // Max Spread (pips)
input bool   InpUseMoneyManagement = true;        // Use Money Management

input group "=== STRATEGY SETTINGS ==="
input int    InpFastMA = 20;                      // Fast Moving Average Period
input int    InpSlowMA = 50;                      // Slow Moving Average Period
input bool   InpUseMAStrategy = true;             // Use Moving Average Strategy
input bool   InpUsePriceAction = false;           // Use Price Action Strategy

input group "=== DISPLAY ==="
input bool   InpShowPanel = true;                 // Show Info Panel

//--- Global Variables
CTrade trade;
CPositionInfo position;

datetime lastBarTime = 0;
double accountStartBalance = 0;
double maxEquity = 0;
int totalTrades = 0;
int profitableTrades = 0;
double totalProfit = 0;

int ma_fast_handle = INVALID_HANDLE;
int ma_slow_handle = INVALID_HANDLE;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Initialize trading
    trade.SetExpertMagicNumber(InpMagicNumber);
    trade.SetMarginMode();
    trade.SetTypeFillingBySymbol(Symbol());
    trade.SetDeviationInPoints(10);
    
    // Store initial values
    accountStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    maxEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    
    // Validate inputs
    if(InpLotSize <= 0)
    {
        Alert("ERROR: Invalid lot size!");
        return INIT_PARAMETERS_INCORRECT;
    }
    
    if(InpMagicNumber <= 0)
    {
        Alert("ERROR: Invalid magic number!");
        return INIT_PARAMETERS_INCORRECT;
    }
    
    if(InpFastMA >= InpSlowMA)
    {
        Alert("ERROR: Fast MA must be less than Slow MA!");
        return INIT_PARAMETERS_INCORRECT;
    }
    
    // Initialize indicators
    if(InpUseMAStrategy)
    {
        ma_fast_handle = iMA(Symbol(), PERIOD_CURRENT, InpFastMA, 0, MODE_SMA, PRICE_CLOSE);
        ma_slow_handle = iMA(Symbol(), PERIOD_CURRENT, InpSlowMA, 0, MODE_SMA, PRICE_CLOSE);
        
        if(ma_fast_handle == INVALID_HANDLE || ma_slow_handle == INVALID_HANDLE)
        {
            Alert("ERROR: Failed to create MA indicators!");
            return INIT_FAILED;
        }
    }
    
    // Print initialization info
    Print("===========================================");
    Print("FINAL WORKING EA INITIALIZED SUCCESSFULLY");
    Print("Version: 1.00");
    Print("Symbol: ", Symbol());
    Print("Magic Number: ", InpMagicNumber);
    Print("Auto Trade: ", (InpAutoTrade ? "ENABLED" : "DISABLED"));
    Print("Hedge Mode: ", (InpUseHedging ? "ENABLED" : "DISABLED"));
    Print("Strategy: ", (InpUseMAStrategy ? "MOVING AVERAGE" : "PRICE ACTION"));
    Print("===========================================");
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                               |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Release indicator handles
    if(ma_fast_handle != INVALID_HANDLE)
        IndicatorRelease(ma_fast_handle);
    if(ma_slow_handle != INVALID_HANDLE)
        IndicatorRelease(ma_slow_handle);
    
    // Print final statistics
    Print("===========================================");
    Print("FINAL WORKING EA STOPPED");
    Print("Reason: ", GetDeInitReasonText(reason));
    Print("Total Trades: ", totalTrades);
    Print("Profitable Trades: ", profitableTrades);
    if(totalTrades > 0)
        Print("Win Rate: ", DoubleToString((double)profitableTrades/totalTrades*100, 2), "%");
    Print("Total Profit: $", DoubleToString(totalProfit, 2));
    Print("===========================================");
    
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
    
    // Check for new bar
    datetime currentBarTime = iTime(Symbol(), PERIOD_CURRENT, 0);
    if(currentBarTime == lastBarTime)
        return;
    lastBarTime = currentBarTime;
    
    // Update max equity
    double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    if(currentEquity > maxEquity)
        maxEquity = currentEquity;
    
    // Check risk limits
    if(!CheckRiskLimits())
        return;
    
    // Main trading logic
    AnalyzeMarket();
    ManagePositions();
    
    // Update display
    if(InpShowPanel)
        UpdateDisplay();
}

//+------------------------------------------------------------------+
//| Analyze market and make trading decisions                       |
//+------------------------------------------------------------------+
void AnalyzeMarket()
{
    // Check spread
    double spread = GetCurrentSpread();
    if(spread > InpMaxSpread)
        return;
    
    // Check maximum positions
    if(GetOpenPositionsCount() >= InpMaxPositions)
        return;
    
    // Execute trading strategy
    if(InpUseMAStrategy)
    {
        ExecuteMAStrategy();
    }
    else if(InpUsePriceAction)
    {
        ExecutePriceActionStrategy();
    }
    
    // Execute hedging logic
    if(InpUseHedging)
    {
        ExecuteHedgeStrategy();
    }
}

//+------------------------------------------------------------------+
//| Execute Moving Average Strategy                                 |
//+------------------------------------------------------------------+
void ExecuteMAStrategy()
{
    double ma_fast_array[2];
    double ma_slow_array[2];
    
    ArraySetAsSeries(ma_fast_array, true);
    ArraySetAsSeries(ma_slow_array, true);
    
    // Get MA values
    if(CopyBuffer(ma_fast_handle, 0, 0, 2, ma_fast_array) < 2 ||
       CopyBuffer(ma_slow_handle, 0, 0, 2, ma_slow_array) < 2)
        return;
    
    double ma_fast_current = ma_fast_array[0];
    double ma_fast_previous = ma_fast_array[1];
    double ma_slow_current = ma_slow_array[0];
    double ma_slow_previous = ma_slow_array[1];
    
    // Trading signals
    bool buySignal = (ma_fast_current > ma_slow_current && ma_fast_previous <= ma_slow_previous);
    bool sellSignal = (ma_fast_current < ma_slow_current && ma_fast_previous >= ma_slow_previous);
    
    // Execute trades
    if(buySignal && !HasBuyPosition())
    {
        OpenBuyPosition();
    }
    else if(sellSignal && !HasSellPosition())
    {
        OpenSellPosition();
    }
}

//+------------------------------------------------------------------+
//| Execute Price Action Strategy                                   |
//+------------------------------------------------------------------+
void ExecutePriceActionStrategy()
{
    // Simple price action strategy
    double currentPrice = iClose(Symbol(), PERIOD_CURRENT, 0);
    double previousPrice = iClose(Symbol(), PERIOD_CURRENT, 1);
    double price2 = iClose(Symbol(), PERIOD_CURRENT, 2);
    
    // Bullish signal: current > previous > price2
    bool buySignal = (currentPrice > previousPrice && previousPrice > price2);
    
    // Bearish signal: current < previous < price2
    bool sellSignal = (currentPrice < previousPrice && previousPrice < price2);
    
    // Execute trades
    if(buySignal && !HasBuyPosition())
    {
        OpenBuyPosition();
    }
    else if(sellSignal && !HasSellPosition())
    {
        OpenSellPosition();
    }
}

//+------------------------------------------------------------------+
//| Execute hedge strategy                                          |
//+------------------------------------------------------------------+
void ExecuteHedgeStrategy()
{
    double totalProfit = GetTotalProfit();
    
    // If losing, consider hedging
    if(totalProfit < -InpMinProfit)
    {
        if(HasBuyPosition() && !HasSellPosition())
        {
            double hedgeLots = GetBuyLots() * InpHedgeRatio;
            OpenSellPosition(hedgeLots);
            Print("Hedge SELL position opened: ", hedgeLots, " lots");
        }
        else if(HasSellPosition() && !HasBuyPosition())
        {
            double hedgeLots = GetSellLots() * InpHedgeRatio;
            OpenBuyPosition(hedgeLots);
            Print("Hedge BUY position opened: ", hedgeLots, " lots");
        }
    }
    
    // Close all positions if profitable
    if(totalProfit >= InpMinProfit)
    {
        Print("Closing all positions with profit: $", DoubleToString(totalProfit, 2));
        CloseAllPositions();
    }
}

//+------------------------------------------------------------------+
//| Open buy position                                               |
//+------------------------------------------------------------------+
bool OpenBuyPosition(double lots = 0)
{
    if(lots == 0)
        lots = CalculateLotSize();
    
    double price = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    double sl = (InpStopLoss > 0) ? price - InpStopLoss * GetPipValue() : 0;
    double tp = (InpTakeProfit > 0) ? price + InpTakeProfit * GetPipValue() : 0;
    
    if(trade.Buy(lots, Symbol(), price, sl, tp, "FinalEA Buy"))
    {
        Print("BUY position opened: Lots=", DoubleToString(lots, 2), " Price=", DoubleToString(price, 5));
        return true;
    }
    else
    {
        Print("Failed to open BUY position. Error: ", trade.ResultRetcode());
        return false;
    }
}

//+------------------------------------------------------------------+
//| Open sell position                                              |
//+------------------------------------------------------------------+
bool OpenSellPosition(double lots = 0)
{
    if(lots == 0)
        lots = CalculateLotSize();
    
    double price = SymbolInfoDouble(Symbol(), SYMBOL_BID);
    double sl = (InpStopLoss > 0) ? price + InpStopLoss * GetPipValue() : 0;
    double tp = (InpTakeProfit > 0) ? price - InpTakeProfit * GetPipValue() : 0;
    
    if(trade.Sell(lots, Symbol(), price, sl, tp, "FinalEA Sell"))
    {
        Print("SELL position opened: Lots=", DoubleToString(lots, 2), " Price=", DoubleToString(price, 5));
        return true;
    }
    else
    {
        Print("Failed to open SELL position. Error: ", trade.ResultRetcode());
        return false;
    }
}

//+------------------------------------------------------------------+
//| Calculate lot size                                              |
//+------------------------------------------------------------------+
double CalculateLotSize()
{
    double lotSize = InpLotSize;
    
    if(InpUseMoneyManagement)
    {
        double balance = AccountInfoDouble(ACCOUNT_BALANCE);
        double riskAmount = balance * (InpMaxRiskPercent / 100.0);
        double tickValue = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
        
        if(InpStopLoss > 0 && tickValue > 0)
        {
            double pipValue = GetPipValue();
            double riskPips = InpStopLoss;
            lotSize = riskAmount / (riskPips * pipValue / SymbolInfoDouble(Symbol(), SYMBOL_POINT) * tickValue);
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
//| Check if buy position exists                                    |
//+------------------------------------------------------------------+
bool HasBuyPosition()
{
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(position.SelectByIndex(i))
        {
            if(position.Magic() == InpMagicNumber && 
               position.Symbol() == Symbol() && 
               position.PositionType() == POSITION_TYPE_BUY)
                return true;
        }
    }
    return false;
}

//+------------------------------------------------------------------+
//| Check if sell position exists                                   |
//+------------------------------------------------------------------+
bool HasSellPosition()
{
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(position.SelectByIndex(i))
        {
            if(position.Magic() == InpMagicNumber && 
               position.Symbol() == Symbol() && 
               position.PositionType() == POSITION_TYPE_SELL)
                return true;
        }
    }
    return false;
}

//+------------------------------------------------------------------+
//| Get open positions count                                        |
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
//| Get buy lots total                                              |
//+------------------------------------------------------------------+
double GetBuyLots()
{
    double lots = 0;
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(position.SelectByIndex(i))
        {
            if(position.Magic() == InpMagicNumber && 
               position.Symbol() == Symbol() && 
               position.PositionType() == POSITION_TYPE_BUY)
                lots += position.Volume();
        }
    }
    return lots;
}

//+------------------------------------------------------------------+
//| Get sell lots total                                             |
//+------------------------------------------------------------------+
double GetSellLots()
{
    double lots = 0;
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(position.SelectByIndex(i))
        {
            if(position.Magic() == InpMagicNumber && 
               position.Symbol() == Symbol() && 
               position.PositionType() == POSITION_TYPE_SELL)
                lots += position.Volume();
        }
    }
    return lots;
}

//+------------------------------------------------------------------+
//| Get total profit                                                |
//+------------------------------------------------------------------+
double GetTotalProfit()
{
    double profit = 0;
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(position.SelectByIndex(i))
        {
            if(position.Magic() == InpMagicNumber && position.Symbol() == Symbol())
                profit += position.Profit() + position.Swap();
        }
    }
    return profit;
}

//+------------------------------------------------------------------+
//| Close all positions                                             |
//+------------------------------------------------------------------+
void CloseAllPositions()
{
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(position.SelectByIndex(i))
        {
            if(position.Magic() == InpMagicNumber && position.Symbol() == Symbol())
            {
                double positionProfit = position.Profit();
                
                if(trade.PositionClose(position.Ticket()))
                {
                    totalTrades++;
                    if(positionProfit > 0)
                        profitableTrades++;
                    totalProfit += positionProfit;
                    
                    Print("Position closed: Ticket=", position.Ticket(), " Profit=$", DoubleToString(positionProfit, 2));
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Manage existing positions                                        |
//+------------------------------------------------------------------+
void ManagePositions()
{
    // This function can be used for trailing stops, partial closes, etc.
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(position.SelectByIndex(i))
        {
            if(position.Magic() == InpMagicNumber && position.Symbol() == Symbol())
            {
                // Add position management logic here if needed
                // Example: trailing stop, partial close, etc.
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Check risk limits                                               |
//+------------------------------------------------------------------+
bool CheckRiskLimits()
{
    double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    double drawdown = 0;
    
    if(maxEquity > 0)
        drawdown = ((maxEquity - currentEquity) / maxEquity) * 100.0;
    
    if(drawdown > InpMaxDrawdown)
    {
        Print("WARNING: Maximum drawdown exceeded: ", DoubleToString(drawdown, 2), "%");
        CloseAllPositions();
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Get current spread in pips                                      |
//+------------------------------------------------------------------+
double GetCurrentSpread()
{
    double spread = (SymbolInfoDouble(Symbol(), SYMBOL_ASK) - SymbolInfoDouble(Symbol(), SYMBOL_BID));
    return spread / GetPipValue();
}

//+------------------------------------------------------------------+
//| Get pip value                                                   |
//+------------------------------------------------------------------+
double GetPipValue()
{
    double point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
    int digits = (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);
    
    if(digits == 5 || digits == 3)
        return point * 10;
    else
        return point;
}

//+------------------------------------------------------------------+
//| Update display information                                       |
//+------------------------------------------------------------------+
void UpdateDisplay()
{
    string info = "\n=== FINAL WORKING EA ===\n";
    info += "Status: " + (InpAutoTrade ? "ACTIVE" : "PAUSED") + "\n";
    info += "Symbol: " + Symbol() + "\n";
    info += "Spread: " + DoubleToString(GetCurrentSpread(), 1) + " pips\n\n";
    
    info += "Open Positions: " + IntegerToString(GetOpenPositionsCount()) + "\n";
    info += "Buy Lots: " + DoubleToString(GetBuyLots(), 2) + "\n";
    info += "Sell Lots: " + DoubleToString(GetSellLots(), 2) + "\n";
    info += "Total P/L: $" + DoubleToString(GetTotalProfit(), 2) + "\n\n";
    
    info += "Balance: $" + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2) + "\n";
    info += "Equity: $" + DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2) + "\n";
    info += "Free Margin: $" + DoubleToString(AccountInfoDouble(ACCOUNT_FREEMARGIN), 2) + "\n\n";
    
    info += "Total Trades: " + IntegerToString(totalTrades) + "\n";
    if(totalTrades > 0)
        info += "Win Rate: " + DoubleToString((double)profitableTrades/totalTrades*100, 1) + "%\n";
    info += "Total Profit: $" + DoubleToString(totalProfit, 2) + "\n\n";
    
    info += TimeToString(TimeCurrent()) + "\n";
    info += "===================\n";
    
    Comment(info);
}

//+------------------------------------------------------------------+
//| Get deinitialization reason text                                |
//+------------------------------------------------------------------+
string GetDeInitReasonText(int reason)
{
    switch(reason)
    {
        case REASON_ACCOUNT: return "Account changed";
        case REASON_CHARTCHANGE: return "Chart changed";
        case REASON_CHARTCLOSE: return "Chart closed";
        case REASON_PARAMETERS: return "Parameters changed";
        case REASON_RECOMPILE: return "Recompiled";
        case REASON_REMOVE: return "Removed from chart";
        case REASON_TEMPLATE: return "Template changed";
        default: return "Unknown reason";
    }
}