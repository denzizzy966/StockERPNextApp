import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stock_provider.dart';
import '../models/warehouse.dart';

class StockStatusScreen extends StatefulWidget {
  const StockStatusScreen({Key? key}) : super(key: key);

  @override
  State<StockStatusScreen> createState() => _StockStatusScreenState();
}

class _StockStatusScreenState extends State<StockStatusScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Warehouse> _warehousesWithStock = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final provider = Provider.of<StockProvider>(context, listen: false);
    await provider.loadItems();
    if (!mounted) return;
    await provider.loadWarehouses();
    if (!mounted) return;
    _warehousesWithStock = await provider.getWarehousesWithStock();
    setState(() {});
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    final provider = Provider.of<StockProvider>(context, listen: false);
    await provider.loadWarehouses();
    if (!mounted) return;
    _warehousesWithStock = await provider.getWarehousesWithStock();
    setState(() {});
  }

  Future<double> _getStock(String itemCode, String warehouse) async {
    if (!mounted) return 0.0;
    final provider = Provider.of<StockProvider>(context, listen: false);
    if (itemCode.isEmpty || warehouse.isEmpty) return 0.0;
    try {
      return await provider.getBinStock(itemCode, warehouse);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting stock: $e')),
        );
      }
      return 0.0;
    }
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
            onPressed: _refreshData,
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

          if (_warehousesWithStock.isEmpty) {
            return const Center(child: Text('No warehouses with stock found'));
          }

          final selectedWarehouse = stockProvider.selectedWarehouse;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButtonFormField<String>(
                  value: selectedWarehouse,
                  decoration: const InputDecoration(
                    labelText: 'Select Warehouse',
                    border: OutlineInputBorder(),
                  ),
                  items: _warehousesWithStock.map((warehouse) {
                    final name = warehouse.name;
                    if (name == null) return null;
                    return DropdownMenuItem(
                      value: name,
                      child: Text(warehouse.warehouseName ?? name),
                    );
                  }).whereType<DropdownMenuItem<String>>().toList(),
                  onChanged: (value) {
                    if (value != null) {
                      stockProvider.setSelectedWarehouse(value);
                    }
                  },
                ),
              ),
              Expanded(
                child: selectedWarehouse == null
                    ? const Center(child: Text('Please select a warehouse'))
                    : ListView.builder(
                        itemCount: stockProvider.items.length,
                        itemBuilder: (context, index) {
                          final item = stockProvider.items[index];
                          final itemCode = item.itemCode;
                          if (itemCode == null) return const SizedBox.shrink();

                          return FutureBuilder<double>(
                            future: _getStock(itemCode, selectedWarehouse),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const SizedBox(
                                  height: 0,
                                  width: 0,
                                );
                              }
                              
                              final stock = snapshot.data ?? 0.0;
                              if (stock == 0) return const SizedBox.shrink();
                              
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                  vertical: 4.0,
                                ),
                                child: ListTile(
                                  title: Text(item.itemName ?? 'Unknown Item'),
                                  subtitle: Text(itemCode),
                                  trailing: Text(
                                    'Stock: ${stock.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: stock > 0 ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
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
