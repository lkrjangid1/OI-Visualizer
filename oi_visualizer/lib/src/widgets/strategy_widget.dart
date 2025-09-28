import 'package:flutter/material.dart';
import '../models/option_leg.dart';
import '../models/data_item.dart';
import '../theme/oi_theme.dart';

class StrategyWidget extends StatefulWidget {
  final String underlying;
  final String? nextUpdateAt;
  final List<OptionLeg> optionLegs;
  final List<String> expiries;
  final String? selectedExpiry;
  final List<DataItem>? optionChainData;
  final ValueChanged<List<OptionLeg>>? onOptionLegsChanged;
  final ValueChanged<String>? onExpiryChanged;
  final VoidCallback? onAddEditLegs;

  const StrategyWidget({
    super.key,
    required this.underlying,
    this.nextUpdateAt,
    required this.optionLegs,
    required this.expiries,
    this.selectedExpiry,
    this.optionChainData,
    this.onOptionLegsChanged,
    this.onExpiryChanged,
    this.onAddEditLegs,
  });

  @override
  State<StrategyWidget> createState() => _StrategyWidgetState();
}

class _StrategyWidgetState extends State<StrategyWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(OITheme.defaultBorderRadius),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Strategy',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          if (widget.optionLegs.isNotEmpty) ...[
            // Option legs list
            Container(
              constraints: const BoxConstraints(minWidth: 395),
              child: Column(
                children: [
                  // Header
                  if (widget.optionLegs.isNotEmpty)
                    _buildOptionLegHeader(),

                  // Option legs
                  ...widget.optionLegs.asMap().entries.map((entry) {
                    final index = entry.key;
                    final leg = entry.value;
                    return _buildOptionLeg(
                      index,
                      leg,
                      showHeader: index == 0,
                    );
                  }),
                ],
              ),
            ),
          ],

          // Strategy info
          if (widget.optionLegs.where((leg) => leg.active == true).isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildStrategyInfo(),
          ],

          // Add/Edit button
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton(
              onPressed: widget.onAddEditLegs,
              style: OutlinedButton.styleFrom(
                foregroundColor: OITheme.primaryBlue,
                side: BorderSide(color: OITheme.primaryBlue),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
              child: const Text('Add/Edit'),
            ),
          ),

          // Next update info
          if (widget.nextUpdateAt != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              child: Text(
                '${widget.nextUpdateAt}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionLegHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 25), // Checkbox space
          _buildHeaderItem('B/S', 25),
          _buildHeaderItem('Expiry', 60),
          _buildHeaderItem('Strike', 50),
          _buildHeaderItem('Type', 25),
          _buildHeaderItem('Lots', 40),
          _buildHeaderItem('Price', 50),
          SizedBox(width: 25), // Delete button space
        ],
      ),
    );
  }

  Widget _buildHeaderItem(String title, double width) {
    return Container(
      width: width,
      alignment: Alignment.center,
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 12,
          color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _buildOptionLeg(int index, OptionLeg leg, {bool showHeader = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          // Active checkbox
          SizedBox(
            width: 25,
            height: 25,
            child: Checkbox(
              value: leg.active ?? false,
              onChanged: (value) => _updateLeg(index, leg.copyWith(active: value)),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),

          // Action button (B/S)
          _buildActionButton(index, leg),

          // Expiry select
          _buildExpirySelect(index, leg),

          // Strike select
          _buildStrikeSelect(index, leg),

          // Type button (CE/PE)
          _buildTypeButton(index, leg),

          // Lots select
          _buildLotsSelect(index, leg),

          // Price input
          _buildPriceInput(index, leg),

          // Delete button
          SizedBox(
            width: 25,
            height: 25,
            child: IconButton(
              onPressed: () => _deleteLeg(index),
              icon: const Icon(Icons.delete_outline, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 25,
                minHeight: 25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(int index, OptionLeg leg) {
    final isBuy = leg.action == OptionAction.buy;
    return Container(
      width: 25,
      height: 25,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: isBuy ? OITheme.buySecondaryColor : OITheme.sellSecondaryColor,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: () => _updateLeg(
            index,
            leg.copyWith(
              action: isBuy ? OptionAction.sell : OptionAction.buy,
            ),
          ),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            alignment: Alignment.center,
            child: Text(
              isBuy ? 'B' : 'S',
              style: TextStyle(
                fontSize: 12,
                color: isBuy ? OITheme.primaryBlue : OITheme.sellColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpirySelect(int index, OptionLeg leg) {
    return Container(
      width: 60,
      height: 25,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: DropdownButtonFormField<String>(
        value: widget.expiries.contains(leg.expiry) ? leg.expiry : null,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          isDense: true,
        ),
        style: const TextStyle(fontSize: 10),
        items: widget.expiries.map((expiry) {
          return DropdownMenuItem(
            value: expiry,
            child: Text(
              expiry.length > 8 ? expiry.substring(0, 8) : expiry,
              style: const TextStyle(fontSize: 10),
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            _updateLeg(index, leg.copyWith(expiry: value));
          }
        },
      ),
    );
  }

  Widget _buildStrikeSelect(int index, OptionLeg leg) {
    return Container(
      width: 50,
      height: 25,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: TextFormField(
        initialValue: leg.strike?.toString() ?? '',
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          isDense: true,
        ),
        style: const TextStyle(fontSize: 10),
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        onChanged: (value) {
          final strike = double.tryParse(value);
          if (strike != null) {
            _updateLeg(index, leg.copyWith(strike: strike));
          }
        },
      ),
    );
  }

  Widget _buildTypeButton(int index, OptionLeg leg) {
    final isCall = leg.type == OptionType.call;
    return Container(
      width: 25,
      height: 25,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _updateLeg(
            index,
            leg.copyWith(
              type: isCall ? OptionType.put : OptionType.call,
            ),
          ),
          borderRadius: BorderRadius.circular(5),
          child: Container(
            alignment: Alignment.center,
            child: Text(
              isCall ? 'CE' : 'PE',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLotsSelect(int index, OptionLeg leg) {
    return Container(
      width: 40,
      height: 25,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: TextFormField(
        initialValue: leg.lots?.toString() ?? '1',
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          isDense: true,
        ),
        style: const TextStyle(fontSize: 10),
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        onChanged: (value) {
          final lots = int.tryParse(value);
          if (lots != null && lots > 0) {
            _updateLeg(index, leg.copyWith(lots: lots));
          }
        },
      ),
    );
  }

  Widget _buildPriceInput(int index, OptionLeg leg) {
    return Container(
      width: 50,
      height: 25,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: TextFormField(
        initialValue: leg.price?.toStringAsFixed(2) ?? '',
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          isDense: true,
        ),
        style: const TextStyle(fontSize: 10),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        onChanged: (value) {
          final price = double.tryParse(value);
          if (price != null) {
            _updateLeg(index, leg.copyWith(price: price));
          }
        },
      ),
    );
  }

  Widget _buildStrategyInfo() {
    final activeLegs = widget.optionLegs.where((leg) => leg.active == true).toList();
    if (activeLegs.isEmpty) return const SizedBox.shrink();

    // Calculate total price and premium
    double totalPrice = 0;
    double totalPremium = 0;
    const lotSize = 50; // Default lot size

    for (final leg in activeLegs) {
      final sign = leg.action == OptionAction.buy ? 1 : -1;
      final price = leg.price ?? 0;
      final lots = leg.lots ?? 1;

      totalPrice += sign * price * lots;
      totalPremium += sign * price * lots * lotSize;
    }

    final priceLabel = totalPrice < 0 ? 'get' : 'pay';
    final premiumLabel = totalPremium < 0 ? 'get' : 'pay';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Price $priceLabel ${totalPrice.abs().toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
          ),
          Text(
            'Premium $premiumLabel ${totalPremium.abs().toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _updateLeg(int index, OptionLeg updatedLeg) {
    final newLegs = List<OptionLeg>.from(widget.optionLegs);
    newLegs[index] = updatedLeg;
    widget.onOptionLegsChanged?.call(newLegs);
  }

  void _deleteLeg(int index) {
    final newLegs = List<OptionLeg>.from(widget.optionLegs);
    newLegs.removeAt(index);
    widget.onOptionLegsChanged?.call(newLegs);
  }
}

extension OptionLegCopyWith on OptionLeg {
  OptionLeg copyWith({
    bool? active,
    OptionAction? action,
    String? expiry,
    double? strike,
    OptionType? type,
    int? lots,
    double? price,
    double? iv,
  }) {
    return OptionLeg(
      active: active ?? this.active,
      action: action ?? this.action,
      expiry: expiry ?? this.expiry,
      strike: strike ?? this.strike,
      type: type ?? this.type,
      lots: lots ?? this.lots,
      price: price ?? this.price,
      iv: iv ?? this.iv,
    );
  }
}