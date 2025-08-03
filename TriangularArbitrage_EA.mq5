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

//--- Input parameters
input group "=== Trading Parameters ==="
input double InpLotSize = 0.1;                    // Lot size for each position
input double InpMinProfitPips = 2.0;              // Minimum profit in pips to execute arbitrage
input double InpMaxSpread = 3.0;                  // Maximum allowed spread in pips
input int    InpSlippage = 3;                     // Maximum slippage in pips
input bool   InpAutoTrade = true;                 // Enable automatic trading

input group "=== Risk Management ==="
input double InpMaxRiskPercent = 2.0;             // Maximum risk per trade as % of account
input double InpStopLoss = 50.0;                  // Stop loss in pips (safety net)
input double InpTakeProfit = 10.0;                // Take profit in pips

input group "=== Monitoring ==="
input int    InpMagicNumber = 12345;              // Magic number for EA trades
input bool   InpShowInfo = true;                  // Show information panel
input int    InpRefreshRate = 100;                // Refresh rate in milliseconds

//--- Global variables
CTrade trade;
CPositionInfo position;
COrderInfo order;

string symbols[3] = {"EURUSD", "GBPUSD", "EURGBP"};
double prices[3][2];  // [symbol][bid/ask] - 0=bid, 1=ask
double spreads[3];
datetime lastUpdate = 0;

struct ArbitrageOpportunity
{
    bool   found;
    double profit_pips;
    int    direction;  // 1 for EUR->GBP->USD->EUR, -1 for EUR->USD->GBP->EUR
    double lots[3];
    string description;
};

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Set trade parameters
    trade.SetExpertMagicNumber(InpMagicNumber);
    trade.SetMarginMode();
    trade.SetTypeFillingBySymbol(Symbol());
    
    // Verify symbols are available
    for(int i = 0; i < 3; i++)
    {
        if(!SymbolSelect(symbols[i], true))
        {
            Print("Failed to select symbol: ", symbols[i]);
            return INIT_FAILED;
        }
    }
    
    Print("Triangular Arbitrage EA initialized successfully");
    Print("Monitoring symbols: ", symbols[0], ", ", symbols[1], ", ", symbols[2]);
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                               |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("Triangular Arbitrage EA deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                            |
//+------------------------------------------------------------------+
void OnTick()
{
    // Update prices
    if(!UpdatePrices())
        return;
    
    // Check for arbitrage opportunities
    ArbitrageOpportunity opportunity = CheckArbitrageOpportunity();
    
    if(opportunity.found && InpAutoTrade)
    {
        ExecuteArbitrage(opportunity);
    }
    
    // Update information panel
    if(InpShowInfo)
    {
        UpdateInfoPanel(opportunity);
    }
    
    // Manage existing positions
    ManagePositions();
}

//+------------------------------------------------------------------+
//| Update prices for all symbols                                   |
//+------------------------------------------------------------------+
bool UpdatePrices()
{
    for(int i = 0; i < 3; i++)
    {
        MqlTick tick;
        if(!SymbolInfoTick(symbols[i], tick))
        {
            Print("Failed to get tick for ", symbols[i]);
            return false;
        }
        
        prices[i][0] = tick.bid;
        prices[i][1] = tick.ask;
        spreads[i] = (tick.ask - tick.bid) / SymbolInfoDouble(symbols[i], SYMBOL_POINT);
        
        // Check if spread is too wide
        if(spreads[i] > InpMaxSpread)
        {
            return false;
        }
    }
    
    lastUpdate = TimeCurrent();
    return true;
}

//+------------------------------------------------------------------+
//| Check for triangular arbitrage opportunities                    |
//+------------------------------------------------------------------+
ArbitrageOpportunity CheckArbitrageOpportunity()
{
    ArbitrageOpportunity opp;
    opp.found = false;
    opp.profit_pips = 0;
    
    // Get current prices
    double eurusd_bid = prices[0][0];
    double eurusd_ask = prices[0][1];
    double gbpusd_bid = prices[1][0];
    double gbpusd_ask = prices[1][1];
    double eurgbp_bid = prices[2][0];
    double eurgbp_ask = prices[2][1];
    
    // Calculate implied EUR/GBP rate from EUR/USD and GBP/USD
    // Direction 1: EUR -> GBP -> USD -> EUR
    double implied_eurgbp_via_usd = eurusd_bid / gbpusd_ask;
    double profit1 = (implied_eurgbp_via_usd - eurgbp_ask) / SymbolInfoDouble("EURGBP", SYMBOL_POINT);
    
    // Direction 2: EUR -> USD -> GBP -> EUR  
    double implied_eurgbp_direct = gbpusd_bid / eurusd_ask;
    double profit2 = (eurgbp_bid - implied_eurgbp_direct) / SymbolInfoDouble("EURGBP", SYMBOL_POINT);
    
    // Check if opportunity exists
    if(profit1 > InpMinProfitPips)
    {
        opp.found = true;
        opp.profit_pips = profit1;
        opp.direction = 1;
        opp.description = "EUR->GBP->USD->EUR: Sell EUR/GBP, Buy GBP/USD, Sell EUR/USD";
        
        // Calculate lot sizes (simplified - equal lots for demonstration)
        for(int i = 0; i < 3; i++)
            opp.lots[i] = InpLotSize;
    }
    else if(profit2 > InpMinProfitPips)
    {
        opp.found = true;
        opp.profit_pips = profit2;
        opp.direction = -1;
        opp.description = "EUR->USD->GBP->EUR: Buy EUR/USD, Sell GBP/USD, Buy EUR/GBP";
        
        // Calculate lot sizes (simplified - equal lots for demonstration)
        for(int i = 0; i < 3; i++)
            opp.lots[i] = InpLotSize;
    }
    
    return opp;
}

//+------------------------------------------------------------------+
//| Execute triangular arbitrage trades                             |
//+------------------------------------------------------------------+
void ExecuteArbitrage(ArbitrageOpportunity &opportunity)
{
    // Check if we already have open positions
    if(HasOpenPositions())
    {
        Print("Skipping arbitrage - positions already open");
        return;
    }
    
    Print("Executing arbitrage opportunity: ", opportunity.description);
    Print("Expected profit: ", DoubleToString(opportunity.profit_pips, 2), " pips");
    
    bool success = true;
    
    if(opportunity.direction == 1)
    {
        // EUR->GBP->USD->EUR sequence
        // 1. Sell EUR/GBP
        success &= trade.Sell(opportunity.lots[2], "EURGBP", 0, 0, 0, "Arbitrage: Sell EURGBP");
        
        // 2. Buy GBP/USD  
        success &= trade.Buy(opportunity.lots[1], "GBPUSD", 0, 0, 0, "Arbitrage: Buy GBPUSD");
        
        // 3. Sell EUR/USD
        success &= trade.Sell(opportunity.lots[0], "EURUSD", 0, 0, 0, "Arbitrage: Sell EURUSD");
    }
    else
    {
        // EUR->USD->GBP->EUR sequence
        // 1. Buy EUR/USD
        success &= trade.Buy(opportunity.lots[0], "EURUSD", 0, 0, 0, "Arbitrage: Buy EURUSD");
        
        // 2. Sell GBP/USD
        success &= trade.Sell(opportunity.lots[1], "GBPUSD", 0, 0, 0, "Arbitrage: Sell GBPUSD");
        
        // 3. Buy EUR/GBP
        success &= trade.Buy(opportunity.lots[2], "EURGBP", 0, 0, 0, "Arbitrage: Buy EURGBP");
    }
    
    if(success)
    {
        Print("Arbitrage trades executed successfully");
    }
    else
    {
        Print("Failed to execute some arbitrage trades - manual intervention may be required");
        CloseAllPositions(); // Close any partial positions
    }
}

//+------------------------------------------------------------------+
//| Check if we have open positions                                 |
//+------------------------------------------------------------------+
bool HasOpenPositions()
{
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(position.SelectByIndex(i))
        {
            if(position.Magic() == InpMagicNumber)
                return true;
        }
    }
    return false;
}

//+------------------------------------------------------------------+
//| Close all positions opened by this EA                           |
//+------------------------------------------------------------------+
void CloseAllPositions()
{
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(position.SelectByIndex(i))
        {
            if(position.Magic() == InpMagicNumber)
            {
                trade.PositionClose(position.Ticket());
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Manage existing positions                                        |
//+------------------------------------------------------------------+
void ManagePositions()
{
    // Check if all arbitrage positions are profitable and can be closed
    if(!HasOpenPositions())
        return;
    
    double totalProfit = 0;
    int positionCount = 0;
    
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(position.SelectByIndex(i))
        {
            if(position.Magic() == InpMagicNumber)
            {
                totalProfit += position.Profit();
                positionCount++;
            }
        }
    }
    
    // Close all positions if total profit target is reached or stop loss hit
    if(positionCount > 0)
    {
        double profitPips = totalProfit / (InpLotSize * 10); // Approximate conversion to pips
        
        if(profitPips >= InpTakeProfit || profitPips <= -InpStopLoss)
        {
            Print("Closing arbitrage positions. Total profit: ", DoubleToString(profitPips, 2), " pips");
            CloseAllPositions();
        }
    }
}

//+------------------------------------------------------------------+
//| Update information panel                                         |
//+------------------------------------------------------------------+
void UpdateInfoPanel(ArbitrageOpportunity &opportunity)
{
    string info = "\n=== Triangular Arbitrage Monitor ===\n";
    info += "Time: " + TimeToString(TimeCurrent()) + "\n";
    info += "EUR/USD: " + DoubleToString(prices[0][0], 5) + "/" + DoubleToString(prices[0][1], 5) + 
            " (Spread: " + DoubleToString(spreads[0], 1) + ")\n";
    info += "GBP/USD: " + DoubleToString(prices[1][0], 5) + "/" + DoubleToString(prices[1][1], 5) + 
            " (Spread: " + DoubleToString(spreads[1], 1) + ")\n";
    info += "EUR/GBP: " + DoubleToString(prices[2][0], 5) + "/" + DoubleToString(prices[2][1], 5) + 
            " (Spread: " + DoubleToString(spreads[2], 1) + ")\n";
    
    if(opportunity.found)
    {
        info += "\n*** ARBITRAGE OPPORTUNITY ***\n";
        info += opportunity.description + "\n";
        info += "Profit: " + DoubleToString(opportunity.profit_pips, 2) + " pips\n";
    }
    else
    {
        info += "\nNo arbitrage opportunity found\n";
    }
    
    info += "\nOpen Positions: " + IntegerToString(CountOpenPositions()) + "\n";
    
    Comment(info);
}

//+------------------------------------------------------------------+
//| Count open positions for this EA                                |
//+------------------------------------------------------------------+
int CountOpenPositions()
{
    int count = 0;
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(position.SelectByIndex(i))
        {
            if(position.Magic() == InpMagicNumber)
                count++;
        }
    }
    return count;
}