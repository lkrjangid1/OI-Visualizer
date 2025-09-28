import 'package:flutter/material.dart';
import '../models/data_item.dart';

class DataTableView extends StatefulWidget {
  final List<DataItem> data;
  final double? underlyingPrice;

  const DataTableView({
    super.key,
    required this.data,
    this.underlyingPrice,
  });

  @override
  State<DataTableView> createState() => _DataTableViewState();
}

class _DataTableViewState extends State<DataTableView> {
  String _sortColumn = 'strikePrice';
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    final sortedData = _getSortedData();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Options Chain',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    sortColumnIndex: _getColumnIndex(_sortColumn),
                    sortAscending: _sortAscending,
                    headingRowColor: WidgetStateProperty.all(
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    columns: [
                      DataColumn(
                        label: const Text('CE OI'),
                        onSort: (columnIndex, ascending) {
                          _sort('ceOI', ascending);
                        },
                      ),
                      DataColumn(
                        label: const Text('CE Change'),
                        onSort: (columnIndex, ascending) {
                          _sort('ceChange', ascending);
                        },
                      ),
                      DataColumn(
                        label: const Text('CE LTP'),
                        onSort: (columnIndex, ascending) {
                          _sort('ceLTP', ascending);
                        },
                      ),
                      DataColumn(
                        label: const Text('Strike', style: TextStyle(fontWeight: FontWeight.bold)),
                        onSort: (columnIndex, ascending) {
                          _sort('strikePrice', ascending);
                        },
                      ),
                      DataColumn(
                        label: const Text('PE LTP'),
                        onSort: (columnIndex, ascending) {
                          _sort('peLTP', ascending);
                        },
                      ),
                      DataColumn(
                        label: const Text('PE Change'),
                        onSort: (columnIndex, ascending) {
                          _sort('peChange', ascending);
                        },
                      ),
                      DataColumn(
                        label: const Text('PE OI'),
                        onSort: (columnIndex, ascending) {
                          _sort('peOI', ascending);
                        },
                      ),
                    ],
                    rows: sortedData.map((item) => _buildDataRow(item)).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<DataItem> _getSortedData() {
    final data = List<DataItem>.from(widget.data);

    data.sort((a, b) {
      final aValue = _getSortValue(a, _sortColumn);
      final bValue = _getSortValue(b, _sortColumn);

      if (aValue == null && bValue == null) return 0;
      if (aValue == null) return _sortAscending ? -1 : 1;
      if (bValue == null) return _sortAscending ? 1 : -1;

      final comparison = aValue.compareTo(bValue);
      return _sortAscending ? comparison : -comparison;
    });

    return data;
  }

  Comparable? _getSortValue(DataItem item, String column) {
    switch (column) {
      case 'strikePrice':
        return item.strikePrice;
      case 'ceOI':
        return item.ce?.openInterest;
      case 'ceChange':
        return item.ce?.changeinOpenInterest;
      case 'ceLTP':
        return item.ce?.lastPrice;
      case 'peOI':
        return item.pe?.openInterest;
      case 'peChange':
        return item.pe?.changeinOpenInterest;
      case 'peLTP':
        return item.pe?.lastPrice;
      default:
        return null;
    }
  }

  int _getColumnIndex(String column) {
    const columns = ['ceOI', 'ceChange', 'ceLTP', 'strikePrice', 'peLTP', 'peChange', 'peOI'];
    return columns.indexOf(column);
  }

  void _sort(String column, bool ascending) {
    setState(() {
      _sortColumn = column;
      _sortAscending = ascending;
    });
  }

  DataRow _buildDataRow(DataItem item) {
    final isAtm = _isAtTheMoney(item.strikePrice);
    final rowColor = isAtm
      ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
      : null;

    return DataRow(
      color: WidgetStateProperty.all(rowColor),
      cells: [
        DataCell(_buildOICell(item.ce?.openInterest, Colors.green)),
        DataCell(_buildChangeCell(item.ce?.changeinOpenInterest, Colors.green)),
        DataCell(_buildPriceCell(item.ce?.lastPrice)),
        DataCell(_buildStrikeCell(item.strikePrice, isAtm)),
        DataCell(_buildPriceCell(item.pe?.lastPrice)),
        DataCell(_buildChangeCell(item.pe?.changeinOpenInterest, Colors.blue)),
        DataCell(_buildOICell(item.pe?.openInterest, Colors.blue)),
      ],
    );
  }

  Widget _buildOICell(int? value, Color color) {
    if (value == null) return const Text('-');

    return Text(
      _formatLargeNumber(value.toDouble()),
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildChangeCell(double? value, Color baseColor) {
    if (value == null) return const Text('-');

    final color = value >= 0
      ? baseColor
      : Colors.red;

    return Text(
      '${value >= 0 ? '+' : ''}${_formatLargeNumber(value)}',
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildPriceCell(double? value) {
    if (value == null) return const Text('-');

    return Text(
      value.toStringAsFixed(2),
      style: const TextStyle(fontWeight: FontWeight.w500),
    );
  }

  Widget _buildStrikeCell(double? value, bool isAtm) {
    if (value == null) return const Text('-');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: isAtm ? BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 1,
        ),
      ) : null,
      child: Text(
        value.toStringAsFixed(0),
        style: TextStyle(
          fontWeight: isAtm ? FontWeight.bold : FontWeight.w500,
          color: isAtm ? Theme.of(context).colorScheme.primary : null,
        ),
      ),
    );
  }

  bool _isAtTheMoney(double? strikePrice) {
    if (strikePrice == null || widget.underlyingPrice == null) return false;

    return (strikePrice - widget.underlyingPrice!).abs() <= 50; // Within 50 points
  }

  String _formatLargeNumber(double value) {
    if (value.abs() >= 10000000) {
      return '${(value / 10000000).toStringAsFixed(1)}Cr';
    } else if (value.abs() >= 100000) {
      return '${(value / 100000).toStringAsFixed(1)}L';
    } else if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }
}