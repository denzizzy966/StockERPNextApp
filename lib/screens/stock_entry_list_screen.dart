import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stock_provider.dart';
import '../models/stock_entry.dart';
import 'stock_entry_screen.dart';

class StockEntryListScreen extends StatefulWidget {
  const StockEntryListScreen({super.key});

  @override
  State<StockEntryListScreen> createState() => _StockEntryListScreenState();
}

class _StockEntryListScreenState extends State<StockEntryListScreen> {
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _refreshEntries() async {
    final provider = Provider.of<StockProvider>(context, listen: false);
    await provider.loadStockEntries();
  }

  void _showFilterDialog() {
    final provider = Provider.of<StockProvider>(context, listen: false);
    String? selectedType = provider.selectedStockEntryType;
    String? selectedStatus = provider.selectedStockEntryStatus;
    DateTime? startDate = provider.startDate;
    DateTime? endDate = provider.endDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Filter Stock Entries'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: 'Entry Type'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Types')),
                        const DropdownMenuItem(value: 'Material Issue', child: Text('Material Issue')),
                        const DropdownMenuItem(value: 'Material Receipt', child: Text('Material Receipt')),
                        const DropdownMenuItem(value: 'Material Transfer', child: Text('Material Transfer')),
                      ],
                      onChanged: (value) {
                        setState(() => selectedType = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Status')),
                        const DropdownMenuItem(value: '0', child: Text('Draft')),
                        const DropdownMenuItem(value: '1', child: Text('Submitted')),
                        const DropdownMenuItem(value: '2', child: Text('Cancelled')),
                      ],
                      onChanged: (value) {
                        setState(() => selectedStatus = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _startDateController..text = startDate?.toString().split(' ')[0] ?? '',
                      decoration: const InputDecoration(labelText: 'Start Date'),
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: startDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            startDate = date;
                            _startDateController.text = date.toString().split(' ')[0];
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _endDateController..text = endDate?.toString().split(' ')[0] ?? '',
                      decoration: const InputDecoration(labelText: 'End Date'),
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: endDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            endDate = date;
                            _endDateController.text = date.toString().split(' ')[0];
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    provider.setStockEntryFilters(
                      type: selectedType,
                      status: selectedStatus,
                      startDate: startDate,
                      endDate: endDate,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddEntryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Entry Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Material Issue'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToStockEntry('Material Issue');
                },
              ),
              ListTile(
                title: const Text('Material Receipt'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToStockEntry('Material Receipt');
                },
              ),
              ListTile(
                title: const Text('Material Transfer'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToStockEntry('Material Transfer');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToStockEntry(String stockEntryType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StockEntryScreen(
          stockEntryType: stockEntryType,
        ),
      ),
    ).then((_) => _refreshEntries());
  }

  String _getStatusText(int docstatus) {
    switch (docstatus) {
      case 0:
        return 'Draft';
      case 1:
        return 'Submitted';
      case 2:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  Color _getStatusColor(int docstatus) {
    switch (docstatus) {
      case 0:
        return Colors.orange;
      case 1:
        return Colors.green;
      case 2:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Entries'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshEntries,
          ),
        ],
      ),
      body: Consumer<StockProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${provider.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshEntries,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final entries = provider.stockEntries;
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No stock entries found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshEntries,
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshEntries,
            child: ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(entry.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Type: ${entry.stockEntryType}'),
                        Text('Date: ${entry.postingDate}'),
                        if (entry.fromWarehouse.isNotEmpty) Text('From: ${entry.fromWarehouse}'),
                        if (entry.toWarehouse.isNotEmpty) Text('To: ${entry.toWarehouse}'),
                        Text('Items: ${entry.items.length}'),
                        if (entry.modified != null) Text('Modified: ${entry.modified}'),
                        if (entry.owner != null) Text('Owner: ${entry.owner}'),
                      ],
                    ),
                    trailing: Chip(
                      label: Text(
                        _getStatusText(entry.docstatus),
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: _getStatusColor(entry.docstatus),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEntryDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
