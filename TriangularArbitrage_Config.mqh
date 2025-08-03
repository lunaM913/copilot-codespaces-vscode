//+------------------------------------------------------------------+
//|                                    TriangularArbitrage_Config.mqh |
//|                                Configuration file for Triangular Arbitrage EA |
//+------------------------------------------------------------------+
#property copyright "Triangular Arbitrage EA"
#property version   "1.00"

//--- Advanced Configuration Parameters
class CArbitrageConfig
{
public:
    // Symbol configurations
    static string GetSymbol(int index)
    {
        string symbols[3] = {"EURUSD", "GBPUSD", "EURGBP"};
        return (index >= 0 && index < 3) ? symbols[index] : "";
    }
    
    // Dynamic lot sizing based on account balance
    static double CalculateLotSize(double riskPercent, double accountBalance)
    {
        double riskAmount = accountBalance * (riskPercent / 100.0);
        double minLot = SymbolInfoDouble("EURUSD", SYMBOL_VOLUME_MIN);
        double maxLot = SymbolInfoDouble("EURUSD", SYMBOL_VOLUME_MAX);
        double lotStep = SymbolInfoDouble("EURUSD", SYMBOL_VOLUME_STEP);
        
        // Calculate position size based on risk
        double lotSize = riskAmount / 1000.0; // Simplified calculation
        
        // Normalize to valid lot size
        lotSize = MathMax(lotSize, minLot);
        lotSize = MathMin(lotSize, maxLot);
        lotSize = NormalizeDouble(lotSize / lotStep, 0) * lotStep;
        
        return lotSize;
    }
    
    // Spread validation for all symbols
    static bool ValidateSpreads(double maxSpread)
    {
        for(int i = 0; i < 3; i++)
        {
            string symbol = GetSymbol(i);
            MqlTick tick;
            if(!SymbolInfoTick(symbol, tick))
                return false;
                
            double spread = (tick.ask - tick.bid) / SymbolInfoDouble(symbol, SYMBOL_POINT);
            if(spread > maxSpread)
                return false;
        }
        return true;
    }
    
    // Market hours validation
    static bool IsMarketOpen()
    {
        // Check if all symbols are tradeable
        for(int i = 0; i < 3; i++)
        {
            string symbol = GetSymbol(i);
            if(!SymbolInfoInteger(symbol, SYMBOL_TRADE_MODE))
                return false;
        }
        return true;
    }
    
    // Economic news filter (basic implementation)
    static bool IsHighImpactNewsTime()
    {
        // This is a simplified check - in practice, you would integrate with an economic calendar
        datetime currentTime = TimeCurrent();
        MqlDateTime dt;
        TimeToStruct(currentTime, dt);
        
        // Avoid trading during major news releases (typically around 8:30, 10:00, 14:30 GMT)
        int hour = dt.hour;
        int minute = dt.min;
        
        if((hour == 8 && minute >= 25 && minute <= 35) ||
           (hour == 10 && minute >= 0 && minute <= 5) ||
           (hour == 14 && minute >= 25 && minute <= 35))
        {
            return true;
        }
        
        return false;
    }
};

//--- Risk Management Class
class CRiskManager
{
public:
    static double CalculateMaxLoss(double lotSize, string symbol)
    {
        double pointValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
        double maxLossPoints = 50.0; // Maximum loss in points
        return lotSize * maxLossPoints * pointValue;
    }
    
    static bool ValidateRisk(double totalRisk, double accountBalance, double maxRiskPercent)
    {
        double riskPercent = (totalRisk / accountBalance) * 100.0;
        return riskPercent <= maxRiskPercent;
    }
    
    static double CalculateCorrelationRisk(double lotSizes[])
    {
        // Simplified correlation risk calculation
        // In practice, you would use historical correlation data
        double correlationFactor = 0.8; // Assume 80% correlation between currency pairs
        double totalExposure = 0;
        
        for(int i = 0; i < 3; i++)
        {
            totalExposure += lotSizes[i];
        }
        
        return totalExposure * correlationFactor;
    }
};

//--- Performance Tracking Class
class CPerformanceTracker
{
private:
    static int totalTrades;
    static int profitableTrades;
    static double totalProfit;
    static double maxDrawdown;
    
public:
    static void AddTrade(double profit)
    {
        totalTrades++;
        if(profit > 0)
            profitableTrades++;
        totalProfit += profit;
        
        // Update drawdown calculation would go here
    }
    
    static double GetWinRate()
    {
        return totalTrades > 0 ? (double)profitableTrades / totalTrades * 100.0 : 0.0;
    }
    
    static double GetTotalProfit()
    {
        return totalProfit;
    }
    
    static int GetTotalTrades()
    {
        return totalTrades;
    }
    
    static void Reset()
    {
        totalTrades = 0;
        profitableTrades = 0;
        totalProfit = 0;
        maxDrawdown = 0;
    }
};

// Initialize static variables
int CPerformanceTracker::totalTrades = 0;
int CPerformanceTracker::profitableTrades = 0;
double CPerformanceTracker::totalProfit = 0.0;
double CPerformanceTracker::maxDrawdown = 0.0;