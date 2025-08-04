//+------------------------------------------------------------------+
//|                                      TriangularArbitrage_Tester.mq5 |
//|                                         Testing script for Triangular Arbitrage |
//+------------------------------------------------------------------+
#property copyright "Triangular Arbitrage EA"
#property version   "1.00"
#property script_show_inputs

//--- Input parameters
input group "=== Test Parameters ==="
input double InpEURUSD_Bid = 1.0850;              // EUR/USD Bid price
input double InpEURUSD_Ask = 1.0853;              // EUR/USD Ask price
input double InpGBPUSD_Bid = 1.2650;              // GBP/USD Bid price
input double InpGBPUSD_Ask = 1.2653;              // GBP/USD Ask price
input double InpEURGBP_Bid = 0.8580;              // EUR/GBP Bid price
input double InpEURGBP_Ask = 0.8583;              // EUR/GBP Ask price

input group "=== Simulation Parameters ==="
input int    InpSimulationRuns = 1000;            // Number of simulation runs
input double InpPriceVariation = 0.0010;          // Price variation range for simulation
input bool   InpDetailedOutput = true;            // Show detailed calculation output

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
    Print("=== Triangular Arbitrage Tester Started ===");
    
    // Test with current input prices
    Print("\n--- Single Test with Input Prices ---");
    TestArbitrageCalculation(InpEURUSD_Bid, InpEURUSD_Ask, InpGBPUSD_Bid, InpGBPUSD_Ask, InpEURGBP_Bid, InpEURGBP_Ask);
    
    // Run simulation with price variations
    Print("\n--- Simulation Results ---");
    RunSimulation();
    
    Print("\n=== Triangular Arbitrage Tester Completed ===");
}

//+------------------------------------------------------------------+
//| Test arbitrage calculation with given prices                     |
//+------------------------------------------------------------------+
void TestArbitrageCalculation(double eurusd_bid, double eurusd_ask, double gbpusd_bid, double gbpusd_ask, double eurgbp_bid, double eurgbp_ask)
{
    if(InpDetailedOutput)
    {
        Print("Input Prices:");
        Print("EUR/USD: ", DoubleToString(eurusd_bid, 5), "/", DoubleToString(eurusd_ask, 5));
        Print("GBP/USD: ", DoubleToString(gbpusd_bid, 5), "/", DoubleToString(gbpusd_ask, 5));
        Print("EUR/GBP: ", DoubleToString(eurgbp_bid, 5), "/", DoubleToString(eurgbp_ask, 5));
    }
    
    // Calculate implied EUR/GBP rates
    double implied_eurgbp_via_usd = eurusd_bid / gbpusd_ask;  // EUR->USD->GBP conversion
    double implied_eurgbp_direct = gbpusd_bid / eurusd_ask;   // Reverse calculation
    
    if(InpDetailedOutput)
    {
        Print("\nImplied Rates:");
        Print("EUR/GBP via USD: ", DoubleToString(implied_eurgbp_via_usd, 5));
        Print("EUR/GBP direct calc: ", DoubleToString(implied_eurgbp_direct, 5));
        Print("Actual EUR/GBP mid: ", DoubleToString((eurgbp_bid + eurgbp_ask) / 2, 5));
    }
    
    // Calculate arbitrage opportunities
    double profit1 = (implied_eurgbp_via_usd - eurgbp_ask) * 10000; // Convert to pips
    double profit2 = (eurgbp_bid - implied_eurgbp_direct) * 10000;  // Convert to pips
    
    Print("\nArbitrage Analysis:");
    
    if(profit1 > 0)
    {
        Print("*** OPPORTUNITY 1 FOUND ***");
        Print("Strategy: Sell EUR/GBP, Buy GBP/USD, Sell EUR/USD");
        Print("Expected Profit: ", DoubleToString(profit1, 2), " pips");
        
        // Calculate execution details
        double lotSize = 1.0; // 1 standard lot for calculation
        Print("Trade Sequence (", DoubleToString(lotSize, 2), " lots):");
        Print("1. Sell EUR/GBP at ", DoubleToString(eurgbp_bid, 5), " -> Get ", DoubleToString(lotSize * 100000 * eurgbp_bid, 2), " GBP");
        Print("2. Buy GBP/USD at ", DoubleToString(gbpusd_ask, 5), " -> Get ", DoubleToString(lotSize * 100000 * eurgbp_bid / gbpusd_ask, 2), " USD");
        Print("3. Sell EUR/USD at ", DoubleToString(eurusd_bid, 5), " -> Need ", DoubleToString(lotSize * 100000 * eurgbp_bid / gbpusd_ask / eurusd_bid, 2), " EUR");
        
        double finalBalance = 100000 - (lotSize * 100000 * eurgbp_bid / gbpusd_ask / eurusd_bid);
        Print("Net EUR result: ", DoubleToString(finalBalance, 2), " EUR (Profit: ", DoubleToString(finalBalance - 100000, 2), " EUR)");
    }
    else
    {
        Print("Opportunity 1: No profit (", DoubleToString(profit1, 2), " pips)");
    }
    
    if(profit2 > 0)
    {
        Print("\n*** OPPORTUNITY 2 FOUND ***");
        Print("Strategy: Buy EUR/USD, Sell GBP/USD, Buy EUR/GBP");
        Print("Expected Profit: ", DoubleToString(profit2, 2), " pips");
        
        // Calculate execution details
        double lotSize = 1.0; // 1 standard lot for calculation
        Print("Trade Sequence (", DoubleToString(lotSize, 2), " lots):");
        Print("1. Buy EUR/USD at ", DoubleToString(eurusd_ask, 5), " -> Get ", DoubleToString(lotSize * 100000 * eurusd_ask, 2), " USD");
        Print("2. Sell GBP/USD at ", DoubleToString(gbpusd_bid, 5), " -> Get ", DoubleToString(lotSize * 100000 * eurusd_ask / gbpusd_bid, 2), " GBP");
        Print("3. Buy EUR/GBP at ", DoubleToString(eurgbp_ask, 5), " -> Get ", DoubleToString(lotSize * 100000 * eurusd_ask / gbpusd_bid / eurgbp_ask, 2), " EUR");
        
        double finalBalance = (lotSize * 100000 * eurusd_ask / gbpusd_bid / eurgbp_ask) - 100000;
        Print("Net EUR result: ", DoubleToString(finalBalance + 100000, 2), " EUR (Profit: ", DoubleToString(finalBalance, 2), " EUR)");
    }
    else
    {
        Print("Opportunity 2: No profit (", DoubleToString(profit2, 2), " pips)");
    }
    
    // Calculate spreads
    double eurusd_spread = (eurusd_ask - eurusd_bid) * 10000;
    double gbpusd_spread = (gbpusd_ask - gbpusd_bid) * 10000;
    double eurgbp_spread = (eurgbp_ask - eurgbp_bid) * 10000;
    double total_spread_cost = eurusd_spread + gbpusd_spread + eurgbp_spread;
    
    Print("\nSpread Analysis:");
    Print("EUR/USD spread: ", DoubleToString(eurusd_spread, 1), " pips");
    Print("GBP/USD spread: ", DoubleToString(gbpusd_spread, 1), " pips");
    Print("EUR/GBP spread: ", DoubleToString(eurgbp_spread, 1), " pips");
    Print("Total spread cost: ", DoubleToString(total_spread_cost, 1), " pips");
    
    // Net profit after spreads
    double net_profit1 = profit1 - total_spread_cost;
    double net_profit2 = profit2 - total_spread_cost;
    
    Print("\nNet Profit (after spreads):");
    Print("Opportunity 1: ", DoubleToString(net_profit1, 2), " pips");
    Print("Opportunity 2: ", DoubleToString(net_profit2, 2), " pips");
    
    if(net_profit1 > 0 || net_profit2 > 0)
    {
        Print("\n*** PROFITABLE ARBITRAGE AVAILABLE ***");
    }
    else
    {
        Print("\nNo profitable arbitrage available after spread costs");
    }
}

//+------------------------------------------------------------------+
//| Run simulation with random price variations                      |
//+------------------------------------------------------------------+
void RunSimulation()
{
    int opportunities_found = 0;
    double total_profit = 0;
    double max_profit = 0;
    double min_profit = 0;
    
    Print("Running ", IntegerToString(InpSimulationRuns), " simulations with ±", DoubleToString(InpPriceVariation * 10000, 1), " pip variations...");
    
    MathSrand(GetTickCount());
    
    for(int i = 0; i < InpSimulationRuns; i++)
    {
        // Generate random price variations
        double eurusd_bid = InpEURUSD_Bid + (MathRand() / 32767.0 - 0.5) * InpPriceVariation * 2;
        double eurusd_ask = eurusd_bid + (InpEURUSD_Ask - InpEURUSD_Bid);
        
        double gbpusd_bid = InpGBPUSD_Bid + (MathRand() / 32767.0 - 0.5) * InpPriceVariation * 2;
        double gbpusd_ask = gbpusd_bid + (InpGBPUSD_Ask - InpGBPUSD_Bid);
        
        double eurgbp_bid = InpEURGBP_Bid + (MathRand() / 32767.0 - 0.5) * InpPriceVariation * 2;
        double eurgbp_ask = eurgbp_bid + (InpEURGBP_Ask - InpEURGBP_Bid);
        
        // Calculate arbitrage
        double implied_eurgbp_via_usd = eurusd_bid / gbpusd_ask;
        double implied_eurgbp_direct = gbpusd_bid / eurusd_ask;
        
        double profit1 = (implied_eurgbp_via_usd - eurgbp_ask) * 10000;
        double profit2 = (eurgbp_bid - implied_eurgbp_direct) * 10000;
        
        // Calculate net profit after spreads
        double total_spread_cost = ((eurusd_ask - eurusd_bid) + (gbpusd_ask - gbpusd_bid) + (eurgbp_ask - eurgbp_bid)) * 10000;
        double net_profit1 = profit1 - total_spread_cost;
        double net_profit2 = profit2 - total_spread_cost;
        
        double best_profit = MathMax(net_profit1, net_profit2);
        
        if(best_profit > 0)
        {
            opportunities_found++;
            total_profit += best_profit;
            max_profit = MathMax(max_profit, best_profit);
            min_profit = (min_profit == 0) ? best_profit : MathMin(min_profit, best_profit);
        }
    }
    
    Print("\n=== Simulation Results ===");
    Print("Total runs: ", IntegerToString(InpSimulationRuns));
    Print("Opportunities found: ", IntegerToString(opportunities_found));
    Print("Success rate: ", DoubleToString((double)opportunities_found / InpSimulationRuns * 100, 2), "%");
    
    if(opportunities_found > 0)
    {
        Print("Average profit: ", DoubleToString(total_profit / opportunities_found, 2), " pips");
        Print("Maximum profit: ", DoubleToString(max_profit, 2), " pips");
        Print("Minimum profit: ", DoubleToString(min_profit, 2), " pips");
        Print("Total profit potential: ", DoubleToString(total_profit, 2), " pips");
    }
    else
    {
        Print("No profitable opportunities found in simulation");
    }
}

//+------------------------------------------------------------------+
//| Calculate theoretical profit for given prices                    |
//+------------------------------------------------------------------+
double CalculateTheoreticalProfit(double eurusd_bid, double eurusd_ask, double gbpusd_bid, double gbpusd_ask, double eurgbp_bid, double eurgbp_ask)
{
    // Calculate both arbitrage directions
    double implied_eurgbp_via_usd = eurusd_bid / gbpusd_ask;
    double implied_eurgbp_direct = gbpusd_bid / eurusd_ask;
    
    double profit1 = (implied_eurgbp_via_usd - eurgbp_ask) * 10000;
    double profit2 = (eurgbp_bid - implied_eurgbp_direct) * 10000;
    
    // Calculate spread costs
    double total_spread_cost = ((eurusd_ask - eurusd_bid) + (gbpusd_ask - gbpusd_bid) + (eurgbp_ask - eurgbp_bid)) * 10000;
    
    double net_profit1 = profit1 - total_spread_cost;
    double net_profit2 = profit2 - total_spread_cost;
    
    return MathMax(MathMax(net_profit1, net_profit2), 0);
}