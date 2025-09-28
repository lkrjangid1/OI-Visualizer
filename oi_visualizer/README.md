# OI Visualizer Flutter Package

A comprehensive Flutter package for visualizing Options Trading data including Open Interest (OI) charts, P&L analysis, and strategy building tools.

## Features

### 📊 Advanced Chart Components
- **Interactive OI Charts**: Visualize Open Interest data with hover tooltips, grid lines, and axis labels
- **P&L Charts**: Advanced Profit & Loss visualization with crosshair interaction and breakeven analysis
- **Real-time Interactions**: Mouse hover effects, tap gestures, and detailed tooltips
- **Mobile Responsive**: Optimized layouts for both desktop and mobile devices

### 📱 UI Components
- **Open Interest View**: Complete dashboard with charts and data tables
- **Strategy Builder**: Interactive option strategy creation and analysis
- **Data Table View**: Sortable, filterable options chain data table
- **Summary Cards**: Key metrics and statistics overview

### 🎨 Theme & Styling
- **Custom Theme System**: Comprehensive theming with light/dark mode support
- **Color-coded Data**: Intuitive color schemes for calls, puts, profits, and losses
- **Professional Design**: Material Design 3 components with custom styling

### 🛠 Utilities
- **Chart Utils**: Advanced chart calculations, scaling, and data processing
- **Number Formatting**: Smart formatting for large numbers (K, L, Cr notation)
- **Statistical Functions**: OI statistics, implied volatility calculations
- **Data Interpolation**: Smooth data interpolation for chart interactions

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  oi_visualizer:
    path: ../oi_visualizer  # Update path as needed
```

Then run:
```bash
flutter pub get
```

## Quick Start

### 1. Basic OI Chart

```dart
import 'package:oi_visualizer/oi_visualizer.dart';

OIChart(
  data: yourDataItems,
  type: OIChartType.change,
  underlyingPrice: 19500.0,
)
```

### 2. Complete Open Interest Dashboard

```dart
OpenInterestView(
  underlying: 'NIFTY',
  onLoadData: (underlying) async {
    // Your data loading logic
    return await apiService.getOpenInterestData(underlying);
  },
)
```

### 3. Strategy Builder

```dart
StrategyBuilderView(
  underlying: 'NIFTY',
  onCalculatePnl: ({
    required underlyingPrice,
    required targetUnderlyingPrice,
    required targetDateTimeISOString,
    required atmIVsPerExpiry,
    required futuresPerExpiry,
    required optionLegs,
    required lotSize,
    required isIndex,
  }) async {
    // Your P&L calculation logic
    return await calculatePnL(...);
  },
)
```

### 4. Data Table

```dart
DataTableView(
  data: yourDataItems,
  underlyingPrice: 19500.0,
)
```

### 5. Summary Card

```dart
SummaryCard(
  data: yourDataItems,
  underlyingPrice: 19500.0,
  title: 'Market Overview',
)
```

## Data Models

### DataItem
```dart
class DataItem {
  final double? strikePrice;
  final ContractData? ce;  // Call option data
  final ContractData? pe;  // Put option data
  final String? expiryDate;
}
```

### ContractData
```dart
class ContractData {
  final double? lastPrice;
  final int? openInterest;
  final double? changeinOpenInterest;
  final double? impliedVolatility;
  // ... other fields
}
```

### BuilderData (for P&L Charts)
```dart
class BuilderData {
  final List<PayoffAt>? payoffsAtTarget;
  final List<PayoffAt>? payoffsAtExpiry;
  final double? xMin;
  final double? xMax;
  final double? underlyingPrice;
  final double? targetUnderlyingPrice;
}
```

## Chart Features

### Interactive Elements
- **Hover Tooltips**: Detailed information on data points
- **Crosshair**: Precise value reading in P&L charts
- **Underlying Price Line**: Visual indicator of current market price
- **Breakeven Points**: Automatic calculation and display
- **Grid Lines**: Professional chart appearance
- **Zoom and Pan**: (Future enhancement)

### Customization Options
- Chart types (Change in OI vs Total OI)
- Color schemes and themes
- Responsive layouts
- Custom formatting

## Theme Usage

```dart
import 'package:oi_visualizer/oi_visualizer.dart';

MaterialApp(
  theme: OITheme.lightTheme,
  darkTheme: OITheme.darkTheme,
  home: YourApp(),
)
```

## Utility Functions

### Number Formatting
```dart
// Format large numbers
ChartUtils.formatLargeNumber(1500000); // "1.5L"
ChartUtils.formatLargeNumber(15000000); // "1.5Cr"

// Format prices and percentages
ChartUtils.formatPrice(123.45); // "123.45"
ChartUtils.formatPercentage(2.5); // "+2.50%"
```

### Statistical Calculations
```dart
final stats = ChartUtils.calculateOIStatistics(dataItems);
print('Put-Call Ratio: ${stats.putCallRatio}');
print('Total OI: ${stats.totalOI}');

final iv = ChartUtils.calculateImpliedVolatility(dataItems, underlyingPrice);
print('Implied Volatility: ${iv}%');
```

## Architecture

### Package Structure
```
lib/
├── src/
│   ├── models/          # Data models
│   ├── widgets/         # UI components
│   ├── utils/           # Utility functions
│   └── theme/           # Theme definitions
└── oi_visualizer.dart   # Main export file
```

### Key Design Principles
- **Separation of Concerns**: Clean separation between UI, data, and business logic
- **Null Safety**: Comprehensive null safety throughout the package
- **Responsive Design**: Mobile-first approach with desktop enhancements
- **Performance**: Optimized rendering and efficient data processing
- **Extensibility**: Easy to extend and customize

## Performance Considerations

- **Efficient Rendering**: Custom painters for optimal chart performance
- **Memory Management**: Proper disposal of controllers and listeners
- **Data Processing**: Optimized algorithms for large datasets
- **Lazy Loading**: Components render only when needed

## Browser Compatibility

- ✅ Chrome (Desktop & Mobile)
- ✅ Firefox (Desktop & Mobile)
- ✅ Safari (Desktop & Mobile)
- ✅ Edge (Desktop)

## Mobile Support

- ✅ iOS (iPhone & iPad)
- ✅ Android (Phone & Tablet)
- ✅ Responsive layouts
- ✅ Touch interactions
- ✅ Mobile-optimized UI

## Contributing

This package is designed to be easily extensible. Key areas for contribution:

1. **Additional Chart Types**: Implement new visualization types
2. **Enhanced Interactions**: Add more interactive features
3. **Performance Optimizations**: Improve rendering performance
4. **Accessibility**: Add accessibility features
5. **Documentation**: Improve documentation and examples

## Migration from React

This Flutter package provides feature parity with the original React frontend:

| React Component | Flutter Equivalent | Status |
|---|---|---|
| OIChart | OIChart | ✅ Complete |
| PNLChart | PNLChart | ✅ Complete |
| DataTable | DataTableView | ✅ Complete |
| StrategyBuilder | StrategyBuilderView | ✅ Complete |
| Tooltip | Built-in tooltips | ✅ Complete |
| Crosshair | Built-in crosshair | ✅ Complete |

## License

This package follows the same license as your main project.

## Support

For issues, feature requests, or questions, please refer to the main project repository.