# Triangular Arbitrage Expert Advisor (EA)

## Overview
This Expert Advisor implements a triangular arbitrage strategy for the EUR/USD, GBP/USD, and EUR/GBP currency pairs. Triangular arbitrage exploits price discrepancies between three related currency pairs to generate risk-free profits through simultaneous trading.

## How Triangular Arbitrage Works

### Basic Concept
Triangular arbitrage involves three currency pairs that form a triangle:
- EUR/USD (Euro to US Dollar)
- GBP/USD (British Pound to US Dollar)  
- EUR/GBP (Euro to British Pound)

The strategy looks for situations where the implied cross rate differs from the actual market rate, creating arbitrage opportunities.

### Example Scenarios

#### Scenario 1: EUR → GBP → USD → EUR
1. **Sell EUR/GBP** (convert EUR to GBP)
2. **Buy GBP/USD** (convert GBP to USD)
3. **Sell EUR/USD** (convert EUR to USD, then USD back to EUR)

#### Scenario 2: EUR → USD → GBP → EUR
1. **Buy EUR/USD** (convert EUR to USD)
2. **Sell GBP/USD** (convert USD to GBP)
3. **Buy EUR/GBP** (convert GBP back to EUR)

## Files Included

1. **TriangularArbitrage_EA.mq5** - Main Expert Advisor file
2. **TriangularArbitrage_Config.mqh** - Configuration and utility classes
3. **TRIANGULAR_ARBITRAGE_README.md** - This documentation file

## Installation Instructions

### Prerequisites
- MetaTrader 5 platform
- Active trading account with access to EUR/USD, GBP/USD, and EUR/GBP pairs
- Sufficient account balance for simultaneous positions
- Low latency internet connection (recommended for arbitrage)

### Installation Steps
1. Copy `TriangularArbitrage_EA.mq5` to your MetaTrader 5 `MQL5/Experts/` directory
2. Copy `TriangularArbitrage_Config.mqh` to your MetaTrader 5 `MQL5/Include/` directory
3. Compile the EA in MetaEditor (F7 or Compile button)
4. Attach the EA to any chart (preferably EUR/USD, GBP/USD, or EUR/GBP)

## Configuration Parameters

### Trading Parameters
- **Lot Size (InpLotSize)**: Base lot size for each position (default: 0.1)
- **Minimum Profit Pips (InpMinProfitPips)**: Minimum profit threshold to execute arbitrage (default: 2.0)
- **Maximum Spread (InpMaxSpread)**: Maximum allowed spread in pips (default: 3.0)
- **Slippage (InpSlippage)**: Maximum acceptable slippage in pips (default: 3)
- **Auto Trade (InpAutoTrade)**: Enable/disable automatic trading (default: true)

### Risk Management
- **Maximum Risk Percent (InpMaxRiskPercent)**: Maximum risk per trade as % of account (default: 2.0%)
- **Stop Loss (InpStopLoss)**: Safety stop loss in pips (default: 50.0)
- **Take Profit (InpTakeProfit)**: Take profit target in pips (default: 10.0)

### Monitoring
- **Magic Number (InpMagicNumber)**: Unique identifier for EA trades (default: 12345)
- **Show Info (InpShowInfo)**: Display information panel on chart (default: true)
- **Refresh Rate (InpRefreshRate)**: Screen refresh rate in milliseconds (default: 100)

## Key Features

### Real-Time Monitoring
- Continuous monitoring of all three currency pairs
- Real-time spread checking
- Price discrepancy detection
- Information panel displaying current status

### Risk Management
- Maximum spread validation
- Position size limits
- Safety stop loss and take profit
- Correlation risk assessment
- Market hours validation

### Trade Execution
- Simultaneous position opening
- Automatic position closing when profit target is reached
- Emergency position closure on failures
- Trade tracking and performance monitoring

### Advanced Features
- Economic news time filtering
- Dynamic lot sizing based on account balance
- Performance tracking and statistics
- Correlation risk calculation

## Usage Instructions

### 1. Initial Setup
1. Ensure all three currency pairs (EUR/USD, GBP/USD, EUR/GBP) are available in Market Watch
2. Set appropriate parameters based on your account size and risk tolerance
3. Enable automated trading in MetaTrader 5 (Ctrl+E or Tools → Options → Expert Advisors)

### 2. Parameter Configuration
```
Recommended Settings for Beginners:
- Lot Size: 0.01 - 0.1 (depending on account size)
- Min Profit Pips: 2.0 - 5.0
- Max Spread: 2.0 - 3.0
- Max Risk Percent: 1.0 - 2.0%
```

### 3. Monitoring
- The information panel shows real-time data for all pairs
- Watch for "ARBITRAGE OPPORTUNITY" alerts
- Monitor open positions count
- Check profit/loss status regularly

### 4. Best Practices
- Start with small lot sizes to test the system
- Monitor during active trading hours (London/New York overlap)
- Avoid trading during major news releases
- Ensure stable internet connection
- Regular monitoring of EA performance

## Risk Warnings

### Market Risks
- **Execution Risk**: Arbitrage opportunities exist for very short periods
- **Slippage Risk**: Price slippage can eliminate arbitrage profits
- **Spread Risk**: Wide spreads can make arbitrage unprofitable
- **Liquidity Risk**: Low liquidity can affect trade execution

### Technical Risks
- **Latency Risk**: High latency can cause missed opportunities
- **System Risk**: Platform or internet failures during trade execution
- **Correlation Risk**: Currency pairs may not behave as expected

### Recommendations
- Test thoroughly on a demo account first
- Start with small position sizes
- Monitor performance closely
- Have emergency procedures in place
- Regular system maintenance and updates

## Performance Monitoring

### Key Metrics
- **Win Rate**: Percentage of profitable arbitrage cycles
- **Average Profit**: Average profit per completed cycle
- **Maximum Drawdown**: Largest peak-to-trough decline
- **Execution Time**: Time taken to complete arbitrage cycles

### Performance Optimization
1. **Spread Management**: Trade only when spreads are tight
2. **Timing**: Focus on high-liquidity periods
3. **Risk Control**: Maintain strict risk management rules
4. **Regular Review**: Analyze performance and adjust parameters

## Troubleshooting

### Common Issues
1. **No Arbitrage Opportunities Found**
   - Check if all symbols are active
   - Verify spread settings
   - Ensure market is open
   - Lower minimum profit threshold (carefully)

2. **Failed Trade Execution**
   - Check account permissions
   - Verify sufficient margin
   - Check internet connection
   - Review broker restrictions

3. **Unexpected Losses**
   - Review risk management settings
   - Check for news events
   - Verify execution speed
   - Analyze market conditions

### Error Codes
- **Trade Error 10016**: Insufficient funds
- **Trade Error 10018**: Requote
- **Trade Error 10019**: Order locked
- **Trade Error 10027**: Auto trading disabled

## Support and Updates

### Contact Information
- For technical support, consult your broker's documentation
- For EA updates, check the source repository
- For customization, contact qualified MQL5 developers

### Version History
- **v1.00**: Initial release with basic triangular arbitrage functionality

## Disclaimer

This Expert Advisor is provided for educational and research purposes. Trading foreign exchange carries a high level of risk and may not be suitable for all investors. Past performance is not indicative of future results. The author and distributors are not responsible for any trading losses incurred through the use of this software.

Always test thoroughly on a demo account before using real money, and never risk more than you can afford to lose.

## License

This software is provided under the MIT License. See the LICENSE file for details.

---

**Last Updated**: 2024
**Version**: 1.00
**Compatible with**: MetaTrader 5