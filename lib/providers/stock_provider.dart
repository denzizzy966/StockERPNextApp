import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:logging/logging.dart';
import '../models/item.dart';
import '../models/warehouse.dart';
import '../models/stock_entry.dart';
import '../services/api_service.dart';

class StockProvider with ChangeNotifier {
  final ApiService _apiService;
  final _logger = Logger('StockProvider');
  
  List<Item> _items = [];
  List<Warehouse> _warehouses = [];
  List<Map<String, dynamic>> _stockEntries = [];
  Map<String, Map<String, double>> _binStock = {};

  // Filter state
  String? _selectedWarehouse;
  String? _searchQuery;

  bool _isLoading = false;
  String? _error;

  StockProvider(this._apiService);

  List<Item> get items {
    if (_searchQuery?.isEmpty ?? true) {
      return _items;
    }
    return _items.where((item) =>
      (item.itemCode?.toLowerCase().contains(_searchQuery!.toLowerCase()) ?? false) ||
      (item.itemName?.toLowerCase().contains(_searchQuery!.toLowerCase()) ?? false)
    ).toList();
  }

  List<Warehouse> get warehouses => _warehouses;
  List<Map<String, dynamic>> get stockEntries => _stockEntries;
  String? get selectedWarehouse => _selectedWarehouse;
  String? get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setSelectedWarehouse(String? warehouse) {
    _selectedWarehouse = warehouse;
    notifyListeners();
  }

  void setSearchQuery(String? query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final items = await _apiService.getItems();
      _items = items;
      await _cacheItems();
      _logger.info('Successfully loaded ${items.length} items');
    } catch (e) {
      _error = 'Failed to load items: $e';
      _logger.severe(_error);
      // Try to load from cache
      await _loadCachedItems();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadWarehouses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final warehouses = await _apiService.getWarehouses();
      _warehouses = warehouses;
      await _cacheWarehouses();
      _logger.info('Successfully loaded ${warehouses.length} warehouses');
    } catch (e) {
      _error = 'Failed to load warehouses: $e';
      _logger.severe(_error);
      // Try to load from cache
      await _loadCachedWarehouses();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStockEntries() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final entries = await _apiService.getStockEntries();
      _stockEntries = entries;
      _logger.info('Successfully loaded ${entries.length} stock entries');
    } catch (e) {
      _error = 'Failed to load stock entries: $e';
      _logger.severe(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<double> getBinStock(String item, String warehouse) async {
    try {
      if (_binStock[item]?[warehouse] != null) {
        return _binStock[item]![warehouse]!;
      }

      final stock = await _apiService.getBinStock(item, warehouse);
      _binStock[item] = {..._binStock[item] ?? {}, warehouse: stock};
      
      // Cache bin stock
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_binstock', binStockToJson(_binStock));
      
      _logger.info('Successfully cached bin stock for $item in $warehouse');
      notifyListeners();
      return stock;
    } catch (e) {
      _logger.severe('Error getting bin stock: $e');
      // Try to load from cache
      final prefs = await SharedPreferences.getInstance();
      final cachedBinStock = prefs.getString('cached_binstock');
      if (cachedBinStock != null) {
        _binStock = binStockFromJson(cachedBinStock);
        return _binStock[item]?[warehouse] ?? 0.0;
      }
      rethrow;
    }
  }

  Future<String> createStockEntry(StockEntry stockEntry) async {
    try {
      final result = await _apiService.createStockEntry(stockEntry);
      // Clear cache after stock entry
      for (var item in stockEntry.items) {
        if (stockEntry.fromWarehouse.isNotEmpty) {
          await getBinStock(item.item, stockEntry.fromWarehouse);
        }
        if (stockEntry.toWarehouse.isNotEmpty) {
          await getBinStock(item.item, stockEntry.toWarehouse);
        }
      }
      _logger.info('Successfully created stock entry');
      return result;
    } catch (e) {
      _logger.severe('Error creating stock entry: $e');
      rethrow;
    }
  }

  Future<void> _cacheItems() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_items', itemsToJson(_items));
    _logger.info('Successfully cached ${_items.length} items');
  }

  Future<void> _loadCachedItems() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedItems = prefs.getString('cached_items');
    if (cachedItems != null) {
      _items = itemsFromJson(cachedItems);
      notifyListeners();
    }
  }

  Future<void> _cacheWarehouses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_warehouses', warehousesToJson(_warehouses));
    _logger.info('Successfully cached ${_warehouses.length} warehouses');
  }

  Future<void> _loadCachedWarehouses() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedWarehouses = prefs.getString('cached_warehouses');
    if (cachedWarehouses != null) {
      _warehouses = warehousesFromJson(cachedWarehouses);
      notifyListeners();
    }
  }

  // Helper methods for JSON conversion
  String itemsToJson(List<Item> items) => jsonEncode(items.map((e) => e.toJson()).toList());
  List<Item> itemsFromJson(String json) => 
      (jsonDecode(json) as List).map((e) => Item.fromJson(e)).toList();

  String warehousesToJson(List<Warehouse> warehouses) => 
      jsonEncode(warehouses.map((e) => e.toJson()).toList());
  List<Warehouse> warehousesFromJson(String json) =>
      (jsonDecode(json) as List).map((e) => Warehouse.fromJson(e)).toList();

  String binStockToJson(Map<String, Map<String, double>> binStock) =>
      jsonEncode(binStock);
  Map<String, Map<String, double>> binStockFromJson(String json) {
    final Map<String, dynamic> decoded = jsonDecode(json);
    return decoded.map((key, value) => MapEntry(
      key,
      (value as Map<String, dynamic>).map((k, v) => MapEntry(k, v.toDouble()))
    ));
  }
}
