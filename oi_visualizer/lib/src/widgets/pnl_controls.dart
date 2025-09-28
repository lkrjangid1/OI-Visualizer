import 'package:flutter/material.dart';
import '../models/builder_data.dart';
import '../models/option_leg.dart';
import '../theme/oi_theme.dart';

class PNLControls extends StatefulWidget {
  final List<OptionLeg> optionLegs;
  final double? underlyingPrice;
  final double? targetUnderlyingPrice;
  final DateTime targetDateTime;
  final List<ProjectedFuturesPrice>? projectedFuturePrices;
  final ValueChanged<double>? onTargetPriceChanged;
  final ValueChanged<DateTime>? onTargetDateTimeChanged;
  final VoidCallback? onResetAutoUpdate;

  const PNLControls({
    super.key,
    required this.optionLegs,
    this.underlyingPrice,
    this.targetUnderlyingPrice,
    required this.targetDateTime,
    this.projectedFuturePrices,
    this.onTargetPriceChanged,
    this.onTargetDateTimeChanged,
    this.onResetAutoUpdate,
  });

  @override
  State<PNLControls> createState() => _PNLControlsState();
}

class _PNLControlsState extends State<PNLControls> {
  late double _targetPrice;
  late DateTime _targetDateTime;
  bool _autoUpdate = true;

  @override
  void initState() {
    super.initState();
    _targetPrice = widget.targetUnderlyingPrice ?? widget.underlyingPrice ?? 0;
    _targetDateTime = widget.targetDateTime;
  }

  @override
  void didUpdateWidget(PNLControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.targetUnderlyingPrice != oldWidget.targetUnderlyingPrice) {
      _targetPrice = widget.targetUnderlyingPrice ?? widget.underlyingPrice ?? 0;
    }
    if (widget.targetDateTime != oldWidget.targetDateTime) {
      _targetDateTime = widget.targetDateTime;
    }
  }

  double get _minTargetPrice => (widget.underlyingPrice ?? 0) * 0.9;
  double get _maxTargetPrice => (widget.underlyingPrice ?? 0) * 1.1;
  double get _step => (widget.underlyingPrice ?? 0) * 0.005;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // Main controls section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 768;

                if (isMobile) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDateTimeSelector(),
                      const SizedBox(height: 20),
                      _buildPriceSelector(),
                    ],
                  );
                } else {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildDateTimeSelector(),
                      const SizedBox(width: 20),
                      Expanded(child: _buildPriceSelector()),
                    ],
                  );
                }
              },
            ),
          ),
          // Info section
          _buildInfoSection(),
        ],
      ),
    );
  }

  Widget _buildDateTimeSelector() {
    final activeLegs = widget.optionLegs.where((leg) => leg.active == true).toList();
    final disabled = activeLegs.isEmpty;

    return SizedBox(
      width: 250,
      child: InkWell(
        onTap: disabled ? null : () => _showDateTimePicker(),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Target Datetime',
            border: const OutlineInputBorder(),
            enabled: !disabled,
            prefixIcon: IconButton(
              onPressed: disabled || _autoUpdate ? null : _handleDateTimeReset,
              icon: Icon(
                Icons.update,
                color: disabled || _autoUpdate
                    ? Theme.of(context).disabledColor
                    : OITheme.primaryBlue,
              ),
            ),
          ),
          child: Text(
            _formatDateTime(_targetDateTime),
            style: TextStyle(
              color: disabled
                  ? Theme.of(context).disabledColor
                  : Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceSelector() {
    final resetDisabled = _autoUpdate || _targetPrice == widget.underlyingPrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Target Underlying Price',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: resetDisabled ? null : _handlePriceReset,
                  child: Text(
                    'Reset & Auto Update',
                    style: TextStyle(
                      fontSize: 14,
                      color: resetDisabled
                          ? Theme.of(context).disabledColor
                          : OITheme.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
            _buildPriceInputWidget(),
          ],
        ),
        const SizedBox(height: 8),
        _buildPriceSlider(),
      ],
    );
  }

  Widget _buildPriceInputWidget() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.6),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrease button
          Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.6),
                ),
              ),
            ),
            child: IconButton(
              onPressed: _targetPrice <= _minTargetPrice ? null : () {
                setState(() {
                  _targetPrice = (_targetPrice - _step).clamp(_minTargetPrice, _maxTargetPrice);
                  _autoUpdate = false;
                });
                widget.onTargetPriceChanged?.call(_targetPrice);
              },
              icon: const Icon(Icons.remove, size: 16),
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
            ),
          ),
          // Price input
          SizedBox(
            width: 120,
            child: TextField(
              controller: TextEditingController(text: _targetPrice.toStringAsFixed(2)),
              textAlign: TextAlign.center,
              readOnly: true,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          // Increase button
          Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.6),
                ),
              ),
            ),
            child: IconButton(
              onPressed: _targetPrice >= _maxTargetPrice ? null : () {
                setState(() {
                  _targetPrice = (_targetPrice + _step).clamp(_minTargetPrice, _maxTargetPrice);
                  _autoUpdate = false;
                });
                widget.onTargetPriceChanged?.call(_targetPrice);
              },
              icon: const Icon(Icons.add, size: 16),
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSlider() {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 10,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        activeTrackColor: OITheme.primaryBlue,
        inactiveTrackColor: Theme.of(context).dividerColor.withOpacity(0.3),
        thumbColor: OITheme.primaryBlue,
      ),
      child: Slider(
        value: _targetPrice.clamp(_minTargetPrice, _maxTargetPrice),
        min: _minTargetPrice,
        max: _maxTargetPrice,
        divisions: ((_maxTargetPrice - _minTargetPrice) / _step).round(),
        onChanged: (value) {
          setState(() {
            _targetPrice = value;
            _autoUpdate = false;
          });
          widget.onTargetPriceChanged?.call(value);
        },
      ),
    );
  }

  Widget _buildInfoSection() {
    final activeLegs = widget.optionLegs.where((leg) => leg.active == true).toList();
    final show = activeLegs.isNotEmpty &&
                 widget.projectedFuturePrices != null &&
                 widget.projectedFuturePrices!.isNotEmpty;

    if (!show) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Target Datetime Futures Prices',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: widget.projectedFuturePrices!.map((item) {
              return Container(
                width: 240,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.03),
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.expiry ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                      ),
                    ),
                    Text(
                      (item.price ?? 0).toStringAsFixed(2),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showDateTimePicker() async {
    final now = DateTime.now();
    final maxDate = DateTime.now().add(const Duration(days: 365));

    final date = await showDatePicker(
      context: context,
      initialDate: _targetDateTime,
      firstDate: now,
      lastDate: maxDate,
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_targetDateTime),
      );

      if (time != null && mounted) {
        final newDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        setState(() {
          _targetDateTime = newDateTime;
          _autoUpdate = false;
        });

        widget.onTargetDateTimeChanged?.call(newDateTime);
      }
    }
  }

  void _handleDateTimeReset() {
    final defaultDateTime = DateTime.now().add(const Duration(days: 30));
    setState(() {
      _targetDateTime = defaultDateTime;
      _autoUpdate = true;
    });
    widget.onTargetDateTimeChanged?.call(defaultDateTime);
  }

  void _handlePriceReset() {
    if (widget.underlyingPrice != null) {
      setState(() {
        _targetPrice = widget.underlyingPrice!;
        _autoUpdate = true;
      });
      widget.onTargetPriceChanged?.call(widget.underlyingPrice!);
      widget.onResetAutoUpdate?.call();
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
           '${dateTime.month.toString().padLeft(2, '0')}/'
           '${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}