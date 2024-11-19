import 'package:flutter/foundation.dart';
import '../models/item.dart';
import '../models/warehouse.dart';
import '../models/stock_entry.dart';
import '../services/api_service.dart';

class StockProvider with ChangeNotifier {
  final ApiService _apiService;
  List<Item> _items = [];
  List<Warehouse> _warehouses = [];
  Map<String, Map<String, double>> _binStock = {};

  StockProvider(this._apiService);

  List<Item> get items => _items;
  List<Warehouse> get warehouses => _warehouses;

  Future<void> loadItems() async {
    try {
      _items = await _apiService.getItems();
      notifyListeners();
    } catch (e) {
      print('Error loading items: $e');
      rethrow;
    }
  }

  Future<void> loadWarehouses() async {
    try {
      _warehouses = await _apiService.getWarehouses();
      notifyListeners();
    } catch (e) {
      print('Error loading warehouses: $e');
      rethrow;
    }
  }

  Future<double> getBinStock(String item, String warehouse) async {
    try {
      if (_binStock[item]?[warehouse] != null) {
        return _binStock[item]![warehouse]!;
      }

      final stock = await _apiService.getBinStock(item, warehouse);
      _binStock[item] = {..._binStock[item] ?? {}, warehouse: stock};
      notifyListeners();
      return stock;
    } catch (e) {
      print('Error getting bin stock: $e');
      rethrow;
    }
  }

  Future<String> createStockEntry(StockEntry stockEntry) async {
    try {
      final result = await _apiService.createStockEntry(stockEntry);
      // Refresh bin stock after stock entry
      for (var item in stockEntry.items) {
        if (stockEntry.fromWarehouse.isNotEmpty) {
          await getBinStock(item.item, stockEntry.fromWarehouse);
        }
        if (stockEntry.toWarehouse.isNotEmpty) {
          await getBinStock(item.item, stockEntry.toWarehouse);
        }
      }
      return result;
    } catch (e) {
      print('Error creating stock entry: $e');
      rethrow;
    }
  }
}
