import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stock_provider.dart';
import 'stock_entry_screen.dart';

class StockEntryListScreen extends StatefulWidget {
  const StockEntryListScreen({Key? key}) : super(key: key);

  @override
  State<StockEntryListScreen> createState() => _StockEntryListScreenState();
}

class _StockEntryListScreenState extends State<StockEntryListScreen> {
  Future<void> _refreshEntries() async {
    await Provider.of<StockProvider>(context, listen: false).loadStockEntries();
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StockEntryScreen(
                        stockEntryType: 'Material Issue',
                      ),
                    ),
                  ).then((_) => _refreshEntries());
                },
              ),
              ListTile(
                title: const Text('Material Receipt'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StockEntryScreen(
                        stockEntryType: 'Material Receipt',
                      ),
                    ),
                  ).then((_) => _refreshEntries());
                },
              ),
              ListTile(
                title: const Text('Material Transfer'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StockEntryScreen(
                        stockEntryType: 'Material Transfer',
                      ),
                    ),
                  ).then((_) => _refreshEntries());
                },
              ),
            ],
          ),
        );
      },
    );
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
    Future.microtask(() => _refreshEntries());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Entries'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddEntryDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshEntries,
          ),
        ],
      ),
      body: Consumer<StockProvider>(
        builder: (context, stockProvider, child) {
          if (stockProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (stockProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${stockProvider.error}',
                    textAlign: TextAlign.center,
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

          final entries = stockProvider.stockEntries;
          if (entries.isEmpty) {
            return const Center(
              child: Text('No stock entries found'),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshEntries,
            child: ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final docstatus = entry['docstatus'] as int? ?? 0;
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(entry['name'] ?? 'Unknown'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Type: ${entry['stock_entry_type'] ?? 'N/A'}'),
                        Text('Date: ${entry['posting_date'] ?? 'N/A'}'),
                        Text('Modified: ${entry['modified'] ?? 'N/A'}'),
                        Text('Owner: ${entry['owner'] ?? 'N/A'}'),
                      ],
                    ),
                    trailing: Chip(
                      label: Text(
                        _getStatusText(docstatus),
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: _getStatusColor(docstatus),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
