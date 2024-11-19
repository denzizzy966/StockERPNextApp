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
    Future.microtask(() {
      final provider = Provider.of<StockProvider>(context, listen: false);
      provider.loadItems();
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
        title: const Text('Items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final provider = Provider.of<StockProvider>(context, listen: false);
              provider.loadItems();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshing items...')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Items',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                Provider.of<StockProvider>(context, listen: false)
                    .setSearchQuery(value);
              },
            ),
          ),
          Expanded(
            child: Consumer<StockProvider>(
              builder: (context, stockProvider, child) {
                if (stockProvider.isLoading && stockProvider.items.isEmpty) {
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
                          onPressed: () {
                            stockProvider.loadItems();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final items = stockProvider.items;
                if (items.isEmpty) {
                  return const Center(child: Text('No items found'));
                }

                return RefreshIndicator(
                  onRefresh: () => stockProvider.loadItems(),
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: ListTile(
                          title: Text(item.itemName ?? 'Unknown Item'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Item Code: ${item.itemCode ?? 'N/A'}'),
                              Text('UOM: ${item.stockUom ?? 'N/A'}'),
                              if (item.description?.isNotEmpty ?? false)
                                Text('Description: ${item.description}'),
                            ],
                          ),
                          trailing: FutureBuilder<double>(
                            future: stockProvider.getBinStock(
                              item.itemCode ?? '',
                              stockProvider.selectedWarehouse ?? '',
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                );
                              }
                              final stock = snapshot.data ?? 0.0;
                              return Text(
                                'Stock: ${stock.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: stock > 0 ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
