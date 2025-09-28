import 'package:flutter/material.dart';
import '../models/builder_data.dart';
import '../models/option_leg.dart';
import '../theme/oi_theme.dart';
import 'pnl_chart.dart';

// ignore: must_be_immutable
class PNLVisualizer extends StatelessWidget {
  BuilderData? data;
  List<OptionLeg> optionLegs;
  bool isLoading;
  bool isError;
  String? errorMessage;
  VoidCallback? onCalculatePNL;

  PNLVisualizer({
    super.key,
    this.data,
    required this.optionLegs,
    this.isLoading = false,
    this.isError = false,
    this.errorMessage,
    this.onCalculatePNL,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(OITheme.defaultBorderRadius),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: _buildContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Profit & Loss Visualizer',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: MediaQuery.of(context).size.width < 600 ? 12 : 16,
            ),
          ),
          _buildLegend(context),
        ],
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Row(
      children: [
        _buildLegendItem(
          context,
          'Target',
          OITheme.targetColor,
          isLine: true,
        ),
        const SizedBox(width: 20),
        _buildLegendItem(
          context,
          'Expiry',
          null,
          isLine: false,
          isSegmented: true,
        ),
      ],
    );
  }

  Widget _buildLegendItem(
    BuildContext context,
    String label,
    Color? color, {
    bool isLine = true,
    bool isSegmented = false,
  }) {
    final isSmall = MediaQuery.of(context).size.width < 600;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLine) ...[
          Container(
            width: isSmall ? 20 : 30,
            height: isSmall ? 3 : 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ] else if (isSegmented) ...[
          Row(
            children: [
              Container(
                width: isSmall ? 10 : 15,
                height: isSmall ? 3 : 4,
                decoration: const BoxDecoration(
                  color: OITheme.profitColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(5),
                    bottomLeft: Radius.circular(5),
                  ),
                ),
              ),
              Container(
                width: isSmall ? 10 : 15,
                height: isSmall ? 3 : 4,
                decoration: const BoxDecoration(
                  color: OITheme.lossColor,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(5),
                    bottomRight: Radius.circular(5),
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(width: 10),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: isSmall ? 12 : 14,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    final activeLegs = optionLegs.where((leg) => leg.active == true).toList();

    if (activeLegs.isEmpty) {
      return _buildEmptyState(context);
    }

    if (isLoading) {
      return _buildLoadingState(context);
    }

    if (isError) {
      return _buildErrorState(context);
    }

    if (data == null) {
      return _buildCalculatePrompt(context);
    }

    return _buildChart(context);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 60,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Add or enable option legs to visualize payoff',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Calculating P&L...',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 60,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            errorMessage ?? 'Something went wrong',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          if (onCalculatePNL != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onCalculatePNL,
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCalculatePrompt(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calculate,
            size: 60,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Configure your strategy and calculate to see P&L',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (onCalculatePNL != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onCalculatePNL,
              icon: const Icon(Icons.calculate),
              label: const Text('Calculate P&L'),
              style: ElevatedButton.styleFrom(
                backgroundColor: OITheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: PNLChart(data: data!),
    );
  }
}