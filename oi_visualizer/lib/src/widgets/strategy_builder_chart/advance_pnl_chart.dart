import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:oi_visualizer/src/models/builder_data.dart';
import 'package:oi_visualizer/src/models/data_item.dart';
import 'package:oi_visualizer/src/models/option_leg.dart';
import 'package:oi_visualizer/src/utils/chart_utils.dart';
import 'advanced_option_chart_painter.dart';

class AdvancedPNLChart extends StatefulWidget {
  final BuilderData? builderData;
  final List<OptionLeg> optionLegs;
  final List<DataItem>? oiData;
  final double? impliedVolatility;
  final int? daysToExpiration;
  final Map<String, double>? greeks;
  final VoidCallback? onRetry;

  const AdvancedPNLChart({
    super.key,
    this.builderData,
    this.optionLegs = const [],
    this.oiData,
    this.impliedVolatility,
    this.daysToExpiration,
    this.greeks,
    this.onRetry,
  });

  @override
  State<AdvancedPNLChart> createState() => _AdvancedPNLChartState();
}

class _AdvancedPNLChartState extends State<AdvancedPNLChart>
    with SingleTickerProviderStateMixin {
  // Crosshair state
  Offset? _crosshairPosition;
  bool _showTooltip = false;
  Map<String, double>? _crosshairValues;

  // Chart settings
  bool _showOIChart = true;
  bool _showChangeInOI = false;
  bool _showProbabilityCone = false;
  bool _showMaxProfitLoss = true;
  bool _showGreeksPanel = false;

  // Zoom and pan state
  double _zoomLevel = 1.0;
  Offset _panOffset = Offset.zero;
  double _baseZoomLevel = 1.0;
  Offset _basePanOffset = Offset.zero;
  Offset? _lastFocalPoint;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildContent(),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 50,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Icon(
                    Icons.insights,
                    size: 24,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Advanced P&L Visualizer',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildQuickActions(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildStrategyInfo(),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(_showOIChart ? Icons.bar_chart : Icons.bar_chart_outlined),
          tooltip: 'Toggle OI Chart',
          onPressed: () {
            setState(() {
              _showOIChart = !_showOIChart;
            });
          },
          color: _showOIChart ? Theme.of(context).colorScheme.primary : null,
        ),
        IconButton(
          icon: Icon(_showProbabilityCone ? Icons.blur_on : Icons.blur_off),
          tooltip: 'Toggle Probability Cone',
          onPressed: () {
            setState(() {
              _showProbabilityCone = !_showProbabilityCone;
            });
          },
          color: _showProbabilityCone ? Theme.of(context).colorScheme.primary : null,
        ),
        IconButton(
          icon: Icon(_showGreeksPanel ? Icons.functions : Icons.functions_outlined),
          tooltip: 'Toggle Greeks Panel',
          onPressed: () {
            setState(() {
              _showGreeksPanel = !_showGreeksPanel;
            });
          },
          color: _showGreeksPanel ? Theme.of(context).colorScheme.primary : null,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          tooltip: 'More Options',
          onSelected: (value) {
            setState(() {
              switch (value) {
                case 'change_oi':
                  _showChangeInOI = !_showChangeInOI;
                  break;
                case 'max_pl':
                  _showMaxProfitLoss = !_showMaxProfitLoss;
                  break;
                case 'reset_zoom':
                  _resetZoomAndPan();
                  break;
              }
            });
          },
          itemBuilder: (context) => [
            CheckedPopupMenuItem(
              value: 'change_oi',
              checked: _showChangeInOI,
              child: const Text('Show Change in OI'),
            ),
            CheckedPopupMenuItem(
              value: 'max_pl',
              checked: _showMaxProfitLoss,
              child: const Text('Show Max P&L'),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'reset_zoom',
              child: Text('Reset Zoom'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStrategyInfo() {
    final activeLegs = widget.optionLegs.where((leg) => leg.active ?? false).toList();
    
    if (activeLegs.isEmpty || widget.builderData == null) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _buildInfoChip(
          'Legs',
          '${activeLegs.length}',
          Icons.layers,
          Colors.blue,
        ),
        if (widget.builderData?.payoffAtTarget != null)
          _buildInfoChip(
            'Target P&L',
            ChartUtils.formatLargeNumber(
              widget.builderData!.payoffAtTarget!,
              showSign: true,
            ),
            Icons.flag,
            widget.builderData!.payoffAtTarget! >= 0 ? Colors.green : Colors.red,
          ),
        if (widget.builderData?.payoffAtExpiry != null)
          _buildInfoChip(
            'Expiry P&L',
            ChartUtils.formatLargeNumber(
              widget.builderData!.payoffAtExpiry!,
              showSign: true,
            ),
            Icons.calendar_today,
            widget.builderData!.payoffAtExpiry! >= 0 ? Colors.green : Colors.red,
          ),
        if (widget.daysToExpiration != null)
          _buildInfoChip(
            'DTE',
            '${widget.daysToExpiration}d',
            Icons.timer,
            Colors.orange,
          ),
        if (widget.impliedVolatility != null)
          _buildInfoChip(
            'IV',
            '${(widget.impliedVolatility! * 100).toStringAsFixed(1)}%',
            Icons.show_chart,
            Colors.purple,
          ),
      ],
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final activeLegs = widget.optionLegs.where((leg) => leg.active ?? false).toList();

    if (activeLegs.isEmpty) {
      return _buildEmptyState();
    }

    if (widget.builderData == null) {
      return _buildLoadingState();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return _buildInteractiveChart(constraints);
        },
      ),
    );
  }

  Widget _buildInteractiveChart(BoxConstraints constraints) {
    return Stack(
      children: [
        // Main chart with gesture detection
        kIsWeb ? _buildWebGestureDetector(constraints) : _buildMobileGestureDetector(constraints),
        
        // Crosshair tooltip overlay
        if (_showTooltip && _crosshairPosition != null && _crosshairValues != null)
          Positioned(
            left: _crosshairPosition!.dx + 15,
            top: (_crosshairPosition!.dy - 120).clamp(10, constraints.maxHeight - 130),
            child: _buildTooltip(),
          ),
      ],
    );
  }

  Widget _buildWebGestureDetector(BoxConstraints constraints) {
    return MouseRegion(
      cursor: SystemMouseCursors.precise,
      onHover: (event) => _handlePointerMove(event.localPosition, constraints),
      onExit: (_) => _clearCrosshair(),
      child: Listener(
        onPointerSignal: (event) {
          if (event is PointerScrollEvent) {
            _handleMouseScroll(event, constraints);
          }
        },
        child: GestureDetector(
          onPanStart: (details) => _handlePanStart(details.localPosition),
          onPanUpdate: (details) => _handlePanUpdate(details.localPosition, details.delta),
          onPanEnd: (_) => {},
          child: _buildChartCanvas(constraints),
        ),
      ),
    );
  }

  Widget _buildMobileGestureDetector(BoxConstraints constraints) {
    return GestureDetector(
      onScaleStart: (details) {
        _baseZoomLevel = _zoomLevel;
        _basePanOffset = _panOffset;
        _lastFocalPoint = details.localFocalPoint;
      },
      onScaleUpdate: (details) {
        setState(() {
          // Handle zoom
          _zoomLevel = (_baseZoomLevel * details.scale).clamp(0.5, 3.0);

          // Handle pan
          if (_lastFocalPoint != null) {
            final delta = details.localFocalPoint - _lastFocalPoint!;
            _panOffset = _basePanOffset + delta;
            
            // Constrain pan within bounds
            const margin = 60.0;
            final maxPanX = (constraints.maxWidth - 2 * margin) * (_zoomLevel - 1) / 2;
            final maxPanY = (constraints.maxHeight - 2 * margin) * (_zoomLevel - 1) / 2;
            
            _panOffset = Offset(
              _panOffset.dx.clamp(-maxPanX, maxPanX),
              _panOffset.dy.clamp(-maxPanY, maxPanY),
            );
          }
        });
      },
      onScaleEnd: (_) {
        _lastFocalPoint = null;
      },
      onLongPressStart: (details) {
        _handlePointerMove(details.localPosition, constraints);
      },
      onLongPressMoveUpdate: (details) {
        _handlePointerMove(details.localPosition, constraints);
      },
      onLongPressEnd: (_) {
        _clearCrosshair();
      },
      child: _buildChartCanvas(constraints),
    );
  }

  Widget _buildChartCanvas(BoxConstraints constraints) {
    return CustomPaint(
      size: Size(constraints.maxWidth, constraints.maxHeight),
      painter: AdvancedOptionChartPainter(
        data: widget.builderData!,
        context: context,
        crosshairPosition: _crosshairPosition,
        oiData: widget.oiData,
        showOIChart: _showOIChart,
        showChangeInOI: _showChangeInOI,
        showProbabilityCone: _showProbabilityCone,
        impliedVolatility: widget.impliedVolatility,
        daysToExpiration: widget.daysToExpiration,
        showMaxProfitLoss: _showMaxProfitLoss,
        showGreeksPanel: _showGreeksPanel,
        greeks: widget.greeks,
      ),
    );
  }

  void _handlePointerMove(Offset position, BoxConstraints constraints) {
    const margin = 60.0;
    
    // Check if within chart bounds
    if (position.dx < margin || 
        position.dx > constraints.maxWidth - margin ||
        position.dy < margin || 
        position.dy > constraints.maxHeight - margin) {
      _clearCrosshair();
      return;
    }

    // Calculate chart values
    final xMin = widget.builderData!.xMin ?? 0.0;
    final xMax = widget.builderData!.xMax ?? 100.0;
    final xRange = xMax - xMin;
    final chartWidth = constraints.maxWidth - 2 * margin;

    final relativeX = (position.dx - margin) / chartWidth;
    final underlyingPrice = xMin + relativeX * xRange;

    // Interpolate P&L values
    final expiryPayoff = _interpolatePayoff(
      widget.builderData!.payoffsAtExpiry ?? [],
      underlyingPrice,
    );
    final targetPayoff = _interpolatePayoff(
      widget.builderData!.payoffsAtTarget ?? [],
      underlyingPrice,
    );

    setState(() {
      _crosshairPosition = position;
      _showTooltip = true;
      _crosshairValues = {
        'price': underlyingPrice,
        'expiryPayoff': expiryPayoff ?? 0,
        'targetPayoff': targetPayoff ?? 0,
      };
    });
  }

  void _handleMouseScroll(PointerScrollEvent event, BoxConstraints constraints) {
    setState(() {
      final scrollDelta = event.scrollDelta.dy;
      final zoomFactor = scrollDelta > 0 ? 0.95 : 1.05;
      _zoomLevel = (_zoomLevel * zoomFactor).clamp(0.5, 3.0);
    });
  }

  void _handlePanStart(Offset position) {
    _basePanOffset = _panOffset;
  }

  void _handlePanUpdate(Offset position, Offset delta) {
    setState(() {
      _panOffset = _basePanOffset + delta;
    });
  }

  void _clearCrosshair() {
    setState(() {
      _crosshairPosition = null;
      _showTooltip = false;
      _crosshairValues = null;
    });
  }

  void _resetZoomAndPan() {
    setState(() {
      _zoomLevel = 1.0;
      _panOffset = Offset.zero;
    });
  }

  double? _interpolatePayoff(List<PayoffAt> payoffs, double price) {
    if (payoffs.isEmpty) return null;

    PayoffAt? before;
    PayoffAt? after;

    for (final payoff in payoffs) {
      if (payoff.at == null || payoff.payoff == null) continue;

      if (payoff.at! <= price) {
        if (before == null || payoff.at! > before.at!) {
          before = payoff;
        }
      } else {
        if (after == null || payoff.at! < after.at!) {
          after = payoff;
        }
      }
    }

    if (before == null && after == null) return null;
    if (before == null) return after!.payoff;
    if (after == null) return before.payoff;

    final ratio = (price - before.at!) / (after.at! - before.at!);
    return before.payoff! + ratio * (after.payoff! - before.payoff!);
  }

  Widget _buildTooltip() {
    if (_crosshairValues == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final price = _crosshairValues!['price']!;
    final expiryPayoff = _crosshairValues!['expiryPayoff']!;
    final targetPayoff = _crosshairValues!['targetPayoff']!;

    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(12),
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 240),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Analysis',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTooltipRow(
              'Price',
              price.toStringAsFixed(2),
              Icons.attach_money,
              theme.colorScheme.onSurface,
            ),
            const SizedBox(height: 8),
            _buildTooltipRow(
              'P&L at Expiry',
              ChartUtils.formatLargeNumber(expiryPayoff, showSign: true),
              Icons.calendar_month,
              expiryPayoff >= 0 ? Colors.green.shade600 : Colors.red.shade600,
            ),
            const SizedBox(height: 8),
            _buildTooltipRow(
              'P&L at Target',
              ChartUtils.formatLargeNumber(targetPayoff, showSign: true),
              Icons.flag,
              targetPayoff >= 0 ? Colors.green.shade600 : Colors.red.shade600,
            ),
            if (widget.greeks != null) ...[
              const Divider(height: 16),
              Text(
                'Position Greeks',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (widget.greeks!['delta'] != null)
                    _buildGreekChip('Δ', widget.greeks!['delta']!, Colors.blue),
                  if (widget.greeks!['gamma'] != null)
                    _buildGreekChip('Γ', widget.greeks!['gamma']!, Colors.purple),
                  if (widget.greeks!['theta'] != null)
                    _buildGreekChip('Θ', widget.greeks!['theta']!, Colors.orange),
                  if (widget.greeks!['vega'] != null)
                    _buildGreekChip('ν', widget.greeks!['vega']!, Colors.green),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTooltipRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildGreekChip(String symbol, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$symbol: ${value.toStringAsFixed(3)}',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    if (_zoomLevel == 1.0 && _panOffset == Offset.zero) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.zoom_in,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8),
          Text(
            'Zoom: ${(_zoomLevel * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(width: 16),
          TextButton.icon(
            onPressed: _resetZoomAndPan,
            icon: const Icon(Icons.restore, size: 16),
            label: const Text('Reset View'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.addchart,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No Active Options',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add option legs to visualize your strategy',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Calculating payoff...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}