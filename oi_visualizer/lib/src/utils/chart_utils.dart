import 'dart:math' as math;
import '../models/data_item.dart';

class ChartUtils {
  // Color utilities
  static const Map<String, String> colorMap = {
    'cePositive': '#16a34a',    // green-600
    'ceNegative': '#dc2626',    // red-600
    'pePositive': '#2563eb',    // blue-600
    'peNegative': '#ea580c',    // orange-600
    'underlying': '#7c3aed',    // purple-600
    'target': '#059669',        // emerald-600
    'breakeven': '#d97706',     // amber-600
  };

  // Number formatting utilities
  static String formatLargeNumber(double value, {bool showSign = false}) {
    final sign = showSign && value >= 0 ? '+' : '';
    final absValue = value.abs();

    if (absValue >= 10000000) {
      return '$sign${(value / 10000000).toStringAsFixed(1)}Cr';
    } else if (absValue >= 100000) {
      return '$sign${(value / 100000).toStringAsFixed(1)}L';
    } else if (absValue >= 1000) {
      return '$sign${(value / 1000).toStringAsFixed(1)}K';
    }

    return '$sign${value.toStringAsFixed(0)}';
  }

  static String formatPrice(double? value, {int decimals = 2}) {
    if (value == null) return 'N/A';
    return value.toStringAsFixed(decimals);
  }

  static String formatPercentage(double? value, {int decimals = 2}) {
    if (value == null) return 'N/A';
    final sign = value >= 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(decimals)}%';
  }

  // Scale calculation utilities
  static ScaleInfo calculateScale(List<double> values, {double padding = 0.1}) {
    if (values.isEmpty) {
      return ScaleInfo(min: -100, max: 100, range: 200);
    }

    // Filter out invalid values
    final validValues = values.where((v) => v.isFinite).toList();
    if (validValues.isEmpty) {
      return ScaleInfo(min: -100, max: 100, range: 200);
    }

    final minValue = validValues.reduce(math.min);
    final maxValue = validValues.reduce(math.max);
    final range = maxValue - minValue;

    // Add padding
    final paddingAmount = range > 0 ? range * padding : 50.0;
    final paddedMin = minValue - paddingAmount;
    final paddedMax = maxValue + paddingAmount;
    final paddedRange = paddedMax - paddedMin;

    return ScaleInfo(
      min: paddedMin,
      max: paddedMax,
      range: paddedRange,
    );
  }

  static List<double> generateTicks(double min, double max, int tickCount) {
    final step = (max - min) / (tickCount - 1);
    return List.generate(tickCount, (index) => min + (step * index));
  }

  // Data processing utilities
  static List<double> extractOIValues(List<DataItem> data, bool isCall, bool isChange) {
    return data
        .map((item) {
          final contract = isCall ? item.ce : item.pe;
          if (contract == null) return null;

          return isChange
              ? contract.changeinOpenInterest
              : contract.openInterest?.toDouble();
        })
        .where((value) => value != null)
        .cast<double>()
        .toList();
  }

  static List<double> extractStrikePrices(List<DataItem> data) {
    return data
        .map((item) => item.strikePrice)
        .where((price) => price != null)
        .cast<double>()
        .toList();
  }

  // Chart position calculations
  static double getXPosition(double value, double min, double range, double chartWidth) {
    return (value - min) / range * chartWidth;
  }

  static double getYPosition(double value, double min, double range, double chartHeight) {
    return chartHeight - ((value - min) / range * chartHeight);
  }

  // Breakeven calculation
  static List<double> findBreakevenPoints(List<PayoffPoint> payoffs) {
    final breakevenPoints = <double>[];

    for (int i = 0; i < payoffs.length - 1; i++) {
      final current = payoffs[i];
      final next = payoffs[i + 1];

      // Check if line crosses zero (breakeven)
      if ((current.payoff <= 0 && next.payoff >= 0) ||
          (current.payoff >= 0 && next.payoff <= 0)) {
        // Linear interpolation to find exact breakeven point
        final ratio = -current.payoff / (next.payoff - current.payoff);
        final breakevenPrice = current.price + ratio * (next.price - current.price);
        breakevenPoints.add(breakevenPrice);
      }
    }

    return breakevenPoints;
  }

  // ATM (At-The-Money) detection
  static bool isAtTheMoney(double? strikePrice, double? underlyingPrice, {double threshold = 50}) {
    if (strikePrice == null || underlyingPrice == null) return false;
    return (strikePrice - underlyingPrice).abs() <= threshold;
  }

  // Data interpolation
  static double? interpolateValue(List<PayoffPoint> points, double targetPrice) {
    if (points.isEmpty) return null;

    // Find closest points for interpolation
    PayoffPoint? before;
    PayoffPoint? after;

    for (final point in points) {
      if (point.price <= targetPrice) {
        if (before == null || point.price > before.price) {
          before = point;
        }
      } else {
        if (after == null || point.price < after.price) {
          after = point;
        }
      }
    }

    if (before == null && after == null) return null;
    if (before == null) return after!.payoff;
    if (after == null) return before.payoff;

    // Linear interpolation
    final ratio = (targetPrice - before.price) / (after.price - before.price);
    return before.payoff + ratio * (after.payoff - before.payoff);
  }

  // Statistical calculations
  static OIStatistics calculateOIStatistics(List<DataItem> data) {
    final ceTotalOI = data.fold<double>(0, (sum, item) =>
        sum + (item.ce?.openInterest?.toDouble() ?? 0));

    final peTotalOI = data.fold<double>(0, (sum, item) =>
        sum + (item.pe?.openInterest?.toDouble() ?? 0));

    final ceChangeOI = data.fold<double>(0, (sum, item) =>
        sum + (item.ce?.changeinOpenInterest ?? 0));

    final peChangeOI = data.fold<double>(0, (sum, item) =>
        sum + (item.pe?.changeinOpenInterest ?? 0));

    final totalOI = ceTotalOI + peTotalOI;
    final totalChangeOI = ceChangeOI + peChangeOI;

    return OIStatistics(
      ceTotalOI: ceTotalOI,
      peTotalOI: peTotalOI,
      ceChangeOI: ceChangeOI,
      peChangeOI: peChangeOI,
      totalOI: totalOI,
      totalChangeOI: totalChangeOI,
      putCallRatio: ceTotalOI > 0 ? peTotalOI / ceTotalOI : 0,
    );
  }

  // Volatility calculations
  static double calculateImpliedVolatility(List<DataItem> data, double? underlyingPrice) {
    if (underlyingPrice == null) return 0;

    final atmOptions = data.where((item) =>
        isAtTheMoney(item.strikePrice, underlyingPrice)).toList();

    if (atmOptions.isEmpty) return 0;

    double totalIV = 0;
    int count = 0;

    for (final item in atmOptions) {
      final ceIV = item.ce?.impliedVolatility;
      final peIV = item.pe?.impliedVolatility;

      if (ceIV != null) {
        totalIV += ceIV;
        count++;
      }
      if (peIV != null) {
        totalIV += peIV;
        count++;
      }
    }

    return count > 0 ? totalIV / count : 0;
  }
}

class ScaleInfo {
  final double min;
  final double max;
  final double range;

  ScaleInfo({
    required this.min,
    required this.max,
    required this.range,
  });
}

class PayoffPoint {
  final double price;
  final double payoff;

  PayoffPoint({
    required this.price,
    required this.payoff,
  });
}

class OIStatistics {
  final double ceTotalOI;
  final double peTotalOI;
  final double ceChangeOI;
  final double peChangeOI;
  final double totalOI;
  final double totalChangeOI;
  final double putCallRatio;

  OIStatistics({
    required this.ceTotalOI,
    required this.peTotalOI,
    required this.ceChangeOI,
    required this.peChangeOI,
    required this.totalOI,
    required this.totalChangeOI,
    required this.putCallRatio,
  });
}