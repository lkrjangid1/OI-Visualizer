import 'package:flutter/material.dart';

class OITheme {
  static const Color ceColor = Color(0xFF16a34a);      // green-600
  static const Color ceColorLight = Color(0xFF22c55e);  // green-500
  static const Color ceColorDark = Color(0xFF15803d);   // green-700

  static const Color peColor = Color(0xFF2563eb);       // blue-600
  static const Color peColorLight = Color(0xFF3b82f6);  // blue-500
  static const Color peColorDark = Color(0xFF1d4ed8);   // blue-700

  // Payoff line colors matching frontend theme
  static const Color profitColor = Color(0xFF15d458);   // ITM color from frontend
  static const Color lossColor = Color(0xFFeb3434);     // OTM color from frontend

  static const Color underlyingColor = Color(0xFF7c3aed);   // purple-600
  static const Color targetColor = Color(0xFF006CE6);       // primary blue from frontend
  static const Color breakevenColor = Color(0xFFd97706);    // amber-600

  // Frontend theme colors
  static const Color primaryBlue = Color(0xFF006CE6);
  static const Color primaryBlueDark = Color(0xFF68A5EA);
  static const Color sellColor = Color(0xFFC85959);
  static const Color sellColorDark = Color(0xFFC06767);
  static const Color buySecondaryColor = Color(0xFFE5EFFB);
  static const Color sellSecondaryColor = Color(0xFFFFE2E3);
  static const Color buySecondaryColorDark = Color(0xFF314256);
  static const Color sellSecondaryColorDark = Color(0xFF542A27);

  // Table cell colors
  static const Color tableCellITM = Color(0xFFFFFEE5);
  static const Color tableCellATM = Color(0xFFE5EFFB);
  static const Color tableCellITMDark = Color(0xFF3A3426);
  static const Color tableCellATMDark = Color(0xFF314256);

  static const Color gridColor = Color(0x1A000000);     // black with 10% opacity
  static const Color axisColor = Color(0x4D000000);     // black with 30% opacity

  // Chart styles
  static const double defaultStrokeWidth = 2.0;
  static const double emphasizedStrokeWidth = 3.0;
  static const double gridStrokeWidth = 0.5;

  // Typography
  static const TextStyle chartTitleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle chartSubtitleStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle axisLabelStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle tooltipTitleStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle tooltipBodyStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.normal,
  );

  // Spacing
  static const double defaultPadding = 16.0;
  static const double compactPadding = 8.0;
  static const double chartMargin = 40.0;
  static const double tooltipPadding = 12.0;

  // Border radius
  static const double defaultBorderRadius = 8.0;
  static const double compactBorderRadius = 4.0;

  // Animations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 200);
  static const Duration chartAnimationDuration = Duration(milliseconds: 300);

  // Get color by type and value
  static Color getOIColor(bool isCall, double? value, {bool isHovered = false}) {
    if (value == null) return Colors.grey;

    Color baseColor;
    if (isCall) {
      baseColor = value >= 0 ? ceColor : lossColor;
    } else {
      baseColor = value >= 0 ? peColor : lossColor;
    }

    return isHovered ? _lightenColor(baseColor, 0.2) : baseColor;
  }

  static Color getPnlColor(double value) {
    return value >= 0 ? profitColor : lossColor;
  }

  static Color _lightenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  // Light theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.light,
    ),
    cardTheme: const CardTheme(
      elevation: 2,
      margin: EdgeInsets.all(8),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 1,
    ),
    dataTableTheme: DataTableThemeData(
      headingRowColor: WidgetStateProperty.all(
        const Color(0xFFF3F4F6), // gray-100
      ),
      dataRowColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFFE0E7FF); // indigo-100
        }
        return null;
      }),
    ),
  );

  // Dark theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlueDark,
      brightness: Brightness.dark,
    ),
    cardTheme: const CardTheme(
      elevation: 4,
      margin: EdgeInsets.all(8),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 1,
    ),
    dataTableTheme: DataTableThemeData(
      headingRowColor: WidgetStateProperty.all(
        const Color(0xFF374151), // gray-700
      ),
      dataRowColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF312E81); // indigo-900
        }
        return null;
      }),
    ),
  );

  // Chart specific themes
  static OIChartTheme chartTheme(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return OIChartTheme(
      backgroundColor: colorScheme.surface,
      gridColor: isDark ? const Color(0x33FFFFFF) : gridColor,
      axisColor: isDark ? const Color(0x66FFFFFF) : axisColor,
      textColor: colorScheme.onSurface,
      ceColor: ceColor,
      peColor: peColor,
      underlyingColor: underlyingColor,
      targetColor: targetColor,
      breakevenColor: breakevenColor,
      profitColor: profitColor,
      lossColor: lossColor,
    );
  }
}

class OIChartTheme {
  final Color backgroundColor;
  final Color gridColor;
  final Color axisColor;
  final Color textColor;
  final Color ceColor;
  final Color peColor;
  final Color underlyingColor;
  final Color targetColor;
  final Color breakevenColor;
  final Color profitColor;
  final Color lossColor;

  const OIChartTheme({
    required this.backgroundColor,
    required this.gridColor,
    required this.axisColor,
    required this.textColor,
    required this.ceColor,
    required this.peColor,
    required this.underlyingColor,
    required this.targetColor,
    required this.breakevenColor,
    required this.profitColor,
    required this.lossColor,
  });
}