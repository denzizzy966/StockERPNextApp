import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stock_provider.dart';

class ItemListScreen extends StatefulWidget {
  const ItemListScreen({Key? key}) : super(key: key);

  @override
  State<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final provider = Provider.of<StockProvider>(context, listen: false);
    await provider.loadItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildStockIndicator(double totalQty, double reorderLevel) {
    Color indicatorColor = Colors.green;
    if (totalQty <= reorderLevel) {
      indicatorColor = Colors.red;
    } else if (totalQty <= reorderLevel * 1.2) {
      indicatorColor = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: indicatorColor.withOpacity(0.1),
        border: Border.all(color: indicatorColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Stock: ${totalQty.toStringAsFixed(2)}',
        style: TextStyle(color: indicatorColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.warning_amber),
            onPressed: () {
              final provider = Provider.of<StockProvider>(context, listen: false);
              if (provider.selectedWarehouse == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select a warehouse first'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              // Show low stock items for selected warehouse
              provider.showLowStockItems();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Consumer<StockProvider>(
        builder: (context, stockProvider, child) {
          if (stockProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (stockProvider.error != null) {
            return Center(child: Text(stockProvider.error!));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Select Warehouse',
                    border: OutlineInputBorder(),
                  ),
                  value: stockProvider.selectedWarehouse,
                  items: stockProvider.warehouses.map((warehouse) {
                    return DropdownMenuItem(
                      value: warehouse.name,
                      child: Text(warehouse.name ?? 'Unknown Warehouse'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      stockProvider.setSelectedWarehouse(value);
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search Items',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    stockProvider.filterItems(value);
                  },
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: stockProvider.filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = stockProvider.filteredItems[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: ListTile(
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.itemName ?? 'Unknown Item',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            _buildStockIndicator(item.totalQty, item.reorderLevel),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Item Code: ${item.itemCode ?? 'N/A'}'),
                            if (item.description?.isNotEmpty ?? false)
                              Text('Description: ${item.description}'),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'UOM: ${item.stockUom ?? 'N/A'}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                                if (item.reorderLevel > 0)
                                  Text(
                                    'Reorder Level: ${item.reorderLevel.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                            if (item.defaultWarehouse != null)
                              Text(
                                'Default Warehouse: ${item.defaultWarehouse}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
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
