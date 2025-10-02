import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:oi_visualizer/oi_visualizer.dart';
import 'services/open_interest_api.dart';
import 'enhanced_strategy_demo.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OI Visualizer Demo',
      theme: OITheme.lightTheme, // Use OI theme
      darkTheme: OITheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const OIVisualizerDemo(),
    );
  }
}

class OIVisualizerDemo extends StatefulWidget {
  const OIVisualizerDemo({super.key});

  @override
  State<OIVisualizerDemo> createState() => _OIVisualizerDemoState();
}

class _OIVisualizerDemoState extends State<OIVisualizerDemo> {
  int _selectedIndex = 0;
  late OpenInterestApi _api;
  TransformedData? _transformedData;
  String? _selectedExpiry;
  bool isDataGatting = true;

  // Demo configuration
  final String _baseUrl = 'http://10.90.176.200:6123'; // Backend server URL
  final String _underlying = 'NIFTY';

  @override
  void initState() {
    super.initState();
    _api = OpenInterestApi(baseUrl: _baseUrl);
    _loadDemoData();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _loadDemoData() async {
    try {
      final data = await _api.getOpenInterest(_underlying);
      setState(() {
        _transformedData = data;
        _selectedExpiry =
            data.filteredExpiries?.isNotEmpty == true
                ? data.filteredExpiries?.first
                : null;
      });
    } catch (e) {
      debugPrint('Error loading demo data: $e');
      // Create demo data if API fails
      _createDemoData();
    }
    setState(() {
      isDataGatting = false;
    });
  }

  void _createDemoData() {
    final demoData = TransformedData(
      underlying: _underlying,
      grouped: {
        '2024-03-28': GroupedDataItem(
          atmStrike: 21000,
          atmIV: 18.5,
          syntheticFuturesPrice: 21050.5,
          data: List.generate(
            10,
            (i) => DataItem(
              strikePrice: 20500 + (i * 100).toDouble(),
              expiryDate: '2024-03-28',
              pe: _createSampleContractData(),
              ce: _createSampleContractData(),
              syntheticFuturesPrice: 21050.5,
              iv: 18.5,
            ),
          ),
        ),
      },
      filteredExpiries: ['2024-03-28', '2024-04-25'],
      allExpiries: ['2024-03-28', '2024-04-25', '2024-05-30'],
      strikePrices: List.generate(11, (i) => 20500 + (i * 100).toDouble()),
      underlyingValue: 21050.5,
    );

    setState(() {
      _transformedData = demoData;
      _selectedExpiry = '2024-03-28';
    });
  }

  ContractData _createSampleContractData() {
    return ContractData(
      askPrice: 155.5,
      askQty: 100,
      bidprice: 154.0,
      bidQty: 200,
      change: 2.5,
      changeinOpenInterest: 500,
      expiryDate: '2024-03-28',
      identifier: 'NIFTY24MAR21000CE',
      impliedVolatility: 18.5,
      lastPrice: 155.0,
      openInterest: 10000,
      pChange: 1.64,
      pchangeinOpenInterest: 5.26,
      strikePrice: 21000,
      totalBuyQuantity: 1500,
      totalSellQuantity: 1200,
      totalTradedVolume: 2500,
      underlying: 'NIFTY',
      underlyingValue: 21050.5,
      greeks: const Greeks(
        delta: 0.5,
        gamma: 0.02,
        theta: -0.05,
        vega: 0.15,
        rho: 0.01,
      ),
    );
  }

  Map<String, double>? getFuturesPerExpiry() {
    if (_transformedData?.grouped == null) return null;
    Map<String, double> data = {};

    for (var e in (_transformedData?.grouped ?? {}).keys) {
      data[e] = (_transformedData?.grouped ?? {})[e]?.syntheticFuturesPrice ?? 0;
    }

    return data;
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900; // tweak threshold
    final destinations = const [
      (icon: Icons.bar_chart, label: 'Open Interest'),
      (icon: Icons.build, label: 'Strategy Builder'),
      (icon: Icons.timeline, label: 'Enhanced P&L Chart'),
    ];

    final content =
        isDataGatting
            ? Center(child: CircularProgressIndicator())
            : IndexedStack(
              index: _selectedIndex,
              children: [
                OpenInterestView(
                  underlying: _underlying,
                  data: _transformedData!,
                ),
                StrategyBuilderView(
                  underlying: _underlying,
                  optionChainData:
                      _transformedData?.grouped != null
                          ? _transformedData?.grouped![_selectedExpiry]?.data
                          : [],
                  expiries: _transformedData?.filteredExpiries ?? [],
                  selectedExpiry: _selectedExpiry,
                  underlyingPrice: _transformedData?.underlyingValue,
                  oiData: _transformedData?.grouped![_selectedExpiry]?.data,
                  onCalculatePnl:
                      ({
                        required underlyingPrice,
                        required targetUnderlyingPrice,
                        required targetDateTimeISOString,
                        required optionLegs,
                      }) => _api.getBuilderData(
                        underlyingPrice: underlyingPrice,
                        targetUnderlyingPrice: targetUnderlyingPrice,
                        targetDateTimeISOString: targetDateTimeISOString,
                        futuresPerExpiry: getFuturesPerExpiry(),
                        optionLegs: optionLegs,
                        lotSize: 25,
                        isIndex: true,
                      ),
                  // nextUpdateAt: 'Next update in 5 minutes',
                  onExpiryChanged: (expiry) {
                    setState(() {
                      _selectedExpiry = expiry;
                    });
                  },
                ),
                const EnhancedStrategyDemo(),
              ],
            );

    // Wide screens → NavigationRail on the left
    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              labelType: NavigationRailLabelType.selected,
              leading: const SizedBox(height: 8),
              destinations:
                  destinations
                      .map(
                        (d) => NavigationRailDestination(
                          icon: Icon(d.icon),
                          selectedIcon: Icon(d.icon),
                          label: Text(d.label),
                        ),
                      )
                      .toList(),
            ),
            const VerticalDivider(width: 1),
            // Main content
            Expanded(child: content),
          ],
        ),
      );
    }

    // Phones → bottom NavigationBar
    return Scaffold(
      body: content,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations:
            destinations
                .map(
                  (d) =>
                      NavigationDestination(icon: Icon(d.icon), label: d.label),
                )
                .toList(),
      ),
    );
  }
}



/// Complete usage example demonstrating all features of the Advanced P&L Chart
class AdvancedChartExample extends StatefulWidget {
  const AdvancedChartExample({super.key});

  @override
  State<AdvancedChartExample> createState() => _AdvancedChartExampleState();
}

class _AdvancedChartExampleState extends State<AdvancedChartExample> {
  BuilderData? _builderData;
  List<OptionLeg> _optionLegs = [];
  List<DataItem>? _oiData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Simulate API call to fetch builder data and OI data
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _builderData = _createSampleBuilderData();
      _optionLegs = _createSampleOptionLegs();
      _oiData = _createSampleOIData();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Option Chart Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Reload Data',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Chart takes most of the screen
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: AdvancedPNLChart(
                        builderData: _builderData,
                        optionLegs: _optionLegs,
                        oiData: _oiData,
                        impliedVolatility: 0.25, // 25% IV
                        daysToExpiration: 30,
                        greeks: {
                          'delta': 0.456,
                          'gamma': 0.023,
                          'theta': -12.5,
                          'vega': 45.2,
                        },
                        onRetry: _loadData,
                      ),
                    ),
                  ),

                  // Legs management panel
                  Expanded(flex: 1, child: _buildLegsPanel()),
                ],
              ),
    );
  }

  Widget _buildLegsPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Option Legs',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _addLeg,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Leg'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _optionLegs.length,
              itemBuilder: (context, index) {
                final leg = _optionLegs[index];
                return _buildLegCard(leg, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegCard(OptionLeg leg, int index) {
    final isActive = leg.active ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isActive ? 2 : 0,
      color:
          isActive
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Active toggle
            Switch(
              value: isActive,
              onChanged: (value) {
                setState(() {
                  _optionLegs[index] = OptionLeg(
                    // Copy all properties with updated active status
                    active: value,
                  );
                });
              },
            ),
            const SizedBox(width: 12),

            // Leg details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getLegColor(leg).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getLegLabel(leg),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getLegColor(leg),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Strike: ${leg.strike ?? 'N/A'}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Premium: ${leg.price ?? 'N/A'} | Qty: ${leg.lots ?? 1}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),

            // Remove button
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () {
                setState(() {
                  _optionLegs.removeAt(index);
                });
              },
              color: Theme.of(context).colorScheme.error,
            ),
          ],
        ),
      ),
    );
  }

  String _getLegLabel(OptionLeg leg) {
    final position = leg.price ?? 'LONG';
    final type = leg.type ?? 'CALL';
    return '$position $type';
  }

  Color _getLegColor(OptionLeg leg) {
    final isCall = (leg.type ?? 'CALL') == 'CALL';
    final isLong = (leg.price ?? 'LONG') == 'LONG';

    if (isCall && isLong) return Colors.green;
    if (isCall && !isLong) return Colors.red;
    if (!isCall && isLong) return Colors.blue;
    return Colors.orange;
  }

  void _addLeg() {
    setState(() {
      _optionLegs.add(
        OptionLeg(
          active: true,
          action: OptionAction.sell, // Short position
          expiry: "30-Dec-2025",
          strike: 24500.0,
          type: OptionType.put,
          lots: 1,
          price: 200.0,
          iv: 0.24,
        ),
      );
    });
  }

  // Sample data generators
  BuilderData _createSampleBuilderData() {
    // Create Iron Condor sample data
    final payoffsAtExpiry = <PayoffAt>[];
    final payoffsAtTarget = <PayoffAt>[];

    const underlyingPrice = 24836.3;
    const xMin = 22500.0;
    const xMax = 27500.0;
    const numPoints = 100;

    for (int i = 0; i <= numPoints; i++) {
      final price = xMin + (xMax - xMin) * i / numPoints;

      // Iron Condor: Sell 24500 Put, Buy 24000 Put, Sell 25500 Call, Buy 26000 Call
      double payoff = 0;

      // Short 24500 Put
      payoff -= math.max(24500 - price, 0) - 200;
      // Long 24000 Put
      payoff += math.max(24000 - price, 0) - 100;
      // Short 25500 Call
      payoff -= math.max(price - 25500, 0) - 180;
      // Long 26000 Call
      payoff += math.max(price - 26000, 0) - 80;

      payoff *= 100; // Contract multiplier

      payoffsAtExpiry.add(PayoffAt(at: price, payoff: payoff));

      // Target payoff (with time value)
      final targetPayoff = payoff * 0.7; // Simulate time decay
      payoffsAtTarget.add(PayoffAt(at: price, payoff: targetPayoff));
    }

    return BuilderData(
      payoffsAtExpiry: payoffsAtExpiry,
      payoffsAtTarget: payoffsAtTarget,
      xMin: xMin,
      xMax: xMax,
      underlyingPrice: underlyingPrice,
      targetUnderlyingPrice: 25100.0,
      payoffAtTarget: 11100.0,
      payoffAtExpiry: 15000.0,
    );
  }

  List<OptionLeg> _createSampleOptionLegs() {
    return [
      OptionLeg(
        active: true,
        action: OptionAction.sell, // Short position
        expiry: "30-Dec-2025",
        strike: 24500.0,
        type: OptionType.put,
        lots: 1,
        price: 200.0,
        iv: 0.24,
      ),
    ];
  }

  List<DataItem> _createSampleOIData() {
    // Create sample Open Interest data
    final oiData = <DataItem>[];
    const baseStrike = 22500.0;
    const strikeInterval = 100.0;
    const numStrikes = 50;

    for (int i = 0; i < numStrikes; i++) {
      final strike = baseStrike + (strikeInterval * i);

      // Simulate OI distribution (higher near ATM)
      final distanceFromATM = (strike - 24836.3).abs();
      final oiFactor = math.exp(-distanceFromATM / 1000);

      oiData.add(
        DataItem(
          strikePrice: strike,
          expiryDate:
              DateTime.now().add(const Duration(days: 30)).toIso8601String(),
          ce: ContractData(
            openInterest:
                (50000 +
                        100000 *
                            oiFactor *
                            (0.5 + math.Random().nextDouble() * 0.5))
                    .toInt(),
            changeinOpenInterest:
                (-5000 + 10000 * (math.Random().nextDouble() - 0.5)),
            impliedVolatility: 0.22 + 0.06 * math.Random().nextDouble(),
          ),
          pe: ContractData(
            openInterest:
                (60000 +
                        120000 *
                            oiFactor *
                            (0.5 + math.Random().nextDouble() * 0.5))
                    .toInt(),
            changeinOpenInterest:
                (-6000 + 12000 * (math.Random().nextDouble() - 0.5)),
            impliedVolatility: 0.24 + 0.06 * math.Random().nextDouble(),
          ),
        ),
      );
    }

    return oiData;
  }
}

/// INTEGRATION GUIDE
/// 
/// 1. BASIC USAGE:
/// ```dart
/// AdvancedPNLChart(
///   builderData: builderData,  // Required: P&L calculation data
///   optionLegs: optionLegs,    // Required: List of option positions
/// )
/// ```
/// 
/// 2. WITH ALL FEATURES:
/// ```dart
/// AdvancedPNLChart(
///   builderData: builderData,
///   optionLegs: optionLegs,
///   oiData: oiData,                    // Open Interest background chart
///   impliedVolatility: 0.25,           // For probability cone
///   daysToExpiration: 30,              // For probability cone
///   greeks: {                          // Portfolio Greeks
///     'delta': 0.456,
///     'gamma': 0.023,
///     'theta': -12.5,
///     'vega': 45.2,
///   },
///   onRetry: _handleRetry,             // Error retry callback
/// )
/// ```
/// 
/// 3. GESTURE CONTROLS:
/// 
/// WEB:
/// - Mouse hover: Show crosshair and tooltip
/// - Mouse wheel: Zoom in/out
/// - Click + drag: Pan chart
/// - Ctrl + wheel: Fine zoom control
/// 
/// MOBILE:
/// - Long press: Show crosshair
/// - Pinch: Zoom in/out
/// - Two-finger drag: Pan chart
/// - Double tap: Reset zoom
/// 
/// 4. INTERACTIVE FEATURES:
/// - Toggle OI Chart: Shows Call/Put open interest bars
/// - Toggle Probability Cone: Shows 1σ, 2σ, 3σ price ranges
/// - Toggle Greeks Panel: Shows portfolio Greeks overlay
/// - Show/Hide Max P&L lines
/// - Change in OI vs Total OI display
/// 
/// 5. CHART ELEMENTS:
/// - Green/Red gradient line: P&L at expiry
/// - Blue line: P&L at target date
/// - Orange circles: Breakeven points
/// - Purple dashed line: Current underlying price
/// - Green/Red solid line: Target price
/// - Light blue bands: Probability cone (68%, 95%, 99.7%)
/// - Background bars: Call (red) and Put (green) open interest
/// 
/// 6. CUSTOMIZATION:
/// The painter accepts these boolean flags:
/// - showOIChart: Display OI background
/// - showChangeInOI: OI change vs total OI
/// - showProbabilityCone: Statistical price bands
/// - showMaxProfitLoss: Max profit/loss horizontal lines
/// - showGreeksPanel: Greeks overlay panel
/// 
/// 7. PERFORMANCE OPTIMIZATION:
/// - Chart automatically uses RepaintBoundary
/// - Crosshair updates are throttled
/// - Path caching for complex shapes
/// - Efficient hit testing for gestures
/// - Separate web/mobile gesture handlers
/// 
/// 8. RESPONSIVE DESIGN:
/// - Adapts to container size automatically
/// - Maintains proper aspect ratio
/// - Touch targets sized appropriately for mobile
/// - Tooltip positioning adjusts to screen edges
/// 
/// 9. DATA REQUIREMENTS:
/// 
/// BuilderData must contain:
/// - payoffsAtExpiry: List of price/payoff pairs at expiration
/// - payoffsAtTarget: List of price/payoff pairs at target date
/// - xMin/xMax: Price range for X-axis
/// - underlyingPrice: Current asset price
/// - targetUnderlyingPrice: Target price (optional)
/// - payoffAtTarget/payoffAtExpiry: P&L at specific prices (optional)
/// 
/// OI Data (optional):
/// - List<DataItem> with CE/PE contract data
/// - Each item should have strikePrice, openInterest, changeinOpenInterest
/// 
/// 10. ERROR HANDLING:
/// - Graceful degradation if data is incomplete
/// - Empty state when no option legs active
/// - Loading state during data fetch
/// - Retry mechanism on error
/// 
/// 11. ACCESSIBILITY:
/// - Semantic labels for interactive elements
/// - Keyboard navigation support (web)
/// - High contrast mode support
/// - Screen reader compatible tooltips
/// 
/// 12. ADVANCED FEATURES:
/// 
/// Multi-leg Strategy Support:
/// - Unlimited number of legs
/// - Mix of calls, puts, long, short
/// - Different strikes and expirations
/// - Real-time P&L aggregation
/// 
/// Greeks Display:
/// - Delta: Directional exposure
/// - Gamma: Curvature risk
/// - Theta: Time decay per day
/// - Vega: Volatility sensitivity
/// 
/// Probability Analysis:
/// - 1 standard deviation: 68% probability
/// - 2 standard deviations: 95% probability
/// - 3 standard deviations: 99.7% probability
/// - Based on implied volatility and DTE
/// 
/// 13. STRATEGY EXAMPLES:
/// 
/// Bull Call Spread:
/// ```dart
/// optionLegs: [
///   OptionLeg(active: true, strike: 24500, premium: 300, 
///             optionType: 'CALL', position: 'LONG'),
///   OptionLeg(active: true, strike: 25500, premium: 150,
///             optionType: 'CALL', position: 'SHORT'),
/// ]
/// ```
/// 
/// Iron Condor:
/// ```dart
/// optionLegs: [
///   OptionLeg(active: true, strike: 24000, premium: 100,
///             optionType: 'PUT', position: 'LONG'),
///   OptionLeg(active: true, strike: 24500, premium: 200,
///             optionType: 'PUT', position: 'SHORT'),
///   OptionLeg(active: true, strike: 25500, premium: 180,
///             optionType: 'CALL', position: 'SHORT'),
///   OptionLeg(active: true, strike: 26000, premium: 80,
///             optionType: 'CALL', position: 'LONG'),
/// ]
/// ```
/// 
/// Straddle:
/// ```dart
/// optionLegs: [
///   OptionLeg(active: true, strike: 25000, premium: 400,
///             optionType: 'CALL', position: 'LONG'),
///   OptionLeg(active: true, strike: 25000, premium: 380,
///             optionType: 'PUT', position: 'LONG'),
/// ]
/// ```
/// 
/// 14. THEMING:
/// Chart automatically adapts to:
/// - Light/Dark theme
/// - Material 3 color scheme
/// - Custom theme colors
/// - Dynamic color support
/// 
/// 15. EXPORT CAPABILITIES (Future):
/// - Screenshot functionality
/// - PDF export
/// - CSV data export
/// - Share strategy link