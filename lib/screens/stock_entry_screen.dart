import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stock_provider.dart';
import '../models/stock_entry.dart';
import '../models/item.dart';
import '../models/warehouse.dart';

class StockEntryScreen extends StatefulWidget {
  final String stockEntryType;

  const StockEntryScreen({
    super.key,
    required this.stockEntryType,
  });

  @override
  State<StockEntryScreen> createState() => _StockEntryScreenState();
}

class _StockEntryScreenState extends State<StockEntryScreen> {
  final List<StockEntryItem> _items = [];
  String? _fromWarehouse;
  String? _toWarehouse;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.stockEntryType),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.stockEntryType != 'Material Receipt')
                    _buildWarehouseDropdown(
                      label: 'From Warehouse',
                      value: _fromWarehouse,
                      onChanged: (value) {
                        setState(() => _fromWarehouse = value);
                      },
                    ),
                  if (widget.stockEntryType != 'Material Issue')
                    _buildWarehouseDropdown(
                      label: 'To Warehouse',
                      value: _toWarehouse,
                      onChanged: (value) {
                        setState(() => _toWarehouse = value);
                      },
                    ),
                  const SizedBox(height: 16),
                  ..._items.asMap().entries.map(
                        (entry) => _buildItemCard(entry.key),
                      ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Item'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _items.isEmpty ? null : _submitStockEntry,
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildWarehouseDropdown({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    final warehouses = Provider.of<StockProvider>(context).warehouses;
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      value: value,
      items: warehouses
          .map(
            (w) => DropdownMenuItem(
              value: w.name,
              child: Text(w.warehouseName),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildItemCard(int index) {
    final items = Provider.of<StockProvider>(context).items;
    final item = _items[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Item',
                      border: OutlineInputBorder(),
                    ),
                    value: item.item,
                    items: items
                        .map(
                          (i) => DropdownMenuItem(
                            value: i.itemCode,
                            child: Text(i.itemName),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _items[index] = StockEntryItem(
                            item: value,
                            qty: item.qty,
                            uom: items
                                .firstWhere((i) => i.itemCode == value)
                                .uom,
                            fromWarehouse: item.fromWarehouse,
                            toWarehouse: item.toWarehouse,
                          );
                        });
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() => _items.removeAt(index));
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              initialValue: item.qty.toString(),
              onChanged: (value) {
                setState(() {
                  _items[index] = StockEntryItem(
                    item: item.item,
                    qty: double.tryParse(value) ?? 0,
                    uom: item.uom,
                    fromWarehouse: item.fromWarehouse,
                    toWarehouse: item.toWarehouse,
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addItem() {
    final items = Provider.of<StockProvider>(context, listen: false).items;
    if (items.isEmpty) return;

    setState(() {
      _items.add(
        StockEntryItem(
          item: items.first.itemCode,
          qty: 0,
          uom: items.first.uom,
          fromWarehouse: _fromWarehouse ?? '',
          toWarehouse: _toWarehouse ?? '',
        ),
      );
    });
  }

  Future<void> _submitStockEntry() async {
    if (_items.isEmpty) return;

    final stockEntry = StockEntry(
      name: '',
      stockEntryType: widget.stockEntryType,
      postingDate: DateTime.now().toIso8601String().split('T').first,
      fromWarehouse: _fromWarehouse ?? '',
      toWarehouse: _toWarehouse ?? '',
      items: _items,
    );

    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<StockProvider>(context, listen: false);
      await provider.createStockEntry(stockEntry);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock entry created successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
