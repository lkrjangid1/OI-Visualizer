import 'dart:math';
import 'package:flutter/material.dart';
import 'package:oi_visualizer/oi_visualizer.dart';

class EnhancedStrategyDemo extends StatefulWidget {
  const EnhancedStrategyDemo({super.key});

  @override
  State<EnhancedStrategyDemo> createState() => _EnhancedStrategyDemoState();
}

class _EnhancedStrategyDemoState extends State<EnhancedStrategyDemo> {
  BuilderData? _builderData;
  List<OptionLeg> _optionLegs = [];
  List<DataItem> _oiData = [];
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _createDemoData();
  }

  void _createDemoData() {
    // Create sample OI data
    _oiData = [
      for (double strike = 20000; strike <= 22000; strike += 50)
        DataItem(
          strikePrice: strike,
          expiryDate: '2024-03-28',
          ce: ContractData(
            openInterest: _generateRandomOI(strike, 21050.5, true),
            changeinOpenInterest: _generateRandomChangeOI(),
          ),
          pe: ContractData(
            openInterest: _generateRandomOI(strike, 21050.5, false),
            changeinOpenInterest: _generateRandomChangeOI(),
          ),
        ),
    ];

    // Create sample option legs
    _optionLegs = [
      OptionLeg(
        active: true,
        action: OptionAction.buy,
        expiry: '2024-03-28',
        strike: 21000,
        type: OptionType.call,
        lots: 1,
        price: 155.0,
        iv: 18.5,
      ),
      OptionLeg(
        active: true,
        action: OptionAction.sell,
        expiry: '2024-03-28',
        strike: 21100,
        type: OptionType.call,
        lots: 1,
        price: 95.0,
        iv: 19.2,
      ),
    ];

    // Create sample P&L data for a bull call spread
    final payoffsAtExpiry = <PayoffAt>[];
    final payoffsAtTarget = <PayoffAt>[];

    // Generate payoff data from 20000 to 22000 in increments of 25
    for (double price = 20000; price <= 22000; price += 25) {
      final callBought = _calculateCallPayoff(price, 21000, 155.0, true);
      final callSold = _calculateCallPayoff(price, 21100, 95.0, false);
      final totalPayoff = callBought + callSold;

      // Apply time decay for target date (50% time decay)
      final targetPayoff = totalPayoff * 0.7; // Simplified time decay

      payoffsAtExpiry.add(PayoffAt(at: price, payoff: totalPayoff));
      payoffsAtTarget.add(PayoffAt(at: price, payoff: targetPayoff));
    }

    _builderData = BuilderData(
      payoffsAtTarget: payoffsAtTarget,
      payoffsAtExpiry: payoffsAtExpiry,
      xMin: 20000,
      xMax: 22000,
      projectedFuturesPrices: [
        ProjectedFuturesPrice(expiry: '2024-03-28', price: 21050.5),
      ],
      underlyingPrice: 21050.5,
      targetUnderlyingPrice: 21075.0,
      payoffAtTarget: 45.5,
    );
  }

  double _calculateCallPayoff(double spotPrice, double strike, double premium, bool isBuy) {
    final intrinsicValue = spotPrice > strike ? spotPrice - strike : 0.0;
    final payoff = intrinsicValue - premium;
    return isBuy ? payoff : -payoff;
  }

  int _generateRandomOI(double strike, double atmPrice, bool isCall) {
    final random = Random();

    // Generate higher OI near ATM strikes
    final distanceFromATM = (strike - atmPrice).abs();
    final normalizedDistance = distanceFromATM / 500; // Normalize by 500 points

    // Base OI decreases as we move away from ATM
    final baseOI = (50000 * (1 / (1 + normalizedDistance))).round();

    // Add some randomness
    final randomFactor = 0.5 + random.nextDouble(); // 0.5 to 1.5

    return (baseOI * randomFactor).round();
  }

  double _generateRandomChangeOI() {
    final random = Random();
    // Generate random change in OI between -5000 and +5000
    return (random.nextDouble() - 0.5) * 10000;
  }

  void _simulateLoading() {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
      });
    });
  }

  void _simulateError() {
    setState(() {
      _isLoading = false;
      _hasError = true;
    });
  }

  void _resetData() {
    setState(() {
      _hasError = false;
    });
    _createDemoData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced P&L Chart Demo'),
        actions: [
          IconButton(
            onPressed: _simulateLoading,
            icon: const Icon(Icons.refresh),
            tooltip: 'Simulate Loading',
          ),
          IconButton(
            onPressed: _simulateError,
            icon: const Icon(Icons.error),
            tooltip: 'Simulate Error',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Strategy Summary Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bull Call Spread Strategy',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Buy 21000 CE @ ₹155 | Sell 21100 CE @ ₹95',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildInfoChip('Max Profit', '₹40', Colors.green),
                        const SizedBox(width: 8),
                        _buildInfoChip('Max Loss', '₹60', Colors.red),
                        const SizedBox(width: 8),
                        _buildInfoChip('Breakeven', '₹21,060', Colors.orange),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Enhanced P&L Visualizer
            Expanded(
              child: EnhancedPNLVisualizer(
                builderData: _builderData,
                optionLegs: _optionLegs,
                isFetching: _isLoading,
                isError: _hasError,
                errorMessage: 'Failed to calculate P&L. Please try again.',
                onRetry: _resetData,
                underlyingPrice: 21050.5,
                targetUnderlyingPrice: 21075.0,
                payoffAtTarget: 45.5,
                oiData: _oiData,
              ),
            ),

            const SizedBox(height: 16),

            // Control Panel
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Interactive Features',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(
                          avatar: const Icon(Icons.mouse, size: 16),
                          label: const Text('Hover for crosshair'),
                        ),
                        Chip(
                          avatar: const Icon(Icons.info, size: 16),
                          label: const Text('Interactive tooltip'),
                        ),
                        Chip(
                          avatar: const Icon(Icons.timeline, size: 16),
                          label: const Text('Breakeven indicators'),
                        ),
                        Chip(
                          avatar: const Icon(Icons.area_chart, size: 16),
                          label: const Text('Filled areas'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}