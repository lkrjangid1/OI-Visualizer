import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/data_item.dart';
import '../models/contract_data.dart';

enum OIChartType { change, total }

class OIChart extends StatefulWidget {
  final List<DataItem> data;
  final OIChartType type;
  final double? underlyingPrice;

  const OIChart({
    super.key,
    required this.data,
    required this.type,
    this.underlyingPrice,
  });

  @override
  State<OIChart> createState() => _OIChartState();
}

class _OIChartState extends State<OIChart> {
  int? _hoveredIndex;
  Offset? _mousePosition;
  bool _showTooltip = false;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: OIChartPainter(
            data: widget.data,
            type: widget.type,
            underlyingPrice: widget.underlyingPrice,
            hoveredIndex: _hoveredIndex,
            context: context,
          ),
          child: MouseRegion(
            onHover: (event) {
              _handleHover(event, constraints);
            },
            onExit: (_) {
              setState(() {
                _hoveredIndex = null;
                _showTooltip = false;
                _mousePosition = null;
              });
            },
            child: GestureDetector(
              onTapDown: (details) {
                _handleTap(details, constraints);
              },
              onPanUpdate: (details) {
                _handlePan(details, constraints);
              },
              onPanEnd: (_) {
                setState(() {
                  _hoveredIndex = null;
                  _showTooltip = false;
                  _mousePosition = null;
                });
              },
              child: Stack(
                children: [
                  Container(),
                  if (_showTooltip && _hoveredIndex != null && _mousePosition != null)
                    _buildTooltip(constraints),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleTap(TapDownDetails details, BoxConstraints constraints) {
    final index = _getDataIndexFromPosition(details.localPosition, constraints);
    setState(() {
      _hoveredIndex = index;
      _mousePosition = details.localPosition;
      _showTooltip = index != null;
    });
  }

  void _handlePan(DragUpdateDetails details, BoxConstraints constraints) {
    final index = _getDataIndexFromPosition(details.localPosition, constraints);
    setState(() {
      _hoveredIndex = index;
      _mousePosition = details.localPosition;
      _showTooltip = index != null;
    });
  }

  void _handleHover(PointerHoverEvent event, BoxConstraints constraints) {
    final index = _getDataIndexFromPosition(event.localPosition, constraints);
    setState(() {
      _hoveredIndex = index;
      _mousePosition = event.localPosition;
      _showTooltip = index != null;
    });
  }

  int? _getDataIndexFromPosition(Offset position, BoxConstraints constraints) {
    final barWidth = constraints.maxWidth / widget.data.length;
    final index = (position.dx / barWidth).floor();

    if (index >= 0 && index < widget.data.length) {
      return index;
    }
    return null;
  }

  Widget _buildTooltip(BoxConstraints constraints) {
    if (_hoveredIndex == null || _mousePosition == null) return Container();

    final item = widget.data[_hoveredIndex!];
    final theme = Theme.of(context);

    return Positioned(
      left: _mousePosition!.dx + 10,
      top: _mousePosition!.dy - 80,
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
                'Strike: ${item.strikePrice?.toStringAsFixed(0) ?? 'N/A'}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              if (item.ce != null) ...[
                Text(
                  'CE ${widget.type == OIChartType.change ? 'Change' : 'Total'}: ${_formatValue(_getValueFromContract(item.ce))}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.green.shade700,
                  ),
                ),
                Text(
                  'CE LTP: ${item.ce?.lastPrice?.toStringAsFixed(2) ?? 'N/A'}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
              if (item.pe != null) ...[
                Text(
                  'PE ${widget.type == OIChartType.change ? 'Change' : 'Total'}: ${_formatValue(_getValueFromContract(item.pe))}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.blue.shade700,
                  ),
                ),
                Text(
                  'PE LTP: ${item.pe?.lastPrice?.toStringAsFixed(2) ?? 'N/A'}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatValue(double? value) {
    if (value == null) return 'N/A';
    if (value.abs() >= 10000000) {
      return '${(value / 10000000).toStringAsFixed(1)}Cr';
    } else if (value.abs() >= 100000) {
      return '${(value / 100000).toStringAsFixed(1)}L';
    } else if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }

  double? _getValueFromContract(ContractData? contract) {
    if (contract == null) return null;

    switch (widget.type) {
      case OIChartType.change:
        return contract.changeinOpenInterest;
      case OIChartType.total:
        return contract.openInterest?.toDouble();
    }
  }
}

class OIChartPainter extends CustomPainter {
  final List<DataItem> data;
  final OIChartType type;
  final double? underlyingPrice;
  final int? hoveredIndex;
  final BuildContext context;

  OIChartPainter({
    required this.data,
    required this.type,
    this.underlyingPrice,
    this.hoveredIndex,
    required this.context,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Calculate scales
    final barWidth = size.width / data.length;
    final subBarWidth = barWidth * 0.8 / 2; // Two bars (CE and PE) with spacing

    // Find min/max values for scaling
    double minValue = 0;
    double maxValue = 0;

    for (final item in data) {
      final ceValue = _getValue(item.ce);
      final peValue = _getValue(item.pe);

      if (ceValue != null) {
        minValue = minValue < ceValue ? minValue : ceValue;
        maxValue = maxValue > ceValue ? maxValue : ceValue;
      }
      if (peValue != null) {
        minValue = minValue < peValue ? minValue : peValue;
        maxValue = maxValue > peValue ? maxValue : peValue;
      }
    }

    // Add some padding to the scale
    final range = maxValue - minValue;
    minValue -= range * 0.1;
    maxValue += range * 0.1;

    // Paint bars
    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final x = i * barWidth;
      final isHovered = hoveredIndex == i;

      _paintBar(
        canvas,
        x,
        size.height,
        subBarWidth,
        item.ce,
        item.pe,
        minValue,
        maxValue,
        colorScheme,
        isHovered,
        size.width,
      );
    }

    // Paint axes
    _paintAxes(canvas, size, minValue, maxValue, colorScheme);

    // Paint grid lines
    _paintGridLines(canvas, size, minValue, maxValue, colorScheme);

    // Paint underlying price line if available
    if (underlyingPrice != null) {
      _paintUnderlyingPriceLine(canvas, size, colorScheme);
    }

    // Paint legend
    _paintLegend(canvas, size, colorScheme);
  }

  void _paintGridLines(Canvas canvas, Size size, double minValue, double maxValue, ColorScheme colorScheme) {
    final paint = Paint()
      ..color = colorScheme.onSurface.withValues(alpha: 0.1)
      ..strokeWidth = 0.5;

    // Horizontal grid lines
    final labelCount = 5;
    for (int i = 1; i < labelCount; i++) {
      final y = size.height - (i / labelCount) * size.height;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  void _paintLegend(Canvas canvas, Size size, ColorScheme colorScheme) {
    final legendItems = [
      {'color': Colors.green.shade600, 'label': 'CE (Call)'},
      {'color': Colors.blue.shade600, 'label': 'PE (Put)'},
    ];

    const legendItemWidth = 80.0;
    const legendSpacing = 10.0;
    final startX = size.width - (legendItems.length * (legendItemWidth + legendSpacing));
    const startY = 10.0;

    for (int i = 0; i < legendItems.length; i++) {
      final item = legendItems[i];
      final x = startX + i * (legendItemWidth + legendSpacing);

      // Draw legend color box
      canvas.drawRect(
        Rect.fromLTWH(x, startY, 12, 12),
        Paint()..color = item['color'] as Color,
      );

      // Draw legend text
      final textPainter = TextPainter(
        text: TextSpan(
          text: item['label'] as String,
          style: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.8),
            fontSize: 11,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x + 16, startY - 1));
    }
  }

  double? _getValue(ContractData? contract) {
    if (contract == null) return null;

    switch (type) {
      case OIChartType.change:
        return contract.changeinOpenInterest;
      case OIChartType.total:
        return contract.openInterest?.toDouble();
    }
  }

  void _paintBar(
    Canvas canvas,
    double x,
    double height,
    double subBarWidth,
    ContractData? ce,
    ContractData? pe,
    double minValue,
    double maxValue,
    ColorScheme colorScheme,
    bool isHovered,
    double totalWidth,
  ) {
    final paint = Paint();
    final zeroY = height - ((0 - minValue) / (maxValue - minValue)) * height;
    final barWidth = data.isNotEmpty ? (totalWidth / data.length) : 0;

    // Paint CE bar (Call)
    final ceValue = _getValue(ce);
    if (ceValue != null) {
      final ceY = height - ((ceValue - minValue) / (maxValue - minValue)) * height;
      final ceHeight = (ceY - zeroY).abs();

      paint.color = ceValue >= 0
          ? (isHovered ? Colors.green.shade400 : Colors.green.shade600)
          : (isHovered ? Colors.red.shade400 : Colors.red.shade600);

      canvas.drawRect(
        Rect.fromLTWH(
          x + barWidth * 0.1,
          ceValue >= 0 ? ceY : zeroY,
          subBarWidth,
          ceHeight,
        ),
        paint,
      );
    }

    // Paint PE bar (Put)
    final peValue = _getValue(pe);
    if (peValue != null) {
      final peY = height - ((peValue - minValue) / (maxValue - minValue)) * height;
      final peHeight = (peY - zeroY).abs();

      paint.color = peValue >= 0
          ? (isHovered ? Colors.blue.shade400 : Colors.blue.shade600)
          : (isHovered ? Colors.orange.shade400 : Colors.orange.shade600);

      canvas.drawRect(
        Rect.fromLTWH(
          x + barWidth * 0.1 + subBarWidth,
          peValue >= 0 ? peY : zeroY,
          subBarWidth,
          peHeight,
        ),
        paint,
      );
    }
  }

  void _paintAxes(Canvas canvas, Size size, double minValue, double maxValue, ColorScheme colorScheme) {
    final paint = Paint()
      ..color = colorScheme.onSurface.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    // Y-axis
    canvas.drawLine(
      const Offset(0, 0),
      Offset(0, size.height),
      paint,
    );

    // X-axis (zero line)
    final zeroY = size.height - ((0 - minValue) / (maxValue - minValue)) * size.height;
    canvas.drawLine(
      Offset(0, zeroY),
      Offset(size.width, zeroY),
      paint,
    );

    // Paint Y-axis labels
    _paintYAxisLabels(canvas, size, minValue, maxValue, colorScheme);

    // Paint X-axis labels (strike prices)
    _paintXAxisLabels(canvas, size, colorScheme);
  }

  void _paintYAxisLabels(Canvas canvas, Size size, double minValue, double maxValue, ColorScheme colorScheme) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final labelCount = 5;
    for (int i = 0; i <= labelCount; i++) {
      final value = minValue + (maxValue - minValue) * i / labelCount;
      final y = size.height - (i / labelCount) * size.height;

      textPainter.text = TextSpan(
        text: _formatAxisValue(value),
        style: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.7),
          fontSize: 10,
        ),
      );
      textPainter.layout();

      // Draw tick mark
      canvas.drawLine(
        Offset(-5, y),
        Offset(0, y),
        Paint()
          ..color = colorScheme.onSurface.withValues(alpha: 0.3)
          ..strokeWidth = 1,
      );

      // Draw label
      textPainter.paint(canvas, Offset(-textPainter.width - 8, y - textPainter.height / 2));
    }
  }

  void _paintXAxisLabels(Canvas canvas, Size size, ColorScheme colorScheme) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final barWidth = size.width / data.length;

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      if (item.strikePrice == null) continue;

      // Only show every nth label to avoid crowding
      if (i % (data.length > 20 ? 4 : 2) != 0) continue;

      final x = (i + 0.5) * barWidth;

      textPainter.text = TextSpan(
        text: item.strikePrice!.toStringAsFixed(0),
        style: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.7),
          fontSize: 10,
        ),
      );
      textPainter.layout();

      // Draw tick mark
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x, size.height + 5),
        Paint()
          ..color = colorScheme.onSurface.withValues(alpha: 0.3)
          ..strokeWidth = 1,
      );

      // Draw label
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, size.height + 8));
    }
  }

  String _formatAxisValue(double value) {
    if (value.abs() >= 10000000) {
      return '${(value / 10000000).toStringAsFixed(1)}Cr';
    } else if (value.abs() >= 100000) {
      return '${(value / 100000).toStringAsFixed(1)}L';
    } else if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }

  void _paintUnderlyingPriceLine(Canvas canvas, Size size, ColorScheme colorScheme) {
    if (data.isEmpty || underlyingPrice == null) return;

    // Find the position of the underlying price
    final strikePrices = data
        .map((e) => e.strikePrice)
        .where((price) => price != null)
        .cast<double>()
        .toList()
      ..sort();

    if (strikePrices.isEmpty) return;

    final minStrike = strikePrices.first;
    final maxStrike = strikePrices.last;

    if (underlyingPrice! < minStrike || underlyingPrice! > maxStrike) return;

    final position = (underlyingPrice! - minStrike) / (maxStrike - minStrike);
    final x = position * size.width;

    final paint = Paint()
      ..color = colorScheme.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Draw dashed line for underlying price
    _drawDashedLine(canvas, Offset(x, 0), Offset(x, size.height), paint);

    // Draw underlying price label
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Underlying: ${underlyingPrice!.toStringAsFixed(0)}',
        style: TextStyle(
          color: colorScheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final labelX = x + 5;
    final labelY = 10.0;

    // Draw background for label
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(labelX - 2, labelY - 2, textPainter.width + 4, textPainter.height + 4),
        const Radius.circular(4),
      ),
      Paint()..color = colorScheme.surface.withValues(alpha: 0.9),
    );

    textPainter.paint(canvas, Offset(labelX, labelY));
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 3.0;
    final distance = (end - start).distance;
    final totalDashSpace = dashWidth + dashSpace;
    final dashCount = (distance / totalDashSpace).floor();

    for (int i = 0; i < dashCount; i++) {
      final startOffset = start + (end - start) * (i * totalDashSpace / distance);
      final endOffset = start + (end - start) * ((i * totalDashSpace + dashWidth) / distance);
      canvas.drawLine(startOffset, endOffset, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is! OIChartPainter) return true;
    return data != oldDelegate.data ||
           type != oldDelegate.type ||
           underlyingPrice != oldDelegate.underlyingPrice ||
           hoveredIndex != oldDelegate.hoveredIndex;
  }
}