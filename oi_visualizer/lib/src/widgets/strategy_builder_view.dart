import 'package:flutter/material.dart';
import 'package:oi_visualizer/src/widgets/strategy_builder_chart/advance_pnl_chart.dart';
import '../models/builder_data.dart';
import '../models/option_leg.dart';
import '../models/data_item.dart';
import '../theme/oi_theme.dart';
import 'pnl_visualizer.dart';
import 'pnl_controls.dart';
import 'strategy_widget.dart';
import 'add_edit_legs.dart';

class StrategyBuilderView extends StatefulWidget {
  final String underlying;
  final List<DataItem>? optionChainData;
  final List<String> expiries;
  final String? selectedExpiry;
  final double? underlyingPrice;
  final Future<BuilderData> Function({
    required double? underlyingPrice,
    required double? targetUnderlyingPrice,
    required String targetDateTimeISOString,
    required List<ActiveOptionLeg> optionLegs,
  })
  onCalculatePnl;
  final String? nextUpdateAt;
  final ValueChanged<String>? onExpiryChanged;
  final List<DataItem>? oiData;

  const StrategyBuilderView({
    super.key,
    required this.underlying,
    this.optionChainData,
    required this.expiries,
    this.selectedExpiry,
    this.underlyingPrice,
    required this.onCalculatePnl,
    this.nextUpdateAt,
    this.onExpiryChanged,
    this.oiData,
  });

  @override
  State<StrategyBuilderView> createState() => _StrategyBuilderViewState();
}

class _StrategyBuilderViewState extends State<StrategyBuilderView> {
  BuilderData? _data;
  bool _isLoading = false;
  String? _error;

  final List<OptionLeg> _optionLegs = [];
  double? _targetUnderlyingPrice;
  DateTime _targetDateTime = DateTime.now().add(const Duration(days: 30));
  bool _showAddEditDrawer = false;

  @override
  void initState() {
    super.initState();
    _targetUnderlyingPrice = widget.underlyingPrice;
  }

  @override
  void didUpdateWidget(StrategyBuilderView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.underlyingPrice != oldWidget.underlyingPrice) {
      _targetUnderlyingPrice = widget.underlyingPrice;
    }
  }

  Future<void> _calculatePNL() async {
    if (_optionLegs.isEmpty || widget.underlyingPrice == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final activeLegs =
          _optionLegs
              .where((leg) => leg.active == true)
              .map(
                (leg) => ActiveOptionLeg(
                  action: leg.action,
                  expiry: leg.expiry,
                  strike: leg.strike,
                  type: leg.type,
                  lots: leg.lots,
                  price: leg.price,
                  iv: leg.iv,
                ),
              )
              .toList();

      final data = await widget.onCalculatePnl(
        underlyingPrice: widget.underlyingPrice,
        targetUnderlyingPrice: _targetUnderlyingPrice,
        targetDateTimeISOString: _targetDateTime.toIso8601String(),
        optionLegs: activeLegs,
      );

      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = constraints.maxWidth >= 1024; // lg breakpoint
          return Stack(
            children: [
              if (isLargeScreen)
                _buildDesktopLayout()
              else
                _buildMobileLayout(),
              Positioned(
                right: 0,
                bottom: 0,
                top: isLargeScreen ? 0 : 200,
                left: isLargeScreen ? null : 0,
                child: SizedBox(
                  width:
                      isLargeScreen
                          ? MediaQuery.of(context).size.width * 0.3
                          : MediaQuery.of(context).size.width,
                  child: _buildFloatingDrawer(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left sidebar - Menu (Strategy)
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.31, // 3.7/12 = ~31%
            child: Container(
              height: MediaQuery.of(context).size.height - 160,
              child: _buildMenuSection(),
            ),
          ),
          const SizedBox(width: 15),

          // Right content - PNL Visualizer and Controls
          Expanded(
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(
                      OITheme.defaultBorderRadius,
                    ),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // PNL Visualizer
                      if(_data != null)
                      AdvancedPNLChart(
                        builderData: _data,
                        optionLegs: _optionLegs,
                        oiData: widget.oiData,
                      ),
                      // PNLVisualizer(
                      //   data: _data,
                      //   optionLegs: _optionLegs,
                      //   isLoading: _isLoading,
                      //   isError: _error != null,
                      //   errorMessage: _error,
                      //   onCalculatePNL: _calculatePNL,
                      //   oiData: widget.oiData,
                      // ),
                      if ((_data?.projectedFuturesPrices ?? []).isNotEmpty) ...[
                        SizedBox(height: 20),

                        // PNL Controls
                        PNLControls(
                          optionLegs: _optionLegs,
                          underlyingPrice: widget.underlyingPrice,
                          targetUnderlyingPrice: _targetUnderlyingPrice,
                          targetDateTime: _targetDateTime,
                          projectedFuturePrices: _data?.projectedFuturesPrices,
                          onTargetPriceChanged: (price) {
                            setState(() {
                              _targetUnderlyingPrice = price;
                            });
                            _calculatePNL();
                          },
                          onTargetDateTimeChanged: (dateTime) {
                            setState(() {
                              _targetDateTime = dateTime;
                            });
                            _calculatePNL();
                          },
                          onResetAutoUpdate: () {
                            setState(() {
                              _targetUnderlyingPrice = widget.underlyingPrice;
                            });
                            _calculatePNL();
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildMenuSection(),
            SizedBox(height: 20),

            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(
                  OITheme.defaultBorderRadius,
                ),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // PNL Visualizer
                  PNLVisualizer(
                    data: _data,
                    optionLegs: _optionLegs,
                    isLoading: _isLoading,
                    isError: _error != null,
                    errorMessage: _error,
                    onCalculatePNL: _calculatePNL,
                    oiData: widget.oiData,
                  ),

                  if ((_data?.projectedFuturesPrices ?? []).isNotEmpty) ...[
                    SizedBox(height: 20),
                    // PNL Controls
                    PNLControls(
                      optionLegs: _optionLegs,
                      underlyingPrice: widget.underlyingPrice,
                      targetUnderlyingPrice: _targetUnderlyingPrice,
                      targetDateTime: _targetDateTime,
                      projectedFuturePrices: _data?.projectedFuturesPrices,
                      onTargetPriceChanged: (price) {
                        setState(() {
                          _targetUnderlyingPrice = price;
                        });
                      },
                      onTargetDateTimeChanged: (dateTime) {
                        setState(() {
                          _targetDateTime = dateTime;
                        });
                      },
                      onResetAutoUpdate: () {
                        setState(() {
                          _targetUnderlyingPrice = widget.underlyingPrice;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection() {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(5)),
      child: Column(
        children: [
          // Select Underlying (placeholder for now)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              children: [
                Text(
                  'Underlying: ${widget.underlying}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),

          // Strategy Widget
          StrategyWidget(
            underlying: widget.underlying,
            nextUpdateAt: widget.nextUpdateAt,
            optionLegs: _optionLegs,
            expiries: widget.expiries,
            selectedExpiry: widget.selectedExpiry,
            optionChainData: widget.optionChainData,
            onOptionLegsChanged: (legs) {
              setState(() {
                _optionLegs.clear();
                _optionLegs.addAll(legs);
              });
              _calculatePNL();
            },
            onExpiryChanged: widget.onExpiryChanged,
            onAddEditLegs: () {
              setState(() {
                _showAddEditDrawer = true;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingDrawer() {
    return _showAddEditDrawer ? _buildAddEditLegsDrawer() : SizedBox.shrink();
  }

  Widget _buildAddEditLegsDrawer() {
    if (widget.optionChainData == null) {
      return Container(
        color: Theme.of(context).colorScheme.surface,
        child: const Center(child: Text('No option chain data available')),
      );
    }

    final rows =
        widget.optionChainData!
            .map((item) => OptionChainRow.fromDataItem(item))
            .toList();

    return AddEditLegs(
      rows: rows,
      expiries: widget.expiries,
      selectedExpiry: widget.selectedExpiry,
      strikePriceATM: _calculateATMStrike(),
      optionLegs: _optionLegs,
      onExpiryChanged: widget.onExpiryChanged,
      onOptionLegsChanged: (legs) {
        setState(() {
          _optionLegs.clear();
          _optionLegs.addAll(legs);
        });
      },
      onClose: () {
        setState(() {
          _showAddEditDrawer = false;
        });
      },
    );
  }

  double? _calculateATMStrike() {
    if (widget.underlyingPrice == null || widget.optionChainData == null) {
      return null;
    }

    double? closestStrike;
    double minDifference = double.infinity;

    for (final item in widget.optionChainData!) {
      if (item.strikePrice != null) {
        final difference = (item.strikePrice! - widget.underlyingPrice!).abs();
        if (difference < minDifference) {
          minDifference = difference;
          closestStrike = item.strikePrice;
        }
      }
    }

    return closestStrike;
  }
}
