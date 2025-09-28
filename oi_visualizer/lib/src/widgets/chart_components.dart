import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/builder_data.dart';
import '../utils/chart_utils.dart';

/// Enhanced chart components that mirror the React/D3.js frontend functionality

class ChartAxis {
  static void drawXAxis({
    required Canvas canvas,
    required Size size,
    required double margin,
    required double chartWidth,
    required double chartHeight,
    required double xMin,
    required double xRange,
    required ColorScheme colorScheme,
    required double? underlyingPrice,
    required double? targetUnderlyingPrice,
    required double? payoffAtTarget,
  }) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Generate 7 ticks for X-axis
    for (int i = 0; i <= 7; i++) {
      final value = xMin + (xRange * i / 7);
      final x = margin + (i / 7.0) * chartWidth;

      // Draw tick marks
      canvas.drawLine(
        Offset(x, size.height - margin),
        Offset(x, size.height - margin + 5),
        Paint()
          ..color = colorScheme.onSurface.withValues(alpha: 0.3)
          ..strokeWidth = 1,
      );

      // Draw grid lines
      canvas.drawLine(
        Offset(x, margin),
        Offset(x, size.height - margin),
        Paint()
          ..color = colorScheme.onSurface.withValues(alpha: 0.1)
          ..strokeWidth = 0.5,
      );

      // Draw labels
      textPainter.text = TextSpan(
        text: value.toStringAsFixed(0),
        style: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.7),
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - margin + 8),
      );
    }

    // Draw X-axis line
    canvas.drawLine(
      Offset(margin, size.height - margin),
      Offset(size.width - margin, size.height - margin),
      Paint()
        ..color = colorScheme.onSurface.withValues(alpha: 0.3)
        ..strokeWidth = 1,
    );

    // Draw underlying price line
    if (underlyingPrice != null) {
      _drawUnderlyingPriceLine(
        canvas, underlyingPrice, margin, chartWidth, chartHeight,
        xMin, xRange, colorScheme, size,
      );
    }

    // Draw target price line
    if (targetUnderlyingPrice != null && payoffAtTarget != null) {
      _drawTargetPriceLine(
        canvas, targetUnderlyingPrice, payoffAtTarget, margin, chartWidth,
        chartHeight, xMin, xRange, colorScheme, size,
      );
    }

    // Draw axis title
    textPainter.text = TextSpan(
      text: 'Underlying Price',
      style: TextStyle(
        color: colorScheme.onSurface.withValues(alpha: 0.6),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        margin + (chartWidth - textPainter.width) / 2,
        size.height - 15,
      ),
    );
  }

  static void drawYAxis({
    required Canvas canvas,
    required Size size,
    required double margin,
    required double chartWidth,
    required double chartHeight,
    required double yMin,
    required double yRange,
    required ColorScheme colorScheme,
  }) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Generate 7 ticks for Y-axis
    for (int i = 0; i <= 7; i++) {
      final value = yMin + (yRange * i / 7);
      final y = margin + chartHeight - (i / 7.0) * chartHeight;

      // Draw tick marks
      canvas.drawLine(
        Offset(margin - 5, y),
        Offset(margin, y),
        Paint()
          ..color = colorScheme.onSurface.withValues(alpha: 0.3)
          ..strokeWidth = 1,
      );

      // Draw grid lines
      canvas.drawLine(
        Offset(margin, y),
        Offset(margin + chartWidth, y),
        Paint()
          ..color = colorScheme.onSurface.withValues(alpha: 0.1)
          ..strokeWidth = 0.5,
      );

      // Draw labels
      textPainter.text = TextSpan(
        text: ChartUtils.formatLargeNumber(value, showSign: false),
        style: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.7),
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(margin - textPainter.width - 8, y - textPainter.height / 2),
      );
    }

    // Draw Y-axis line
    canvas.drawLine(
      Offset(margin, margin),
      Offset(margin, size.height - margin),
      Paint()
        ..color = colorScheme.onSurface.withValues(alpha: 0.3)
        ..strokeWidth = 1,
    );

    // Draw zero line (only if zero is within the visible range)
    final yMax = yMin + yRange;
    if (yMin <= 0 && yMax >= 0) {
      final zeroY = margin + chartHeight - (0 - yMin) / yRange * chartHeight;
      canvas.drawLine(
        Offset(margin, zeroY),
        Offset(margin + chartWidth, zeroY),
        Paint()
          ..color = colorScheme.onSurface.withValues(alpha: 0.5)
          ..strokeWidth = 1.5,
      );
    }

    // Draw Y-axis title (rotated)
    canvas.save();
    canvas.translate(0, margin + chartHeight / 2);
    canvas.rotate(-math.pi / 2);
    textPainter.text = TextSpan(
      text: 'Profit & Loss',
      style: TextStyle(
        color: colorScheme.onSurface.withValues(alpha: 0.6),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(-textPainter.width / 2, 0));
    canvas.restore();
  }

  static void _drawUnderlyingPriceLine(
    Canvas canvas,
    double underlyingPrice,
    double margin,
    double chartWidth,
    double chartHeight,
    double xMin,
    double xRange,
    ColorScheme colorScheme,
    Size size,
  ) {
    final x = margin + (underlyingPrice - xMin) / xRange * chartWidth;

    // Draw dashed line
    final paint = Paint()
      ..color = colorScheme.onSurface.withValues(alpha: 0.5)
      ..strokeWidth = 1.5;

    _drawDashedLine(
      canvas,
      Offset(x, margin),
      Offset(x, margin + chartHeight),
      paint,
      8,
      8,
    );

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
    textPainter.paint(
      canvas,
      Offset(x - textPainter.width / 2, margin - 20),
    );
  }

  static void _drawTargetPriceLine(
    Canvas canvas,
    double targetPrice,
    double payoffAtTarget,
    double margin,
    double chartWidth,
    double chartHeight,
    double xMin,
    double xRange,
    ColorScheme colorScheme,
    Size size,
  ) {
    final x = margin + (targetPrice - xMin) / xRange * chartWidth;
    final lineColor = payoffAtTarget > 0 ? Colors.green : Colors.red;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5;

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
    textPainter.paint(
      canvas,
      Offset(x - textPainter.width / 2, margin + chartHeight + 10),
    );
  }

  static void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    double dashWidth,
    double dashSpace,
  ) {
    final distance = (end - start).distance;
    final dashCount = (distance / (dashWidth + dashSpace)).floor();
    final direction = (end - start) / distance;

    for (int i = 0; i < dashCount; i++) {
      final dashStart = start + direction * (dashWidth + dashSpace) * i.toDouble();
      final dashEnd = dashStart + direction * dashWidth;
      canvas.drawLine(dashStart, dashEnd, paint);
    }
  }
}

class PNLLines {
  static void drawPNLAtTargetLine({
    required Canvas canvas,
    required List<PayoffAt> payoffs,
    required double margin,
    required double chartWidth,
    required double chartHeight,
    required double xMin,
    required double xRange,
    required double yMin,
    required double yRange,
    required ColorScheme colorScheme,
  }) {
    if (payoffs.isEmpty) return;

    final paint = Paint()
      ..color = colorScheme.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();

    for (int i = 0; i < payoffs.length; i++) {
      final payoff = payoffs[i];
      if (payoff.at == null || payoff.payoff == null || !payoff.payoff!.isFinite) continue;

      final x = margin + (payoff.at! - xMin) / xRange * chartWidth;
      final y = margin + chartHeight - (payoff.payoff! - yMin) / yRange * chartHeight;

      // Clamp Y coordinate to chart bounds
      final clampedY = y.clamp(margin, margin + chartHeight);

      if (i == 0) {
        path.moveTo(x, clampedY);
      } else {
        path.lineTo(x, clampedY);
      }
    }

    canvas.drawPath(path, paint);
  }

  static void drawPNLAtExpiryLine({
    required Canvas canvas,
    required List<PayoffAt> payoffs,
    required double margin,
    required double chartWidth,
    required double chartHeight,
    required double xMin,
    required double xRange,
    required double yMin,
    required double yRange,
  }) {
    if (payoffs.isEmpty) return;

    // Separate positive and negative payoff segments
    final segments = _separatePayoffSegments(payoffs);

    // Draw positive segments
    for (final segment in segments['positive']!) {
      _drawSegmentWithFill(
        canvas, segment, margin, chartWidth, chartHeight,
        xMin, xRange, yMin, yRange, Colors.green, true,
      );
    }

    // Draw negative segments
    for (final segment in segments['negative']!) {
      _drawSegmentWithFill(
        canvas, segment, margin, chartWidth, chartHeight,
        xMin, xRange, yMin, yRange, Colors.red, false,
      );
    }
  }

  static Map<String, List<List<PayoffAt>>> _separatePayoffSegments(List<PayoffAt> payoffs) {
    final positiveSegments = <List<PayoffAt>>[];
    final negativeSegments = <List<PayoffAt>>[];

    List<PayoffAt> currentPositive = [];
    List<PayoffAt> currentNegative = [];

    for (int i = 0; i < payoffs.length; i++) {
      final payoff = payoffs[i];
      if (payoff.at == null || payoff.payoff == null) continue;

      final nextPayoff = i < payoffs.length - 1 ? payoffs[i + 1] : null;

      if (payoff.payoff! > 0) {
        currentPositive.add(payoff);
      } else if (payoff.payoff! < 0) {
        currentNegative.add(payoff);
      }

      // Check for zero crossing
      if (nextPayoff != null && nextPayoff.at != null && nextPayoff.payoff != null) {
        if ((payoff.payoff! > 0 && nextPayoff.payoff! < 0) ||
            (payoff.payoff! < 0 && nextPayoff.payoff! > 0)) {
          // Find zero crossing point
          final ratio = -payoff.payoff! / (nextPayoff.payoff! - payoff.payoff!);
          final zeroPoint = PayoffAt(
            at: payoff.at! + ratio * (nextPayoff.at! - payoff.at!),
            payoff: 0,
          );

          if (payoff.payoff! >= 0 && nextPayoff.payoff! <= 0) {
            currentPositive.add(zeroPoint);
            currentNegative.add(zeroPoint);
            positiveSegments.add(List.from(currentPositive));
            currentPositive.clear();
          } else if (payoff.payoff! <= 0 && nextPayoff.payoff! >= 0) {
            currentNegative.add(zeroPoint);
            currentPositive.add(zeroPoint);
            negativeSegments.add(List.from(currentNegative));
            currentNegative.clear();
          }
        }
      }
    }

    if (currentPositive.isNotEmpty) positiveSegments.add(currentPositive);
    if (currentNegative.isNotEmpty) negativeSegments.add(currentNegative);

    return {
      'positive': positiveSegments,
      'negative': negativeSegments,
    };
  }

  static void _drawSegmentWithFill(
    Canvas canvas,
    List<PayoffAt> segment,
    double margin,
    double chartWidth,
    double chartHeight,
    double xMin,
    double xRange,
    double yMin,
    double yRange,
    Color color,
    bool isPositive,
  ) {
    if (segment.isEmpty) return;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final linePath = Path();
    final fillPath = Path();

    final zeroY = margin + chartHeight - (0 - yMin) / yRange * chartHeight;

    for (int i = 0; i < segment.length; i++) {
      final payoff = segment[i];
      if (payoff.at == null || payoff.payoff == null || !payoff.payoff!.isFinite) continue;

      final x = margin + (payoff.at! - xMin) / xRange * chartWidth;
      final y = margin + chartHeight - (payoff.payoff! - yMin) / yRange * chartHeight;

      // Clamp Y coordinate to chart bounds
      final clampedY = y.clamp(margin, margin + chartHeight);

      if (i == 0) {
        linePath.moveTo(x, clampedY);
        fillPath.moveTo(x, zeroY);
        fillPath.lineTo(x, clampedY);
      } else {
        linePath.lineTo(x, clampedY);
        fillPath.lineTo(x, clampedY);
      }

      if (i == segment.length - 1) {
        fillPath.lineTo(x, zeroY);
        fillPath.close();
      }
    }

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, linePaint);
  }
}

class BreakevenIndicators {
  static void drawBreakevenPoints({
    required Canvas canvas,
    required List<PayoffAt> payoffs,
    required double margin,
    required double chartWidth,
    required double chartHeight,
    required double xMin,
    required double xRange,
    required double yMin,
    required double yRange,
    required ColorScheme colorScheme,
  }) {
    final breakevenPoints = ChartUtils.findBreakevenPoints(
      payoffs.map((p) => PayoffPoint(
        price: p.at ?? 0,
        payoff: p.payoff ?? 0,
      )).toList(),
    );

    const color = Colors.orange;
    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    for (final breakevenPrice in breakevenPoints) {
      final x = margin + (breakevenPrice - xMin) / xRange * chartWidth;
      final y = margin + chartHeight - (0 - yMin) / yRange * chartHeight;

      // Draw circle at breakeven point
      canvas.drawCircle(Offset(x, y), 4.0, circlePaint);

      // Draw vertical dashed line
      ChartAxis._drawDashedLine(
        canvas,
        Offset(x, y),
        Offset(x, margin + chartHeight),
        linePaint,
        4,
        4,
      );

      // Draw label with background
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'BE: ${breakevenPrice.toStringAsFixed(1)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // Draw background for label
      final labelRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x, margin + chartHeight + 28),
          width: textPainter.width + 8,
          height: textPainter.height + 8,
        ),
        const Radius.circular(4),
      );
      canvas.drawRRect(labelRect, Paint()..color = color);

      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, margin + chartHeight + 23),
      );
    }
  }
}

class Crosshair {
  static void draw({
    required Canvas canvas,
    required Offset position,
    required Size size,
    required ColorScheme colorScheme,
  }) {
    const margin = 40.0;

    final paint = Paint()
      ..color = colorScheme.onSurface.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    // Vertical line (within chart bounds)
    canvas.drawLine(
      Offset(position.dx, margin),
      Offset(position.dx, size.height - margin),
      paint,
    );

    // Horizontal line (within chart bounds)
    canvas.drawLine(
      Offset(margin, position.dy),
      Offset(size.width - margin, position.dy),
      paint,
    );

    // Draw crosshair circle
    final circlePaint = Paint()
      ..color = colorScheme.primary.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, 4.0, circlePaint);

    // Draw white border around circle
    final borderPaint = Paint()
      ..color = colorScheme.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(position, 4.0, borderPaint);
  }
}