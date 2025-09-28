import 'package:flutter/material.dart';
import '../models/data_item.dart';
import '../utils/chart_utils.dart';
import '../theme/oi_theme.dart';

class SummaryCard extends StatelessWidget {
  final List<DataItem> data;
  final double? underlyingPrice;
  final String title;

  const SummaryCard({
    super.key,
    required this.data,
    this.underlyingPrice,
    this.title = 'Open Interest Summary',
  });

  @override
  Widget build(BuildContext context) {
    final stats = ChartUtils.calculateOIStatistics(data);
    final impliedVolatility = ChartUtils.calculateImpliedVolatility(data, underlyingPrice);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(OITheme.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildMetricsGrid(context, stats, impliedVolatility),
            if (underlyingPrice != null) ...[
              const SizedBox(height: 16),
              _buildUnderlyingInfo(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, OIStatistics stats, double impliedVolatility) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 400;
        final crossAxisCount = isWide ? 4 : 2;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: isWide ? 1.5 : 2.0,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            _buildMetricCard(
              context,
              'Total CE OI',
              ChartUtils.formatLargeNumber(stats.ceTotalOI),
              OITheme.ceColor,
              Icons.trending_up,
            ),
            _buildMetricCard(
              context,
              'Total PE OI',
              ChartUtils.formatLargeNumber(stats.peTotalOI),
              OITheme.peColor,
              Icons.trending_down,
            ),
            _buildMetricCard(
              context,
              'CE Change',
              ChartUtils.formatLargeNumber(stats.ceChangeOI, showSign: true),
              OITheme.getPnlColor(stats.ceChangeOI),
              Icons.change_history,
            ),
            _buildMetricCard(
              context,
              'PE Change',
              ChartUtils.formatLargeNumber(stats.peChangeOI, showSign: true),
              OITheme.getPnlColor(stats.peChangeOI),
              Icons.change_history,
            ),
            _buildMetricCard(
              context,
              'PCR',
              stats.putCallRatio.toStringAsFixed(2),
              _getPCRColor(stats.putCallRatio),
              Icons.balance,
            ),
            _buildMetricCard(
              context,
              'Total OI',
              ChartUtils.formatLargeNumber(stats.totalOI),
              Theme.of(context).colorScheme.primary,
              Icons.pie_chart,
            ),
            _buildMetricCard(
              context,
              'Total Change',
              ChartUtils.formatLargeNumber(stats.totalChangeOI, showSign: true),
              OITheme.getPnlColor(stats.totalChangeOI),
              Icons.analytics,
            ),
            _buildMetricCard(
              context,
              'IV',
              '${(impliedVolatility * 100).toStringAsFixed(1)}%',
              Theme.of(context).colorScheme.secondary,
              Icons.show_chart,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard(BuildContext context, String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(OITheme.compactBorderRadius),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildUnderlyingInfo(BuildContext context) {
    final atmStrikes = data.where((item) =>
        ChartUtils.isAtTheMoney(item.strikePrice, underlyingPrice)).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(OITheme.defaultBorderRadius),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.gps_fixed,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Underlying: ₹${underlyingPrice!.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (atmStrikes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'ATM Strikes: ${atmStrikes.map((item) => item.strikePrice?.toStringAsFixed(0)).join(', ')}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getPCRColor(double pcr) {
    if (pcr > 1.2) return OITheme.peColor;      // Bearish
    if (pcr < 0.8) return OITheme.ceColor;      // Bullish
    return Colors.orange;                        // Neutral
  }
}