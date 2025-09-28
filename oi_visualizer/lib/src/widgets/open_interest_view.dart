import 'dart:developer';

import 'package:flutter/material.dart';
import '../models/transformed_data.dart';
import '../models/data_item.dart';
import 'oi_chart.dart';
import 'data_table_view.dart';

class OpenInterestView extends StatefulWidget {
  final String underlying;
  final TransformedData data;

  const OpenInterestView({
    super.key,
    required this.underlying,
    required this.data,
  });

  @override
  State<OpenInterestView> createState() => _OpenInterestViewState();
}

class _OpenInterestViewState extends State<OpenInterestView>
    with SingleTickerProviderStateMixin {
  TransformedData? _data;
  bool _isLoading = false;
  String? _error;
  List<String> _selectedExpiries = [];
  TabController? _tabController;
  int _currentViewIndex = 0;
  final List<String> _viewTabs = ['Charts', 'Table'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _viewTabs.length, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(OpenInterestView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.underlying != widget.underlying) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = widget.data;
      setState(() {
        _data = data;
        _selectedExpiries = (data.filteredExpiries ?? []).take(1).toList();
        _isLoading = false;
      });
    } catch (e,s) {
      log("OpenInterestView | Error in data parsing | $e\n$s");
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildBody();
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Error: $_error',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_data == null) {
      return const Center(child: Text('No data available'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 768;
        final isMobile = constraints.maxWidth < 480;

        if (isLargeScreen) {
          // Desktop/Tablet layout
          return Row(
            children: [
              SizedBox(
                width: isMobile ? 250 : 300,
                child: _buildMenu(),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: _buildContent(),
              ),
            ],
          );
        } else {
          // Mobile layout with floating menu
          return Stack(
            children: [
              _buildContent(),
              Positioned(
                top: 8,
                right: 8,
                child: FloatingActionButton.small(
                  onPressed: () => _showMobileMenu(context),
                  child: const Icon(Icons.menu),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildMenu() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildMenuContent(),
      ),
    );
  }

  Widget _buildMenuContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Text(
          'View',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...List.generate(_viewTabs.length, (index) {
          return RadioListTile<int>(
            dense: true,
            title: Text(_viewTabs[index]),
            value: index,
            groupValue: _currentViewIndex,
            onChanged: (value) {
              setState(() {
                _currentViewIndex = value!;
              });
              // Close mobile menu after selection
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          );
        }),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        Text(
          'Expiries',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...(_data?.filteredExpiries ?? []).map((expiry) {
          return CheckboxListTile(
            dense: true,
            title: Text(expiry),
            value: _selectedExpiries.contains(expiry),
            onChanged: (selected) {
              setState(() {
                _selectedExpiries.clear();
                _selectedExpiries.insert(0, expiry);
              });
              // Close mobile menu after selection
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          );
        }),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Underlying: ${_data?.underlying ?? 'N/A'}\nPrice: ₹${(_data?.underlyingValue ?? 0.0).toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showMobileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: _buildMenuContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final selectedData = <DataItem>[];

    for (final expiry in _selectedExpiries) {
      final groupData = _data?.grouped?[expiry];
      if (groupData?.data != null) {
        selectedData.addAll(groupData!.data!);
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 480;
        final padding = isMobile ? 8.0 : 16.0;

        return Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            children: [
              if (!isMobile) ...[
                Card(
                  child: TabBar(
                    controller: _tabController,
                    tabs: _viewTabs.map((tab) => Tab(text: tab)).toList(),
                    onTap: (index) {
                      setState(() {
                        _currentViewIndex = index;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Expanded(
                child: _currentViewIndex == 0 ? _buildCharts(selectedData, padding, isMobile) : _buildTable(selectedData),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCharts(List<DataItem> selectedData, double padding, bool isMobile) {
    return Column(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'OI Change',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Refresh Data',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: OIChart(
                      data: selectedData,
                      type: OIChartType.change,
                      underlyingPrice: _data?.underlyingValue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: isMobile ? 8 : 16),
        Expanded(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'OI Total',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: OIChart(
                      data: selectedData,
                      type: OIChartType.total,
                      underlyingPrice: _data?.underlyingValue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTable(List<DataItem> selectedData) {
    return DataTableView(
      data: selectedData,
      underlyingPrice: _data?.underlyingValue,
    );
  }
}