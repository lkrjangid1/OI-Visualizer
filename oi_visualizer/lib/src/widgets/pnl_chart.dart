import 'package:flutter/material.dart';
import '../models/builder_data.dart';
import '../utils/chart_utils.dart';
import 'chart_components.dart';

class PNLChart extends StatefulWidget {
  final BuilderData data;
  final bool isFetching;
  final bool isError;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const PNLChart({
    super.key,
    required this.data,
    this.isFetching = false,
    this.isError = false,
    this.errorMessage,
    this.onRetry,
  });

  @override
  State<PNLChart> createState() => _PNLChartState();
}

class _PNLChartState extends State<PNLChart> {
  Offset? _crosshairPosition;
  bool _showTooltip = false;
  Map<String, double>? _crosshairValues;
  final GlobalKey _chartKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _chartKey,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Stack(
        children: [
          if (widget.isError)
            _buildErrorOverlay()
          else if (widget.isFetching)
            _buildLoadingOverlay()
          else
            _buildChart(),
        ],
      ),
    );
  }

  Widget _buildChart() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            ClipRRect(
              clipBehavior: Clip.hardEdge,
              child: CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: EnhancedPNLChartPainter(
                  data: widget.data,
                  context: context,
                  crosshairPosition: _crosshairPosition,
                ),
              ),
            ),
            MouseRegion(
              onHover: (event) {
                _updateCrosshair(event.localPosition, Size(constraints.maxWidth, constraints.maxHeight));
              },
              onExit: (_) {
                setState(() {
                  _crosshairPosition = null;
                  _showTooltip = false;
                  _crosshairValues = null;
                });
              },
              child: GestureDetector(
                onTapDown: (details) {
                  _updateCrosshair(details.localPosition, Size(constraints.maxWidth, constraints.maxHeight));
                },
                onPanUpdate: (details) {
                  _updateCrosshair(details.localPosition, Size(constraints.maxWidth, constraints.maxHeight));
                },
                onPanEnd: (_) {
                  setState(() {
                    _crosshairPosition = null;
                    _showTooltip = false;
                    _crosshairValues = null;
                  });
                },
                child: Stack(
                  children: [
                    Container(),
                    if (_showTooltip && _crosshairPosition != null && _crosshairValues != null)
                      _buildCrosshairTooltip(),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.3),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.1),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              widget.errorMessage ?? 'Failed to load chart data',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (widget.onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: widget.onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _updateCrosshair(Offset position, Size size) {
    const margin = 40.0;
    final chartWidth = size.width - 2 * margin;

    // Check if position is within chart area
    if (position.dx < margin || position.dx > size.width - margin ||
        position.dy < margin || position.dy > size.height - margin) {
      setState(() {
        _crosshairPosition = null;
        _showTooltip = false;
        _crosshairValues = null;
      });
      return;
    }

    // Calculate chart values at crosshair position
    final xMin = widget.data.xMin ?? 0.0;
    final xMax = widget.data.xMax ?? 100.0;
    final xRange = xMax - xMin;

    // Note: Y-axis calculations removed as they're not needed for crosshair position calculation

    // Calculate underlying price at crosshair
    final relativeX = (position.dx - margin) / chartWidth;
    final underlyingPrice = xMin + relativeX * xRange;

    // Calculate P&L values at crosshair
    final expiryPayoff = _interpolatePayoff(widget.data.payoffsAtExpiry ?? [], underlyingPrice);
    final targetPayoff = _interpolatePayoff(widget.data.payoffsAtTarget ?? [], underlyingPrice);

    setState(() {
      _crosshairPosition = position;
      _showTooltip = true;
      _crosshairValues = {
        'underlyingPrice': underlyingPrice,
        'expiryPayoff': expiryPayoff ?? 0,
        'targetPayoff': targetPayoff ?? 0,
      };
    });
  }

  double? _interpolatePayoff(List<PayoffAt> payoffs, double underlyingPrice) {
    if (payoffs.isEmpty) return null;

    // Find closest points for interpolation
    PayoffAt? before;
    PayoffAt? after;

    for (final payoff in payoffs) {
      if (payoff.at == null || payoff.payoff == null) continue;

      if (payoff.at! <= underlyingPrice) {
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

    // Linear interpolation
    final ratio = (underlyingPrice - before.at!) / (after.at! - before.at!);
    return before.payoff! + ratio * (after.payoff! - before.payoff!);
  }

  Widget _buildCrosshairTooltip() {
    if (_crosshairPosition == null || _crosshairValues == null) return Container();

    final theme = Theme.of(context);
    final values = _crosshairValues!;

    return Positioned(
      left: _crosshairPosition!.dx + 10,
      top: _crosshairPosition!.dy - 100,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Price: ${values['underlyingPrice']!.toStringAsFixed(1)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'P&L at Expiry: ${_formatPnlValue(values['expiryPayoff']!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _getPnlColor(values['expiryPayoff']!),
                ),
              ),
              Text(
                'P&L at Target: ${_formatPnlValue(values['targetPayoff']!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _getPnlColor(values['targetPayoff']!),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPnlValue(double value) {
    final sign = value >= 0 ? '+' : '';
    if (value.abs() >= 10000) {
      return '$sign${(value / 1000).toStringAsFixed(1)}K';
    }
    return '$sign${value.toStringAsFixed(0)}';
  }

  Color _getPnlColor(double value) {
    return value >= 0 ? Colors.green.shade700 : Colors.red.shade700;
  }
}

class EnhancedPNLChartPainter extends CustomPainter {
  final BuilderData data;
  final BuildContext context;
  final Offset? crosshairPosition;

  EnhancedPNLChartPainter({
    required this.data,
    required this.context,
    this.crosshairPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    const margin = 40.0;
    final chartWidth = size.width - 2 * margin;
    final chartHeight = size.height - 2 * margin;

    // Calculate scales
    final xMin = data.xMin ?? 0.0;
    final xMax = data.xMax ?? 100.0;
    final xRange = xMax - xMin;

    final payoffsAtExpiry = data.payoffsAtExpiry ?? [];
    final validPayoffs = payoffsAtExpiry
        .map((p) => p.payoff)
        .where((payoff) => payoff != null && payoff.isFinite)
        .cast<double>()
        .toList();

    // Use ChartUtils.calculateScale for proper scaling
    final scaleInfo = ChartUtils.calculateScale(validPayoffs, padding: 0.15);
    final yMin = scaleInfo.min;
    final yRange = scaleInfo.range;

    // Draw enhanced axes
    ChartAxis.drawXAxis(
      canvas: canvas,
      size: size,
      margin: margin,
      chartWidth: chartWidth,
      chartHeight: chartHeight,
      xMin: xMin,
      xRange: xRange,
      colorScheme: colorScheme,
      underlyingPrice: data.underlyingPrice,
      targetUnderlyingPrice: data.targetUnderlyingPrice,
      payoffAtTarget: data.payoffAtTarget,
    );

    ChartAxis.drawYAxis(
      canvas: canvas,
      size: size,
      margin: margin,
      chartWidth: chartWidth,
      chartHeight: chartHeight,
      yMin: yMin,
      yRange: yRange,
      colorScheme: colorScheme,
    );

    // Draw P&L lines using enhanced components
    PNLLines.drawPNLAtExpiryLine(
      canvas: canvas,
      payoffs: data.payoffsAtExpiry ?? [],
      margin: margin,
      chartWidth: chartWidth,
      chartHeight: chartHeight,
      xMin: xMin,
      xRange: xRange,
      yMin: yMin,
      yRange: yRange,
    );

    PNLLines.drawPNLAtTargetLine(
      canvas: canvas,
      payoffs: data.payoffsAtTarget ?? [],
      margin: margin,
      chartWidth: chartWidth,
      chartHeight: chartHeight,
      xMin: xMin,
      xRange: xRange,
      yMin: yMin,
      yRange: yRange,
      colorScheme: colorScheme,
    );

    // Draw crosshair if active
    if (crosshairPosition != null) {
      Crosshair.draw(
        canvas: canvas,
        position: crosshairPosition!,
        size: size,
        colorScheme: colorScheme,
      );
    }

    // Draw breakeven points
    BreakevenIndicators.drawBreakevenPoints(
      canvas: canvas,
      payoffs: data.payoffsAtExpiry ?? [],
      margin: margin,
      chartWidth: chartWidth,
      chartHeight: chartHeight,
      xMin: xMin,
      xRange: xRange,
      yMin: yMin,
      yRange: yRange,
      colorScheme: colorScheme,
    );

    // Draw legend
    _drawLegend(canvas, size, colorScheme);

    // Draw underlying price line
    if (data.underlyingPrice != null) {
      _drawUnderlyingPriceLine(
        canvas,
        data.underlyingPrice!,
        margin,
        chartWidth,
        chartHeight,
        xMin,
        xRange,
        colorScheme,
      );
    }

    // Draw target price line
    if (data.targetUnderlyingPrice != null) {
      _drawTargetPriceLine(
        canvas,
        data.targetUnderlyingPrice!,
        margin,
        chartWidth,
        chartHeight,
        xMin,
        xRange,
        colorScheme,
      );
    }
  }


  void _drawUnderlyingPriceLine(
    Canvas canvas,
    double underlyingPrice,
    double margin,
    double chartWidth,
    double chartHeight,
    double xMin,
    double xRange,
    ColorScheme colorScheme,
  ) {
    final x = margin + (underlyingPrice - xMin) / xRange * chartWidth;

    // Draw dashed line
    final paint = Paint()
      ..color = colorScheme.onSurface.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    _drawDashedLine(canvas, Offset(x, margin), Offset(x, margin + chartHeight), paint, 8, 8);

    // Draw label
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Underlying: ${underlyingPrice.toStringAsFixed(1)}',
        style: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.8),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x - textPainter.width / 2, margin - 20));
  }

  void _drawTargetPriceLine(
    Canvas canvas,
    double targetPrice,
    double margin,
    double chartWidth,
    double chartHeight,
    double xMin,
    double xRange,
    ColorScheme colorScheme,
  ) {
    final x = margin + (targetPrice - xMin) / xRange * chartWidth;
    final payoffAtTarget = data.payoffAtTarget ?? 0;
    final lineColor = payoffAtTarget > 0 ? Colors.green : Colors.red;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(x, margin),
      Offset(x, margin + chartHeight),
      paint,
    );

    // Draw payoff label
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Payoff: ${ChartUtils.formatLargeNumber(payoffAtTarget, showSign: true)}',
        style: TextStyle(
          color: lineColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x - textPainter.width / 2, margin + chartHeight + 10));
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint, double dashWidth, double dashSpace) {
    final distance = (end - start).distance;
    final dashCount = (distance / (dashWidth + dashSpace)).floor();
    final direction = (end - start) / distance;

    for (int i = 0; i < dashCount; i++) {
      final dashStart = start + direction * (dashWidth + dashSpace) * i.toDouble();
      final dashEnd = dashStart + direction * dashWidth;
      canvas.drawLine(dashStart, dashEnd, paint);
    }
  }

  void _drawLegend(Canvas canvas, Size size, ColorScheme colorScheme) {
    final legendItems = [
      {'color': Colors.blue, 'label': 'P&L at Expiry', 'width': 3.0},
      {'color': Colors.green, 'label': 'P&L at Target', 'width': 2.0},
    ];

    const legendY = 15.0;
    double legendX = size.width - 200;

    for (int i = 0; i < legendItems.length; i++) {
      final item = legendItems[i];
      final color = item['color'] as Color;
      final label = item['label'] as String;
      final width = item['width'] as double;

      // Draw line sample
      canvas.drawLine(
        Offset(legendX, legendY + i * 20),
        Offset(legendX + 20, legendY + i * 20),
        Paint()
          ..color = color
          ..strokeWidth = width
          ..style = PaintingStyle.stroke,
      );

      // Draw label
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.8),
            fontSize: 11,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(legendX + 25, legendY + i * 20 - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is! EnhancedPNLChartPainter) return true;
    return data != oldDelegate.data || crosshairPosition != oldDelegate.crosshairPosition;
  }
}