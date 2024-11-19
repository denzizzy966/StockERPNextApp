import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stock_provider.dart';
import '../models/item.dart';
import '../models/warehouse.dart';

class StockStatusScreen extends StatefulWidget {
  const StockStatusScreen({Key? key}) : super(key: key);

  @override
  State<StockStatusScreen> createState() => _StockStatusScreenState();
}

class _StockStatusScreenState extends State<StockStatusScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final provider = Provider.of<StockProvider>(context, listen: false);
      provider.loadItems();
      provider.loadWarehouses();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Status'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final provider = Provider.of<StockProvider>(context, listen: false);
              provider.loadItems();
              provider.loadWarehouses();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshing data...')),
              );
            },
          ),
        ],
      ),
      body: Consumer<StockProvider>(
        builder: (context, stockProvider, child) {
          if (stockProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${stockProvider.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      stockProvider.loadItems();
                      stockProvider.loadWarehouses();
                    },
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (stockProvider.isLoading && stockProvider.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Consumer<StockProvider>(
                          builder: (context, stockProvider, child) {
                            return DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Filter by Warehouse',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              dropdownColor: Colors.white,
                              value: stockProvider.selectedWarehouse,
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('All Warehouses', 
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                                ...stockProvider.warehouses
                                    .map((warehouse) => DropdownMenuItem(
                                          value: warehouse.name,
                                          child: Text(
                                            warehouse.name ?? 'Unknown',
                                            style: const TextStyle(color: Colors.black),
                                          ),
                                        ))
                                    .toList(),
                              ],
                              onChanged: (value) {
                                stockProvider.setSelectedWarehouse(value);
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            labelText: 'Search by Item Code/Name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (value) {
                            Provider.of<StockProvider>(context, listen: false)
                                .setSearchQuery(value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Consumer<StockProvider>(
                  builder: (context, stockProvider, child) {
                    final items = stockProvider.items;
                    final warehouses = stockProvider.warehouses;
                    final selectedWarehouse = stockProvider.selectedWarehouse;

                    return ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return ExpansionTile(
                          title: Text(item.itemName ?? item.itemCode ?? 'Unknown Item'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Item Code: ${item.itemCode ?? 'N/A'}'),
                              Text('UOM: ${item.stockUom ?? 'N/A'}'),
                            ],
                          ),
                          children: warehouses
                              .where((warehouse) =>
                                  selectedWarehouse == null ||
                                  warehouse.name == selectedWarehouse)
                              .map((warehouse) {
                            return FutureBuilder<double>(
                              future: stockProvider.getBinStock(
                                item.itemCode ?? '',
                                warehouse.name ?? '',
                              ),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const ListTile(
                                    title: LinearProgressIndicator(),
                                  );
                                }

                                final stock = snapshot.data ?? 0.0;
                                return ListTile(
                                  title: Text(warehouse.name ?? 'Unknown Warehouse'),
                                  trailing: Text(
                                    'Stock: ${stock.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: stock > 0 ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
