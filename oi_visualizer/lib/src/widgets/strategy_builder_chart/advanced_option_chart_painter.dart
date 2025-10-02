import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:oi_visualizer/src/models/builder_data.dart';
import 'package:oi_visualizer/src/models/data_item.dart';
import 'package:oi_visualizer/src/utils/chart_utils.dart';

/// Advanced Option Strategy Chart Painter with professional features
class AdvancedOptionChartPainter extends CustomPainter {
  final BuilderData data;
  final BuildContext context;
  final Offset? crosshairPosition;
  final List<DataItem>? oiData;
  final bool showOIChart;
  final bool showChangeInOI;
  final bool showProbabilityCone;
  final double? impliedVolatility;
  final int? daysToExpiration;
  final bool showMaxProfitLoss;
  final bool showGreeksPanel;
  final Map<String, double>? greeks;

  AdvancedOptionChartPainter({
    required this.data,
    required this.context,
    this.crosshairPosition,
    this.oiData,
    this.showOIChart = false,
    this.showChangeInOI = false,
    this.showProbabilityCone = false,
    this.impliedVolatility,
    this.daysToExpiration,
    this.showMaxProfitLoss = true,
    this.showGreeksPanel = false,
    this.greeks,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    const margin = 60.0;
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

    final scaleInfo = ChartUtils.calculateScale(validPayoffs, padding: 0.15);
    final yMin = scaleInfo.min;
    final yMax = scaleInfo.max;
    final yRange = scaleInfo.range;

    // 1. Draw probability cone (if enabled)
    if (showProbabilityCone && impliedVolatility != null && daysToExpiration != null) {
      _drawProbabilityCone(
        canvas, size, margin, chartWidth, chartHeight,
        xMin, xRange, yMin, yRange, isDark,
      );
    }

    // 2. Draw OI background chart (if enabled)
    if (showOIChart && oiData != null) {
      _drawOIBackgroundChart(
        canvas, size, margin, chartWidth, chartHeight,
        xMin, xRange, yMin, yRange, isDark,
      );
    }

    // 3. Draw axes with enhanced styling
    _drawEnhancedAxes(
      canvas, size, margin, chartWidth, chartHeight,
      xMin, xRange, yMin, yRange, colorScheme, isDark,
    );

    // 4. Draw max profit/loss zones (if enabled)
    if (showMaxProfitLoss) {
      _drawMaxProfitLossZones(
        canvas, margin, chartWidth, chartHeight,
        yMin, yRange, validPayoffs, colorScheme, isDark,
      );
    }

    // 5. Draw P&L fill areas
    _drawPNLFillAreas(
      canvas, payoffsAtExpiry, margin, chartWidth, chartHeight,
      xMin, xRange, yMin, yRange, isDark,
    );

    // 6. Draw P&L lines (expiry and target)
    _drawPNLLines(
      canvas, margin, chartWidth, chartHeight,
      xMin, xRange, yMin, yRange, colorScheme, isDark,
    );

    // 7. Draw breakeven points with enhanced styling
    _drawEnhancedBreakevens(
      canvas, payoffsAtExpiry, margin, chartWidth, chartHeight,
      xMin, xRange, yMin, yRange, colorScheme, isDark,
    );

    // 8. Draw standard deviation markers (if probability cone enabled)
    if (showProbabilityCone && impliedVolatility != null && daysToExpiration != null) {
      _drawStandardDeviationMarkers(
        canvas, size, margin, chartWidth, chartHeight,
        xMin, xRange, colorScheme, isDark,
      );
    }

    // 9. Draw underlying price line with label
    if (data.underlyingPrice != null) {
      _drawEnhancedUnderlyingLine(
        canvas, size, data.underlyingPrice!, margin, chartWidth, chartHeight,
        xMin, xRange, colorScheme, isDark,
      );
    }

    // 10. Draw target price line with payoff (if exists)
    if (data.targetUnderlyingPrice != null) {
      _drawEnhancedTargetLine(
        canvas, size, data.targetUnderlyingPrice!, data.payoffAtTarget,
        margin, chartWidth, chartHeight, xMin, xRange, colorScheme, isDark,
      );
    }

    // 11. Draw crosshair (if active)
    if (crosshairPosition != null) {
      _drawEnhancedCrosshair(
        canvas, crosshairPosition!, size, margin, chartWidth, chartHeight,
        xMin, xRange, yMin, yRange, colorScheme, isDark,
      );
    }

    // 12. Draw Greeks panel (if enabled)
    if (showGreeksPanel && greeks != null) {
      _drawGreeksPanel(canvas, size, greeks!, colorScheme, isDark);
    }

    // 13. Draw legend
    _drawAdvancedLegend(canvas, size, colorScheme, isDark);
  }

  void _drawProbabilityCone(
    Canvas canvas,
    Size size,
    double margin,
    double chartWidth,
    double chartHeight,
    double xMin,
    double xRange,
    double yMin,
    double yRange,
    bool isDark,
  ) {
    if (data.underlyingPrice == null) return;

    final currentPrice = data.underlyingPrice!;
    final T = (daysToExpiration ?? 30) / 365.0;
    final sigma = impliedVolatility ?? 0.20;

    // Calculate standard deviation bands
    final sigmaMove = sigma * math.sqrt(T);

    // Draw 1, 2, and 3 standard deviation bands
    final bands = [
      {'sd': 3, 'alpha': 0.05, 'label': '99.7%'},
      {'sd': 2, 'alpha': 0.10, 'label': '95%'},
      {'sd': 1, 'alpha': 0.20, 'label': '68%'},
    ];

    for (final band in bands) {
      final sd = band['sd'] as int;
      final alpha = band['alpha'] as double;
      final label = band['label'] as String;

      final upperPrice = currentPrice * math.exp(sd * sigmaMove);
      final lowerPrice = currentPrice * math.exp(-sd * sigmaMove);

      final upperX = margin + (upperPrice - xMin) / xRange * chartWidth;
      final lowerX = margin + (lowerPrice - xMin) / xRange * chartWidth;

      // Draw shaded rectangle
      final rect = Rect.fromLTRB(
        lowerX.clamp(margin, margin + chartWidth),
        margin,
        upperX.clamp(margin, margin + chartWidth),
        margin + chartHeight,
      );

      canvas.drawRect(
        rect,
        Paint()
          ..color = Colors.blue.withValues(alpha: alpha)
          ..style = PaintingStyle.fill,
      );

      // Draw boundary lines
      if (upperX >= margin && upperX <= margin + chartWidth) {
        _drawDashedVerticalLine(
          canvas,
          Offset(upperX, margin),
          Offset(upperX, margin + chartHeight),
          Colors.blue.withValues(alpha: 0.4),
          2,
          4,
        );
      }

      if (lowerX >= margin && lowerX <= margin + chartWidth) {
        _drawDashedVerticalLine(
          canvas,
          Offset(lowerX, margin),
          Offset(lowerX, margin + chartHeight),
          Colors.blue.withValues(alpha: 0.4),
          2,
          4,
        );
      }

      // Draw label for innermost band
      if (sd == 1 && upperX >= margin && upperX <= margin + chartWidth) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: Colors.blue.withValues(alpha: 0.8),
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(upperX - textPainter.width - 4, margin + 5));
      }
    }
  }

  void _drawOIBackgroundChart(
    Canvas canvas,
    Size size,
    double margin,
    double chartWidth,
    double chartHeight,
    double xMin,
    double xRange,
    double yMin,
    double yRange,
    bool isDark,
  ) {
    if (oiData == null || oiData!.isEmpty) return;

    // Calculate max OI values
    double maxCallOI = 0;
    double maxPutOI = 0;
    double maxCallChangeOI = 0;
    double maxPutChangeOI = 0;

    for (final item in oiData!) {
      if (item.ce?.openInterest != null) {
        maxCallOI = math.max(maxCallOI, item.ce!.openInterest!.toDouble());
      }
      if (item.pe?.openInterest != null) {
        maxPutOI = math.max(maxPutOI, item.pe!.openInterest!.toDouble());
      }
      if (item.ce?.changeinOpenInterest != null) {
        maxCallChangeOI = math.max(maxCallChangeOI, item.ce!.changeinOpenInterest!.abs());
      }
      if (item.pe?.changeinOpenInterest != null) {
        maxPutChangeOI = math.max(maxPutChangeOI, item.pe!.changeinOpenInterest!.abs());
      }
    }

    final maxOI = showChangeInOI
        ? math.max(maxCallChangeOI, maxPutChangeOI)
        : math.max(maxCallOI, maxPutOI);

    if (maxOI == 0) return;

    final barMaxHeight = chartHeight * 0.35; // 35% of chart height

    for (final item in oiData!) {
      if (item.strikePrice == null) continue;

      final x = margin + (item.strikePrice! - xMin) / xRange * chartWidth;
      final barWidth = math.max(chartWidth / (oiData!.length * 2.5), 2.0);

      // Draw Call OI bar (red/pink)
      if (item.ce != null) {
        final oiValue = showChangeInOI
            ? item.ce!.changeinOpenInterest ?? 0
            : item.ce!.openInterest?.toDouble() ?? 0;

        if (oiValue.abs() > 0) {
          final barHeight = (oiValue.abs() / maxOI) * barMaxHeight;
          final isPositive = oiValue >= 0;

          final color = isDark
              ? (isPositive ? Colors.red.shade300 : Colors.red.shade700)
              : (isPositive ? Colors.red.shade400 : Colors.red.shade600);

          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                x - barWidth - 1,
                margin + chartHeight - barHeight,
                barWidth,
                barHeight,
              ),
              const Radius.circular(2),
            ),
            Paint()..color = color.withValues(alpha: 0.5),
          );
        }
      }

      // Draw Put OI bar (green)
      if (item.pe != null) {
        final oiValue = showChangeInOI
            ? item.pe!.changeinOpenInterest ?? 0
            : item.pe!.openInterest?.toDouble() ?? 0;

        if (oiValue.abs() > 0) {
          final barHeight = (oiValue.abs() / maxOI) * barMaxHeight;
          final isPositive = oiValue >= 0;

          final color = isDark
              ? (isPositive ? Colors.green.shade300 : Colors.green.shade700)
              : (isPositive ? Colors.green.shade400 : Colors.green.shade600);

          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                x + 1,
                margin + chartHeight - barHeight,
                barWidth,
                barHeight,
              ),
              const Radius.circular(2),
            ),
            Paint()..color = color.withValues(alpha: 0.5),
          );
        }
      }
    }
  }

  void _drawEnhancedAxes(
    Canvas canvas,
    Size size,
    double margin,
    double chartWidth,
    double chartHeight,
    double xMin,
    double xRange,
    double yMin,
    double yRange,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final gridColor = colorScheme.onSurface.withValues(alpha: isDark ? 0.1 : 0.08);
    final axisColor = colorScheme.onSurface.withValues(alpha: 0.3);
    final labelColor = colorScheme.onSurface.withValues(alpha: 0.7);

    // Draw X-axis
    for (int i = 0; i <= 8; i++) {
      final value = xMin + (xRange * i / 8);
      final x = margin + (i / 8.0) * chartWidth;

      // Grid line
      canvas.drawLine(
        Offset(x, margin),
        Offset(x, margin + chartHeight),
        Paint()
          ..color = gridColor
          ..strokeWidth = i == 4 ? 1.0 : 0.5,
      );

      // Tick mark
      canvas.drawLine(
        Offset(x, size.height - margin),
        Offset(x, size.height - margin + 6),
        Paint()
          ..color = axisColor
          ..strokeWidth = 1.5,
      );

      // Label
      textPainter.text = TextSpan(
        text: value.toStringAsFixed(0),
        style: TextStyle(
          color: labelColor,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - margin + 10),
      );
    }

    // X-axis line
    canvas.drawLine(
      Offset(margin, size.height - margin),
      Offset(size.width - margin, size.height - margin),
      Paint()
        ..color = axisColor
        ..strokeWidth = 2,
    );

    // X-axis title
    textPainter.text = TextSpan(
      text: 'Underlying Price',
      style: TextStyle(
        color: labelColor,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        margin + (chartWidth - textPainter.width) / 2,
        size.height - 18,
      ),
    );

    // Draw Y-axis
    for (int i = 0; i <= 8; i++) {
      final value = yMin + (yRange * i / 8);
      final y = margin + chartHeight - (i / 8.0) * chartHeight;

      // Grid line
      canvas.drawLine(
        Offset(margin, y),
        Offset(margin + chartWidth, y),
        Paint()
          ..color = gridColor
          ..strokeWidth = value.abs() < yRange * 0.05 ? 1.5 : 0.5, // Emphasize zero line
      );

      // Tick mark
      canvas.drawLine(
        Offset(margin - 6, y),
        Offset(margin, y),
        Paint()
          ..color = axisColor
          ..strokeWidth = 1.5,
      );

      // Label
      textPainter.text = TextSpan(
        text: ChartUtils.formatLargeNumber(value, showSign: false),
        style: TextStyle(
          color: labelColor,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(margin - textPainter.width - 10, y - textPainter.height / 2),
      );
    }

    // Y-axis line
    canvas.drawLine(
      Offset(margin, margin),
      Offset(margin, size.height - margin),
      Paint()
        ..color = axisColor
        ..strokeWidth = 2,
    );

    // Y-axis title (rotated)
    canvas.save();
    canvas.translate(15, margin + chartHeight / 2);
    canvas.rotate(-math.pi / 2);
    textPainter.text = TextSpan(
      text: 'Profit & Loss',
      style: TextStyle(
        color: labelColor,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(-textPainter.width / 2, 0));
    canvas.restore();

    // Draw prominent zero line
    final zeroY = margin + chartHeight - (0 - yMin) / yRange * chartHeight;
    if (zeroY >= margin && zeroY <= margin + chartHeight) {
      canvas.drawLine(
        Offset(margin, zeroY),
        Offset(margin + chartWidth, zeroY),
        Paint()
          ..color = colorScheme.onSurface.withValues(alpha: 0.5)
          ..strokeWidth = 2,
      );
    }
  }

  void _drawMaxProfitLossZones(
    Canvas canvas,
    double margin,
    double chartWidth,
    double chartHeight,
    double yMin,
    double yRange,
    List<double> validPayoffs,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    if (validPayoffs.isEmpty) return;

    final maxProfit = validPayoffs.reduce(math.max);
    final maxLoss = validPayoffs.reduce(math.min);

    // Draw max profit line
    if (maxProfit > 0) {
      final y = margin + chartHeight - (maxProfit - yMin) / yRange * chartHeight;
      if (y >= margin && y <= margin + chartHeight) {
        _drawDashedHorizontalLine(
          canvas,
          Offset(margin, y),
          Offset(margin + chartWidth, y),
          Colors.green.withValues(alpha: 0.5),
          6,
          4,
        );

        // Label
        final textPainter = TextPainter(
          text: TextSpan(
            text: 'Max Profit: ${ChartUtils.formatLargeNumber(maxProfit, showSign: true)}',
            style: TextStyle(
              color: Colors.green.shade700,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        // Background
        final labelRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            margin + chartWidth - textPainter.width - 12,
            y - textPainter.height / 2 - 4,
            textPainter.width + 8,
            textPainter.height + 8,
          ),
          const Radius.circular(4),
        );
        canvas.drawRRect(
          labelRect,
          Paint()..color = Colors.green.withValues(alpha: 0.2),
        );

        textPainter.paint(
          canvas,
          Offset(margin + chartWidth - textPainter.width - 8, y - textPainter.height / 2),
        );
      }
    }

    // Draw max loss line
    if (maxLoss < 0) {
      final y = margin + chartHeight - (maxLoss - yMin) / yRange * chartHeight;
      if (y >= margin && y <= margin + chartHeight) {
        _drawDashedHorizontalLine(
          canvas,
          Offset(margin, y),
          Offset(margin + chartWidth, y),
          Colors.red.withValues(alpha: 0.5),
          6,
          4,
        );

        // Label
        final textPainter = TextPainter(
          text: TextSpan(
            text: 'Max Loss: ${ChartUtils.formatLargeNumber(maxLoss, showSign: true)}',
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        // Background
        final labelRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            margin + chartWidth - textPainter.width - 12,
            y - textPainter.height / 2 - 4,
            textPainter.width + 8,
            textPainter.height + 8,
          ),
          const Radius.circular(4),
        );
        canvas.drawRRect(
          labelRect,
          Paint()..color = Colors.red.withValues(alpha: 0.2),
        );

        textPainter.paint(
          canvas,
          Offset(margin + chartWidth - textPainter.width - 8, y - textPainter.height / 2),
        );
      }
    }
  }

  void _drawPNLFillAreas(
    Canvas canvas,
    List<PayoffAt> payoffs,
    double margin,
    double chartWidth,
    double chartHeight,
    double xMin,
    double xRange,
    double yMin,
    double yRange,
    bool isDark,
  ) {
    if (payoffs.isEmpty) return;

    final zeroY = margin + chartHeight - (0 - yMin) / yRange * chartHeight;
    final profitPath = Path();
    final lossPath = Path();
    bool profitStarted = false;
    bool lossStarted = false;

    for (int i = 0; i < payoffs.length; i++) {
      final payoff = payoffs[i];
      if (payoff.at == null || payoff.payoff == null || !payoff.payoff!.isFinite) continue;

      final x = margin + (payoff.at! - xMin) / xRange * chartWidth;
      final y = (margin + chartHeight - (payoff.payoff! - yMin) / yRange * chartHeight)
          .clamp(margin, margin + chartHeight);

      if (payoff.payoff! >= 0) {
        if (!profitStarted) {
          profitPath.moveTo(x, zeroY);
          profitPath.lineTo(x, y);
          profitStarted = true;
        } else {
          profitPath.lineTo(x, y);
        }
      } else {
        if (!lossStarted) {
          lossPath.moveTo(x, zeroY);
          lossPath.lineTo(x, y);
          lossStarted = true;
        } else {
          lossPath.lineTo(x, y);
        }
      }

      // Handle zero crossing
      if (i < payoffs.length - 1) {
        final nextPayoff = payoffs[i + 1];
        if (nextPayoff.at != null && nextPayoff.payoff != null) {
          if ((payoff.payoff! >= 0 && nextPayoff.payoff! < 0) ||
              (payoff.payoff! < 0 && nextPayoff.payoff! >= 0)) {
            final ratio = -payoff.payoff! / (nextPayoff.payoff! - payoff.payoff!);
            final zeroX = x + ratio * ((margin + (nextPayoff.at! - xMin) / xRange * chartWidth) - x);

            if (payoff.payoff! >= 0) {
              profitPath.lineTo(zeroX, zeroY);
              profitPath.close();
              profitStarted = false;
              lossStarted = false;
            } else {
              lossPath.lineTo(zeroX, zeroY);
              lossPath.close();
              lossStarted = false;
              profitStarted = false;
            }
          }
        }
      }
    }

    // Close paths
    if (profitStarted) {
      final lastProfit = payoffs.lastWhere(
        (p) => p.payoff != null && p.payoff! >= 0,
        orElse: () => payoffs.last,
      );
      if (lastProfit.at != null) {
        final x = margin + (lastProfit.at! - xMin) / xRange * chartWidth;
        profitPath.lineTo(x, zeroY);
        profitPath.close();
      }
    }

    if (lossStarted) {
      final lastLoss = payoffs.lastWhere(
        (p) => p.payoff != null && p.payoff! < 0,
        orElse: () => payoffs.last,
      );
      if (lastLoss.at != null) {
        final x = margin + (lastLoss.at! - xMin) / xRange * chartWidth;
        lossPath.lineTo(x, zeroY);
        lossPath.close();
      }
    }

    // Draw fills
    canvas.drawPath(
      profitPath,
      Paint()
        ..color = (isDark ? Colors.green.shade300 : Colors.green.shade400)
            .withValues(alpha: 0.15)
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      lossPath,
      Paint()
        ..color = (isDark ? Colors.red.shade300 : Colors.red.shade400)
            .withValues(alpha: 0.15)
        ..style = PaintingStyle.fill,
    );
  }

  void _drawPNLLines(
    Canvas canvas,
    double margin,
    double chartWidth,
    double chartHeight,
    double xMin,
    double xRange,
    double yMin,
    double yRange,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    // Draw expiry line (bold, primary color)
    final expiryPayoffs = data.payoffsAtExpiry ?? [];
    if (expiryPayoffs.isNotEmpty) {
      final path = Path();
      bool started = false;

      for (final payoff in expiryPayoffs) {
        if (payoff.at == null || payoff.payoff == null || !payoff.payoff!.isFinite) continue;

        final x = margin + (payoff.at! - xMin) / xRange * chartWidth;
        final y = (margin + chartHeight - (payoff.payoff! - yMin) / yRange * chartHeight)
            .clamp(margin, margin + chartHeight);

        if (!started) {
          path.moveTo(x, y);
          started = true;
        } else {
          path.lineTo(x, y);
        }
      }

      // Draw gradient line for expiry
      final paint = Paint()
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      // Create gradient based on profit/loss
      final colors = <Color>[];
      final stops = <double>[];

      for (int i = 0; i < expiryPayoffs.length; i++) {
        final payoff = expiryPayoffs[i].payoff ?? 0;
        final color = payoff >= 0 ? Colors.green.shade600 : Colors.red.shade600;
        colors.add(color);
        stops.add(i / (expiryPayoffs.length - 1));
      }

      paint.shader = LinearGradient(
        colors: colors.length > 1 ? colors : [Colors.blue, Colors.blue],
        stops: stops.length > 1 ? stops : null,
      ).createShader(Rect.fromLTWH(margin, margin, chartWidth, chartHeight));

      canvas.drawPath(path, paint);
    }

    // Draw target line (thinner, accent color)
    final targetPayoffs = data.payoffsAtTarget ?? [];
    if (targetPayoffs.isNotEmpty) {
      final path = Path();
      bool started = false;

      for (final payoff in targetPayoffs) {
        if (payoff.at == null || payoff.payoff == null || !payoff.payoff!.isFinite) continue;

        final x = margin + (payoff.at! - xMin) / xRange * chartWidth;
        final y = (margin + chartHeight - (payoff.payoff! - yMin) / yRange * chartHeight)
            .clamp(margin, margin + chartHeight);

        if (!started) {
          path.moveTo(x, y);
          started = true;
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = colorScheme.secondary
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  void _drawEnhancedBreakevens(
    Canvas canvas,
    List<PayoffAt> payoffs,
    double margin,
    double chartWidth,
    double chartHeight,
    double xMin,
    double xRange,
    double yMin,
    double yRange,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final breakevenPoints = ChartUtils.findBreakevenPoints(
      payoffs.map((p) => PayoffPoint(
        price: p.at ?? 0,
        payoff: p.payoff ?? 0,
      )).toList(),
    );

    const color = Colors.orange;
    final zeroY = margin + chartHeight - (0 - yMin) / yRange * chartHeight;

    for (int i = 0; i < breakevenPoints.length; i++) {
      final breakevenPrice = breakevenPoints[i];
      final x = margin + (breakevenPrice - xMin) / xRange * chartWidth;

      // Draw vertical dashed line
      _drawDashedVerticalLine(
        canvas,
        Offset(x, margin),
        Offset(x, margin + chartHeight),
        color.withValues(alpha: 0.4),
        5,
        3,
      );

      // Draw circle at breakeven point
      canvas.drawCircle(
        Offset(x, zeroY),
        6.0,
        Paint()..color = color,
      );

      // White inner circle
      canvas.drawCircle(
        Offset(x, zeroY),
        4.0,
        Paint()..color = Colors.white,
      );

      // Orange center dot
      canvas.drawCircle(
        Offset(x, zeroY),
        2.0,
        Paint()..color = color,
      );

      // Label with background
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'BE: ${breakevenPrice.toStringAsFixed(1)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final labelY = i % 2 == 0 ? margin - 15 : margin + chartHeight + 25;
      final labelRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x, labelY),
          width: textPainter.width + 12,
          height: textPainter.height + 10,
        ),
        const Radius.circular(6),
      );

      // Shadow
      canvas.drawRRect(
        labelRect.shift(const Offset(0, 2)),
        Paint()..color = Colors.black.withValues(alpha: 0.2),
      );

      // Background
      canvas.drawRRect(labelRect, Paint()..color = color);

      // Text
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, labelY - textPainter.height / 2),
      );
    }
  }

  void _drawStandardDeviationMarkers(
    Canvas canvas,
    Size size,
    double margin,
    double chartWidth,
    double chartHeight,
    double xMin,
    double xRange,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    if (data.underlyingPrice == null) return;

    final currentPrice = data.underlyingPrice!;
    final T = (daysToExpiration ?? 30) / 365.0;
    final sigma = impliedVolatility ?? 0.20;
    final sigmaMove = sigma * math.sqrt(T);

    final sdMarkers = [
      {'sd': -2, 'label': '-2σ'},
      {'sd': -1, 'label': '-1σ'},
      {'sd': 1, 'label': '+1σ'},
      {'sd': 2, 'label': '+2σ'},
    ];

    for (final marker in sdMarkers) {
      final sd = marker['sd'] as int;
      final label = marker['label'] as String;
      final price = currentPrice * math.exp(sd * sigmaMove);
      final x = margin + (price - xMin) / xRange * chartWidth;

      if (x < margin || x > margin + chartWidth) continue;

      // Draw marker at top
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: Colors.blue.shade600,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final labelRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x, margin - 8),
          width: textPainter.width + 8,
          height: textPainter.height + 6,
        ),
        const Radius.circular(4),
      );

      canvas.drawRRect(
        labelRect,
        Paint()..color = Colors.blue.withValues(alpha: 0.2),
      );

      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, margin - 8 - textPainter.height / 2),
      );
    }
  }

  void _drawEnhancedUnderlyingLine(
    Canvas canvas,
    Size size,
    double underlyingPrice,
    double margin,
    double chartWidth,
    double chartHeight,
    double xMin,
    double xRange,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final x = margin + (underlyingPrice - xMin) / xRange * chartWidth;

    // Draw line
    final paint = Paint()
      ..color = colorScheme.primary.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(x, margin),
      Offset(x, margin + chartHeight),
      paint,
    );

    // Draw label with background
    final textPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Current\n',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(
            text: underlyingPrice.toStringAsFixed(1),
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();

    final labelRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(x, margin + chartHeight / 2),
        width: textPainter.width + 12,
        height: textPainter.height + 10,
      ),
      const Radius.circular(6),
    );

    // Shadow
    canvas.drawRRect(
      labelRect.shift(const Offset(0, 2)),
      Paint()..color = Colors.black.withValues(alpha: 0.3),
    );

    // Background
    canvas.drawRRect(
      labelRect,
      Paint()..color = colorScheme.primary,
    );

    // Text
    textPainter.paint(
      canvas,
      Offset(
        x - textPainter.width / 2,
        margin + chartHeight / 2 - textPainter.height / 2,
      ),
    );
  }

  void _drawEnhancedTargetLine(
    Canvas canvas,
    Size size,
    double targetPrice,
    double? payoffAtTarget,
    double margin,
    double chartWidth,
    double chartHeight,
    double xMin,
    double xRange,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final x = margin + (targetPrice - xMin) / xRange * chartWidth;
    final lineColor = (payoffAtTarget ?? 0) >= 0 
        ? Colors.green.shade600 
        : Colors.red.shade600;

    // Draw solid line
    canvas.drawLine(
      Offset(x, margin),
      Offset(x, margin + chartHeight),
      Paint()
        ..color = lineColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );

    // Draw label
    final textPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Target\n',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(
            text: targetPrice.toStringAsFixed(1),
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (payoffAtTarget != null)
            TextSpan(
              text: '\n${ChartUtils.formatLargeNumber(payoffAtTarget, showSign: true)}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();

    final labelRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(x, margin + chartHeight - 40),
        width: textPainter.width + 12,
        height: textPainter.height + 10,
      ),
      const Radius.circular(6),
    );

    // Shadow
    canvas.drawRRect(
      labelRect.shift(const Offset(0, 2)),
      Paint()..color = Colors.black.withValues(alpha: 0.3),
    );

    // Background
    canvas.drawRRect(labelRect, Paint()..color = lineColor);

    // Text
    textPainter.paint(
      canvas,
      Offset(
        x - textPainter.width / 2,
        margin + chartHeight - 40 - textPainter.height / 2,
      ),
    );
  }

  void _drawEnhancedCrosshair(
    Canvas canvas,
    Offset position,
    Size size,
    double margin,
    double chartWidth,
    double chartHeight,
    double xMin,
    double xRange,
    double yMin,
    double yRange,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final paint = Paint()
      ..color = colorScheme.primary.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Vertical line
    canvas.drawLine(
      Offset(position.dx, margin),
      Offset(position.dx, margin + chartHeight),
      paint,
    );

    // Horizontal line
    canvas.drawLine(
      Offset(margin, position.dy),
      Offset(margin + chartWidth, position.dy),
      paint,
    );

    // Central circle
    canvas.drawCircle(
      position,
      6.0,
      Paint()
        ..color = colorScheme.primary
        ..style = PaintingStyle.fill,
    );

    canvas.drawCircle(
      position,
      6.0,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // Calculate and display values
    final relativeX = (position.dx - margin) / chartWidth;
    final relativeY = (margin + chartHeight - position.dy) / chartHeight;
    final priceValue = xMin + relativeX * xRange;
    final pnlValue = yMin + relativeY * yRange;

    // X-axis label
    final xTextPainter = TextPainter(
      text: TextSpan(
        text: priceValue.toStringAsFixed(1),
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    xTextPainter.layout();

    final xLabelRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(position.dx, margin + chartHeight + 15),
        width: xTextPainter.width + 10,
        height: xTextPainter.height + 8,
      ),
      const Radius.circular(4),
    );

    canvas.drawRRect(xLabelRect, Paint()..color = colorScheme.primary);
    xTextPainter.paint(
      canvas,
      Offset(
        position.dx - xTextPainter.width / 2,
        margin + chartHeight + 15 - xTextPainter.height / 2,
      ),
    );

    // Y-axis label
    final yTextPainter = TextPainter(
      text: TextSpan(
        text: ChartUtils.formatLargeNumber(pnlValue, showSign: true),
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    yTextPainter.layout();

    final yLabelRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(margin - 20, position.dy),
        width: yTextPainter.width + 10,
        height: yTextPainter.height + 8,
      ),
      const Radius.circular(4),
    );

    canvas.drawRRect(yLabelRect, Paint()..color = colorScheme.primary);
    yTextPainter.paint(
      canvas,
      Offset(
        margin - 20 - yTextPainter.width / 2,
        position.dy - yTextPainter.height / 2,
      ),
    );
  }

  void _drawGreeksPanel(
    Canvas canvas,
    Size size,
    Map<String, double> greeks,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    const panelWidth = 180.0;
    const panelHeight = 120.0;
    const padding = 12.0;

    final panelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width - panelWidth - 20,
        20,
        panelWidth,
        panelHeight,
      ),
      const Radius.circular(8),
    );

    // Shadow
    canvas.drawRRect(
      panelRect.shift(const Offset(0, 2)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Background
    canvas.drawRRect(
      panelRect,
      Paint()
        ..color = colorScheme.surface
        ..style = PaintingStyle.fill,
    );

    canvas.drawRRect(
      panelRect,
      Paint()
        ..color = colorScheme.outline
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );

    // Title
    final titlePainter = TextPainter(
      text: TextSpan(
        text: 'Greeks',
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    titlePainter.layout();
    titlePainter.paint(
      canvas,
      Offset(
        size.width - panelWidth - 20 + padding,
        20 + padding,
      ),
    );

    // Greeks values
    final greeksList = [
      {'name': 'Delta', 'value': greeks['delta'], 'color': Colors.blue},
      {'name': 'Gamma', 'value': greeks['gamma'], 'color': Colors.purple},
      {'name': 'Theta', 'value': greeks['theta'], 'color': Colors.orange},
      {'name': 'Vega', 'value': greeks['vega'], 'color': Colors.green},
    ];

    double yOffset = 20 + padding + titlePainter.height + 8;

    for (final greek in greeksList) {
      final name = greek['name'] as String;
      final value = greek['value'] as double?;
      final color = greek['color'] as Color;

      if (value == null) continue;

      // Name
      final namePainter = TextPainter(
        text: TextSpan(
          text: '$name: ',
          style: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      namePainter.layout();
      namePainter.paint(
        canvas,
        Offset(size.width - panelWidth - 20 + padding, yOffset),
      );

      // Value
      final valuePainter = TextPainter(
        text: TextSpan(
          text: value.toStringAsFixed(3),
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      valuePainter.layout();
      valuePainter.paint(
        canvas,
        Offset(
          size.width - panelWidth - 20 + panelWidth - padding - valuePainter.width,
          yOffset,
        ),
      );

      yOffset += 18;
    }
  }

  void _drawAdvancedLegend(
    Canvas canvas,
    Size size,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final legendItems = [
      {
        'color': Colors.green.shade600,
        'label': 'P&L at Expiry',
        'width': 3.0,
        'gradient': true,
      },
      {
        'color': colorScheme.secondary,
        'label': 'P&L at Target',
        'width': 2.5,
        'gradient': false,
      },
      {
        'color': Colors.orange,
        'label': 'Breakeven',
        'width': 2.0,
        'gradient': false,
        'dashed': true,
      },
    ];

    const legendY = 15.0;
    double legendX = size.width - 380;

    for (int i = 0; i < legendItems.length; i++) {
      final item = legendItems[i];
      final color = item['color'] as Color;
      final label = item['label'] as String;
      final width = item['width'] as double;
      final gradient = item['gradient'] as bool? ?? false;
      final dashed = item['dashed'] as bool? ?? false;

      // Draw line sample
      if (dashed) {
        _drawDashedHorizontalLine(
          canvas,
          Offset(legendX, legendY + i * 22),
          Offset(legendX + 24, legendY + i * 22),
          color,
          4,
          2,
        );
      } else {
        final paint = Paint()
          ..strokeWidth = width
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        if (gradient) {
          paint.shader = LinearGradient(
            colors: [Colors.red.shade600, Colors.green.shade600],
          ).createShader(Rect.fromLTWH(legendX, legendY + i * 22 - 2, 24, 4));
        } else {
          paint.color = color;
        }

        canvas.drawLine(
          Offset(legendX, legendY + i * 22),
          Offset(legendX + 24, legendY + i * 22),
          paint,
        );
      }

      // Draw label
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.8),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(legendX + 30, legendY + i * 22 - textPainter.height / 2),
      );

      legendX += textPainter.width + 60;
    }
  }

  void _drawDashedVerticalLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color,
    double dashWidth,
    double dashSpace,
  ) {
    final distance = (end - start).distance;
    final dashCount = (distance / (dashWidth + dashSpace)).floor();
    final direction = (end - start) / distance;

    for (int i = 0; i < dashCount; i++) {
      final dashStart = start + direction * (dashWidth + dashSpace) * i.toDouble();
      final dashEnd = dashStart + direction * dashWidth;
      canvas.drawLine(
        dashStart,
        dashEnd,
        Paint()
          ..color = color
          ..strokeWidth = 1.5,
      );
    }
  }

  void _drawDashedHorizontalLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color,
    double dashWidth,
    double dashSpace,
  ) {
    final distance = (end - start).distance;
    final dashCount = (distance / (dashWidth + dashSpace)).floor();
    final direction = (end - start) / distance;

    for (int i = 0; i < dashCount; i++) {
      final dashStart = start + direction * (dashWidth + dashSpace) * i.toDouble();
      final dashEnd = dashStart + direction * dashWidth;
      canvas.drawLine(
        dashStart,
        dashEnd,
        Paint()
          ..color = color
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant AdvancedOptionChartPainter oldDelegate) {
    return data != oldDelegate.data ||
           crosshairPosition != oldDelegate.crosshairPosition ||
           oiData != oldDelegate.oiData ||
           showOIChart != oldDelegate.showOIChart ||
           showChangeInOI != oldDelegate.showChangeInOI ||
           showProbabilityCone != oldDelegate.showProbabilityCone ||
           showMaxProfitLoss != oldDelegate.showMaxProfitLoss ||
           showGreeksPanel != oldDelegate.showGreeksPanel;
  }
}