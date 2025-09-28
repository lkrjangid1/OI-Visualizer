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
  final String _baseUrl = 'http://10.209.202.200:6123'; // Backend server URL
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
