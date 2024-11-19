import 'package:flutter/foundation.dart';
import '../models/warehouse.dart';
import '../models/item.dart';
import '../models/stock_entry.dart';
import '../services/api_service.dart';
import 'package:logging/logging.dart';

class StockProvider with ChangeNotifier {
  final ApiService _apiService;
  final Logger _logger = Logger('StockProvider');
  
  List<Item> _items = [];
  List<Warehouse> _warehouses = [];
  final List<StockEntry> _stockEntries = [];
  String? _selectedWarehouse;
  String _searchQuery = '';
  bool _showLowStock = false;
  bool _isLoading = false;
  String? _error;
  String? _selectedStockEntryType;
  String? _selectedStockEntryStatus;
  DateTime? _startDate;
  DateTime? _endDate;
  final Map<String, Map<String, double>> _binStock = {};
  final Map<String, Map<String, double>> _reorderLevels = {};

  StockProvider(this._apiService);

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Item> get items => _showLowStock ? _items.where((item) => _isLowStock(item)).toList() : _items;
  List<Item> get filteredItems => _searchQuery.isEmpty 
      ? items 
      : items.where((item) => 
          (item.itemName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (item.itemCode?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
        ).toList();
  List<Warehouse> get warehouses => _warehouses;
  String? get selectedWarehouse => _selectedWarehouse;
  List<StockEntry> get stockEntries => _stockEntries;
  String? get selectedStockEntryType => _selectedStockEntryType;
  String? get selectedStockEntryStatus => _selectedStockEntryStatus;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  void setSelectedWarehouse(String warehouse) {
    _selectedWarehouse = warehouse;
    loadWarehouseStock(warehouse);
    loadReorderLevels();
    notifyListeners();
  }

  void setStockEntryFilters({
    String? type,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    _selectedStockEntryType = type;
    _selectedStockEntryStatus = status;
    _startDate = startDate;
    _endDate = endDate;
    loadStockEntries();
    notifyListeners();
  }

  void filterItems(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _apiService.getItems();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load items: $e';
      _logger.severe('Error loading items', e);
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
      final entries = await _apiService.getStockEntries(
        warehouse: _selectedWarehouse,
        type: _selectedStockEntryType,
        status: _selectedStockEntryStatus,
        startDate: _startDate,
        endDate: _endDate,
      );
      _stockEntries.clear();
      _stockEntries.addAll(entries);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load stock entries: $e';
      _logger.severe('Error loading stock entries', e);
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
      _warehouses = await _apiService.getWarehouses();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load warehouses: $e';
      _logger.severe('Error loading warehouses', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadWarehouseStock(String warehouse) async {
    try {
      for (var item in _items) {
        if (item.itemCode == null) continue;
        final String itemCode = item.itemCode!;
        
        final stock = await _apiService.getBinStock(itemCode, warehouse);
        if (_binStock[itemCode] == null) {
          _binStock[itemCode] = {};
        }
        _binStock[itemCode]![warehouse] = stock;
      }
      notifyListeners();
    } catch (e) {
      _logger.severe('Error loading warehouse stock', e);
    }
  }

  Future<double> getBinStock(String itemCode, String warehouse) async {
    try {
      if (!_binStock.containsKey(itemCode) || !_binStock[itemCode]!.containsKey(warehouse)) {
        final stock = await _apiService.getBinStock(itemCode, warehouse);
        if (_binStock[itemCode] == null) {
          _binStock[itemCode] = {};
        }
        _binStock[itemCode]![warehouse] = stock;
      }
      return _binStock[itemCode]?[warehouse] ?? 0.0;
    } catch (e) {
      _logger.severe('Error getting bin stock', e);
      return 0.0;
    }
  }

  Future<void> loadReorderLevels() async {
    if (_selectedWarehouse == null) return;
    final String warehouse = _selectedWarehouse!;

    try {
      for (var item in _items) {
        if (item.itemCode == null) continue;
        final String itemCode = item.itemCode!;
        
        final response = await _apiService.getItemDetails(itemCode);
        if (response != null && response['reorder_levels'] != null) {
          final reorderLevels = response['reorder_levels'] as List;
          for (var level in reorderLevels) {
            if (level['warehouse'] == warehouse) {
              if (_reorderLevels[itemCode] == null) {
                _reorderLevels[itemCode] = {};
              }
              _reorderLevels[itemCode]![warehouse] = 
                  double.tryParse(level['warehouse_reorder_level'].toString()) ?? 0.0;
            }
          }
        }
      }
      notifyListeners();
    } catch (e) {
      _logger.severe('Error loading reorder levels', e);
    }
  }

  bool _isLowStock(Item item) {
    if (_selectedWarehouse == null || item.itemCode == null) return false;
    final String warehouse = _selectedWarehouse!;
    final String itemCode = item.itemCode!;
    
    final stockLevel = _binStock[itemCode]?[warehouse] ?? 0.0;
    final reorderLevel = _reorderLevels[itemCode]?[warehouse] ?? 0.0;
    
    return stockLevel <= reorderLevel;
  }

  void showLowStockItems() {
    _showLowStock = true;
    notifyListeners();
  }

  Future<void> createStockEntry(Map<String, dynamic> entryData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Create a StockEntry object using the fromJson factory constructor
      final stockEntry = StockEntry.fromJson(entryData);
      
      // Send the stock entry to the API
      await _apiService.createStockEntry(stockEntry);
      await loadStockEntries();
    } catch (e) {
      _error = 'Failed to create stock entry: $e';
      _logger.severe('Error creating stock entry', e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Warehouse>> getWarehousesWithStock() async {
    List<Warehouse> warehousesWithStock = [];
    for (var warehouse in _warehouses) {
      if (warehouse.name == null) continue;
      final String warehouseName = warehouse.name!;
      
      try {
        bool hasStock = false;
        for (var item in _items) {
          if (item.itemCode == null) continue;
          final stock = await _apiService.getBinStock(item.itemCode!, warehouseName);
          if (stock > 0) {
            hasStock = true;
            break;
          }
        }
        if (hasStock) {
          warehousesWithStock.add(warehouse);
        }
      } catch (e) {
        _logger.warning('Error checking stock for warehouse ${warehouse.name}', e);
      }
    }
    return warehousesWithStock;
  }
}
