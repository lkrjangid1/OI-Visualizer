import 'package:flutter/material.dart';
import '../models/data_item.dart';
import '../models/option_leg.dart';
import '../models/greeks.dart';
import '../theme/oi_theme.dart';

class OptionChainRow {
  final double? putPrice;
  final double? putOI;
  final double strike;
  final double? callOI;
  final double? callPrice;
  final double syntheticFuturesPrice;
  final double? iv;
  final Greeks? ceGreeks;
  final Greeks? peGreeks;

  const OptionChainRow({
    this.putPrice,
    this.putOI,
    required this.strike,
    this.callOI,
    this.callPrice,
    required this.syntheticFuturesPrice,
    this.iv,
    this.ceGreeks,
    this.peGreeks,
  });

  factory OptionChainRow.fromDataItem(DataItem item) {
    return OptionChainRow(
      putPrice: item.pe?.lastPrice,
      putOI: item.pe?.openInterest?.toDouble(),
      strike: item.strikePrice ?? 0,
      callOI: item.ce?.openInterest?.toDouble(),
      callPrice: item.ce?.lastPrice,
      syntheticFuturesPrice: item.syntheticFuturesPrice ?? 0,
      iv: item.iv,
      ceGreeks: item.ce?.greeks,
      peGreeks: item.pe?.greeks,
    );
  }
}

class SelectedOptionsInRow {
  final bool ceBuy;
  final bool ceSell;
  final int ceLots;
  final int? ceLegIndex;
  final bool peBuy;
  final bool peSell;
  final int peLots;
  final int? peLegIndex;

  const SelectedOptionsInRow({
    this.ceBuy = false,
    this.ceSell = false,
    this.ceLots = 1,
    this.ceLegIndex,
    this.peBuy = false,
    this.peSell = false,
    this.peLots = 1,
    this.peLegIndex,
  });
}

class AddEditLegs extends StatefulWidget {
  final List<OptionChainRow> rows;
  final List<String> expiries;
  final String? selectedExpiry;
  final double? strikePriceATM;
  final List<OptionLeg> optionLegs;
  final ValueChanged<String>? onExpiryChanged;
  final ValueChanged<List<OptionLeg>>? onOptionLegsChanged;
  final VoidCallback? onClose;

  const AddEditLegs({
    super.key,
    required this.rows,
    required this.expiries,
    this.selectedExpiry,
    this.strikePriceATM,
    required this.optionLegs,
    this.onExpiryChanged,
    this.onOptionLegsChanged,
    this.onClose,
  });

  @override
  State<AddEditLegs> createState() => _AddEditLegsState();
}

class _AddEditLegsState extends State<AddEditLegs> {
  @override
  Widget build(BuildContext context) {
    final maxCallOI = widget.rows.fold<double>(
      0,
      (max, row) => row.callOI != null && row.callOI! > max ? row.callOI! : max,
    );
    final maxPutOI = widget.rows.fold<double>(
      0,
      (max, row) => row.putOI != null && row.putOI! > max ? row.putOI! : max,
    );
    final maxOI = maxCallOI > maxPutOI ? maxCallOI : maxPutOI;

    return Material(
      elevation: 5,
      color: Theme.of(context).colorScheme.surface,
      child: Container(
        height: MediaQuery.of(context).size.height,
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          children: [
            // Header with expiry selector and done button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildExpirySelector(),
                  ElevatedButton(
                    onPressed: widget.onClose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: OITheme.primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),

            // Option chain table
            Expanded(child: _buildOptionChainTable(maxOI)),
          ],
        ),
      ),
    );
  }

  Widget _buildExpirySelector() {
    return SizedBox(
      width: 200,
      child: DropdownButtonFormField<String>(
        value:
            widget.expiries.contains(widget.selectedExpiry)
                ? widget.selectedExpiry
                : null,
        decoration: const InputDecoration(
          labelText: 'Select Expiry',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items:
            widget.expiries.map((expiry) {
              return DropdownMenuItem(value: expiry, child: Text(expiry));
            }).toList(),
        onChanged: (value) {
          if (value != null) {
            widget.onExpiryChanged?.call(value);
          }
        },
      ),
    );
  }

  Widget _buildOptionChainTable(double maxOI) {
    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          children: [
            // Table header
            _buildTableHeader(),

            // Table rows
            ...widget.rows.map((row) => _buildOptionChainRow(row, maxOI)),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          _buildHeaderCell('Delta', 60),
          _buildHeaderCell('Call LTP', 120),
          _buildHeaderCell('Strike', 80),
          _buildHeaderCell('IV', 60),
          _buildHeaderCell('Put LTP', 120),
          _buildHeaderCell('Delta', 60),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String title, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
        ),
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildOptionChainRow(OptionChainRow row, double maxOI) {
    final selectedOptions = _getSelectedOptionsForRow(row);
    final isATM =
        widget.strikePriceATM != null && row.strike == widget.strikePriceATM;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          // Call Delta
          _buildDataCell(
            _formatValue(row.ceGreeks?.delta, precision: 1),
            60,
            isATM: isATM,
          ),

          // Call LTP with OI bar and actions
          _buildCallPutCell(
            price: row.callPrice,
            oi: row.callOI,
            maxOI: maxOI,
            width: 120,
            isCall: true,
            isATM: isATM,
            isBuy: selectedOptions.ceBuy,
            isSell: selectedOptions.ceSell,
            lots: selectedOptions.ceLots,
            showLots: selectedOptions.ceBuy || selectedOptions.ceSell,
            onBuyPressed:
                () => _handleAction(row, OptionType.call, OptionAction.buy),
            onSellPressed:
                () => _handleAction(row, OptionType.call, OptionAction.sell),
            onLotsChanged:
                (lots) => _handleLotsChange(row, OptionType.call, lots),
          ),

          // Strike
          _buildDataCell(
            row.strike.toStringAsFixed(0),
            80,
            isATM: isATM,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
          ),

          // IV
          _buildDataCell(
            _formatValue(row.iv, precision: 1, isIV: true),
            60,
            isATM: isATM,
          ),

          // Put LTP with OI bar and actions
          _buildCallPutCell(
            price: row.putPrice,
            oi: row.putOI,
            maxOI: maxOI,
            width: 120,
            isCall: false,
            isATM: isATM,
            isBuy: selectedOptions.peBuy,
            isSell: selectedOptions.peSell,
            lots: selectedOptions.peLots,
            showLots: selectedOptions.peBuy || selectedOptions.peSell,
            onBuyPressed:
                () => _handleAction(row, OptionType.put, OptionAction.buy),
            onSellPressed:
                () => _handleAction(row, OptionType.put, OptionAction.sell),
            onLotsChanged:
                (lots) => _handleLotsChange(row, OptionType.put, lots),
          ),

          // Put Delta
          _buildDataCell(
            _formatValue(row.peGreeks?.delta, precision: 1),
            60,
            isATM: isATM,
          ),
        ],
      ),
    );
  }

  Widget _buildDataCell(
    String value,
    double width, {
    bool isATM = false,
    Color? backgroundColor,
  }) {
    Color? bgColor = backgroundColor;
    if (isATM) {
      bgColor = OITheme.tableCellATM;
    }

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
        ),
      ),
      child: Text(
        value,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCallPutCell({
    required double? price,
    required double? oi,
    required double maxOI,
    required double width,
    required bool isCall,
    required bool isATM,
    required bool isBuy,
    required bool isSell,
    required int lots,
    required bool showLots,
    required VoidCallback onBuyPressed,
    required VoidCallback onSellPressed,
    required ValueChanged<int> onLotsChanged,
  }) {
    final oiWidth =
        (oi != null && maxOI > 0) ? (oi / maxOI) * width * 0.8 : 0.0;

    Color? backgroundColor;
    if (isATM) {
      backgroundColor = OITheme.tableCellATM;
    } else if (!isCall &&
        widget.strikePriceATM != null &&
        price != null &&
        price > (widget.strikePriceATM ?? 0)) {
      backgroundColor = OITheme.tableCellITM;
    } else if (isCall &&
        widget.strikePriceATM != null &&
        price != null &&
        price < (widget.strikePriceATM ?? 0)) {
      backgroundColor = OITheme.tableCellITM;
    }

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 40,
            child: Stack(
              children: [
                // OI Background bar
                if (oiWidth > 0)
                  Positioned(
                    left: isCall ? 0 : width - oiWidth,
                    top: 8,
                    child: Container(
                      width: oiWidth,
                      height: 24,
                      decoration: BoxDecoration(
                        color:
                            isCall
                                ? OITheme.lossColor.withValues(alpha: 0.3)
                                : OITheme.profitColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.horizontal(
                          left:
                              isCall ? Radius.zero : const Radius.circular(20),
                          right:
                              isCall ? const Radius.circular(20) : Radius.zero,
                        ),
                      ),
                    ),
                  ),

                // Price text
                Positioned(
                  left: isCall ? 8 : null,
                  right: isCall ? null : 8,
                  top: 8,
                  child: Container(
                    height: 24,
                    alignment:
                        isCall ? Alignment.centerLeft : Alignment.centerRight,
                    child: Text(
                      _formatValue(price),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(fontSize: 12),
                    ),
                  ),
                ),

                // Action buttons
                Positioned(
                  left: isCall ? null : 8,
                  right: isCall ? 8 : null,
                  top: 8,
                  child: _buildActionButtons(
                    isBuy: isBuy,
                    isSell: isSell,
                    onBuyPressed: onBuyPressed,
                    onSellPressed: onSellPressed,
                  ),
                ),
              ],
            ),
          ),

          // Lots selector
          if (showLots)
            Padding(
              padding: EdgeInsets.only(
                left: isCall ? 0 : 8,
                right: isCall ? 8 : 0,
                bottom: 8,
              ),
              child: _buildLotsSelector(lots, onLotsChanged),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons({
    required bool isBuy,
    required bool isSell,
    required VoidCallback onBuyPressed,
    required VoidCallback onSellPressed,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton('B', isBuy, onBuyPressed, true),
        const SizedBox(width: 2),
        _buildActionButton('S', isSell, onSellPressed, false),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    bool isActive,
    VoidCallback onPressed,
    bool isBuy,
  ) {
    return SizedBox(
      width: 20,
      height: 16,
      child: Material(
        color:
            isActive
                ? (isBuy ? OITheme.primaryBlue : OITheme.sellColor)
                : (isBuy
                    ? OITheme.buySecondaryColor
                    : OITheme.sellSecondaryColor),
        borderRadius: BorderRadius.circular(2),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(2),
          child: Container(
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color:
                    isActive
                        ? Colors.white
                        : (isBuy ? OITheme.primaryBlue : OITheme.sellColor),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLotsSelector(int lots, ValueChanged<int> onChanged) {
    return SizedBox(
      width: 50,
      child: DropdownButtonFormField<int>(
        value: lots,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          isDense: true,
        ),
        style: const TextStyle(fontSize: 10),
        items:
            List.generate(150, (i) => i + 1).map((lot) {
              return DropdownMenuItem(value: lot, child: Text(lot.toString()));
            }).toList(),
        onChanged: (value) {
          if (value != null) {
            onChanged(value);
          }
        },
      ),
    );
  }

  SelectedOptionsInRow _getSelectedOptionsForRow(OptionChainRow row) {
    bool ceBuy = false, ceSell = false, peBuy = false, peSell = false;
    int ceLots = 1, peLots = 1;
    int? ceLegIndex, peLegIndex;

    for (int i = 0; i < widget.optionLegs.length; i++) {
      final leg = widget.optionLegs[i];
      if (leg.expiry == widget.selectedExpiry && leg.strike == row.strike) {
        if (leg.type == OptionType.call) {
          ceBuy = leg.action == OptionAction.buy;
          ceSell = leg.action == OptionAction.sell;
          ceLots = leg.lots ?? 1;
          ceLegIndex = i;
        } else if (leg.type == OptionType.put) {
          peBuy = leg.action == OptionAction.buy;
          peSell = leg.action == OptionAction.sell;
          peLots = leg.lots ?? 1;
          peLegIndex = i;
        }
      }
    }

    return SelectedOptionsInRow(
      ceBuy: ceBuy,
      ceSell: ceSell,
      ceLots: ceLots,
      ceLegIndex: ceLegIndex,
      peBuy: peBuy,
      peSell: peSell,
      peLots: peLots,
      peLegIndex: peLegIndex,
    );
  }

  void _handleAction(OptionChainRow row, OptionType type, OptionAction action) {
    final newLegs = List<OptionLeg>.from(widget.optionLegs);
    final selectedOptions = _getSelectedOptionsForRow(row);

    // Find existing leg index
    int? existingIndex;
    bool currentlyHasThisAction = false;

    for (int i = 0; i < newLegs.length; i++) {
      final leg = newLegs[i];
      if (leg.expiry == widget.selectedExpiry &&
          leg.strike == row.strike &&
          leg.type == type) {
        existingIndex = i;
        currentlyHasThisAction = leg.action == action;
        break;
      }
    }

    if (currentlyHasThisAction) {
      // Remove the leg if clicking the same action
      if (existingIndex != null) {
        newLegs.removeAt(existingIndex);
      }
    } else {
      // Create new leg or update existing
      final newLeg = OptionLeg(
        active: true,
        action: action,
        expiry: widget.selectedExpiry,
        strike: row.strike,
        type: type,
        lots:
            type == OptionType.call
                ? selectedOptions.ceLots
                : selectedOptions.peLots,
        price: type == OptionType.call ? row.callPrice : row.putPrice,
        iv: row.iv,
      );

      if (existingIndex != null) {
        newLegs[existingIndex] = newLeg;
      } else if (newLegs.length < 10) {
        newLegs.add(newLeg);
      } else {
        // Show max legs warning
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maximum 10 legs allowed in a strategy'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    widget.onOptionLegsChanged?.call(newLegs);
  }

  void _handleLotsChange(OptionChainRow row, OptionType type, int lots) {
    final newLegs = List<OptionLeg>.from(widget.optionLegs);
    // final selectedOptions = _getSelectedOptionsForRow(row);

    // Find existing leg
    for (int i = 0; i < newLegs.length; i++) {
      final leg = newLegs[i];
      if (leg.expiry == widget.selectedExpiry &&
          leg.strike == row.strike &&
          leg.type == type) {
        newLegs[i] = OptionLeg(
          active: leg.active,
          action: leg.action,
          expiry: leg.expiry,
          strike: leg.strike,
          type: leg.type,
          lots: lots,
          price: leg.price,
          iv: leg.iv,
        );
        break;
      }
    }

    widget.onOptionLegsChanged?.call(newLegs);
  }

  String _formatValue(double? value, {int precision = 2, bool isIV = false}) {
    if (value == null) return '-';

    final multiplier = isIV ? 100 : 1;
    final result = value * multiplier;

    if (result.abs() < (isIV ? 0.1 : 0.01)) return '-';

    return result.toStringAsFixed(precision);
  }
}
