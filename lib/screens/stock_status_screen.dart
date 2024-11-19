import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stock_provider.dart';
import '../models/item.dart';
import '../models/warehouse.dart';

class StockStatusScreen extends StatefulWidget {
  const StockStatusScreen({super.key});

  @override
  State<StockStatusScreen> createState() => _StockStatusScreenState();
}

class _StockStatusScreenState extends State<StockStatusScreen> {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Status'),
      ),
      body: Consumer<StockProvider>(
        builder: (context, stockProvider, child) {
          final items = stockProvider.items;
          final warehouses = stockProvider.warehouses;

          if (items.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ExpansionTile(
                title: Text(item.itemName ?? item.itemCode ?? 'Unknown Item'),
                subtitle: Text(item.itemCode ?? ''),
                children: warehouses.map((warehouse) {
                  return FutureBuilder<double>(
                    future: stockProvider.getBinStock(
                      item.itemCode ?? '',
                      warehouse.name ?? '',
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const ListTile(
                          title: CircularProgressIndicator(),
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
    );
  }
}
