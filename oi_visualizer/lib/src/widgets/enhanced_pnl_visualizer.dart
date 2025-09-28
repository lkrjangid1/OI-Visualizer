import 'package:flutter/material.dart';
import '../models/builder_data.dart';
import '../models/option_leg.dart';
import 'pnl_chart.dart';

class EnhancedPNLVisualizer extends StatefulWidget {
  final BuilderData? builderData;
  final List<OptionLeg> optionLegs;
  final bool isFetching;
  final bool isError;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final double? underlyingPrice;
  final double? targetUnderlyingPrice;
  final double? payoffAtTarget;

  const EnhancedPNLVisualizer({
    super.key,
    this.builderData,
    this.optionLegs = const [],
    this.isFetching = false,
    this.isError = false,
    this.errorMessage,
    this.onRetry,
    this.underlyingPrice,
    this.targetUnderlyingPrice,
    this.payoffAtTarget,
  });

  @override
  State<EnhancedPNLVisualizer> createState() => _EnhancedPNLVisualizerState();
}

class _EnhancedPNLVisualizerState extends State<EnhancedPNLVisualizer> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Profit & Loss Visualizer',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLegendItem(
          'Target',
          Theme.of(context).colorScheme.primary,
          isLine: true,
        ),
        const SizedBox(width: 20),
        _buildLegendItem(
          'Expiry',
          null,
          isGradient: true,
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color? color, {bool isLine = false, bool isGradient = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isLine ? 30 : 30,
          height: isLine ? 4 : 4,
          decoration: BoxDecoration(
            color: isGradient ? null : color,
            gradient: isGradient ? LinearGradient(
              colors: [
                Colors.green.withValues(alpha: 0.6),
                Colors.red.withValues(alpha: 0.6),
              ],
            ) : null,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildContent() {
    // Check if there are active option legs
    final activeLegs = widget.optionLegs.where((leg) => leg.active ?? false).toList();

    if (activeLegs.isEmpty) {
      return _buildEmptyState();
    }

    if (widget.builderData == null) {
      return _buildLoadingOrError();
    }

    return PNLChart(
      data: widget.builderData!,
      isFetching: widget.isFetching,
      isError: widget.isError,
      errorMessage: widget.errorMessage,
      onRetry: widget.onRetry,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline,
            size: 60,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Add or enable option legs to visualize payoff',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOrError() {
    if (widget.isError) {
      return Center(
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
              widget.errorMessage ?? 'Failed to load payoff data',
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
      );
    }

    if (widget.isFetching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Center(
      child: Text(
        'No data available',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}