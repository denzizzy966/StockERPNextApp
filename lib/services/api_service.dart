import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:logging/logging.dart';
import '../models/item.dart';
import '../models/warehouse.dart';
import '../models/stock_entry.dart';
import '../config/config.dart';

class ApiService {
  late final Dio _dio;
  final String baseUrl;
  final String apiKey;
  final String apiSecret;
  final _logger = Logger('ApiService');

  ApiService({
    String? baseUrl,
    String? apiKey,
    String? apiSecret,
  })  : baseUrl = baseUrl ?? Config.baseUrl,
        apiKey = apiKey ?? Config.apiKey,
        apiSecret = apiSecret ?? Config.apiSecret {
    _dio = Dio(BaseOptions(
      baseUrl: this.baseUrl,
      headers: _headers,
      validateStatus: (status) {
        return status! < 500;
      },
    ));
    
    // Add logging interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        _logger.info('Making request to: ${options.path}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        _logger.info('Received response from: ${response.requestOptions.path} with status: ${response.statusCode}');
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        _logger.severe('Error in request to ${e.requestOptions.path}: ${e.message}');
        return handler.next(e);
      },
    ));
  }

  Map<String, String> get _headers => {
        'Authorization': 'token $apiKey:$apiSecret',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Future<List<Item>> getItems() async {
    try {
      final response = await _dio.get(
        '/api/resource/Item',
        queryParameters: {
          'fields': '["*"]',
          'limit_page_length': 'None',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['data'] != null) {
          final items = (data['data'] as List).map((item) => Item.fromJson(item)).toList();
          
          // Get stock quantities for each item in parallel
          await Future.wait(
            items.map((item) async {
              if (item.itemCode != null && item.defaultWarehouse != null) {
                try {
                  final stock = await getBinStock(item.itemCode!, item.defaultWarehouse!);
                  final reorderLevel = await getReorderLevel(item.itemCode!);
                  final index = items.indexOf(item);
                  items[index] = Item(
                    itemCode: item.itemCode,
                    itemName: item.itemName,
                    description: item.description,
                    stockUom: item.stockUom,
                    defaultWarehouse: item.defaultWarehouse,
                    totalQty: stock,
                    reorderLevel: reorderLevel,
                  );
                } catch (e) {
                  _logger.warning('Error getting stock for item ${item.itemCode}: $e');
                }
              }
            })
          );
          return items;
        }
        return [];
      } else {
        _logger.warning('Failed to load items with status code: ${response.statusCode}');
        _logger.warning('Response data: ${response.data}');
        throw Exception('Failed to load items: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.severe('DioException loading items: ${e.message}');
      _logger.severe('Request: ${e.requestOptions.uri}');
      _logger.severe('Response: ${e.response?.data}');
      throw Exception('Network error loading items: ${e.message}');
    } catch (e) {
      _logger.severe('Error loading items: $e');
      throw Exception('Error loading items: $e');
    }
  }

  Future<double> getReorderLevel(String itemCode) async {
    try {
      final response = await _dio.get('/api/resource/Item/$itemCode');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        return (data['reorder_level'] ?? 0.0).toDouble();
      }
      return 0.0;
    } on DioException catch (e) {
      _logger.warning('Error getting reorder level for $itemCode: ${e.message}');
      return 0.0;
    } catch (e) {
      _logger.warning('Error getting reorder level for $itemCode: $e');
      return 0.0;
    }
  }

  Future<double> getBinStock(String item, String warehouse) async {
    try {
      if (warehouse.isEmpty) {
        _logger.warning('No warehouse specified for item: $item');
        return 0.0;
      }

      // Step 1: Get the bin name
      final binListResponse = await _dio.get(
        '/api/resource/Bin',
        queryParameters: {
          'filters': '[["item_code","=","$item"],["warehouse","=","$warehouse"]]',
          'fields': '["name", "actual_qty"]',
        },
      );

      if (binListResponse.statusCode == 200 && 
          binListResponse.data != null && 
          binListResponse.data['data'] is List && 
          binListResponse.data['data'].isNotEmpty) {
        
        final binData = binListResponse.data['data'][0];
        // If we have actual_qty in the first response, use it directly
        if (binData.containsKey('actual_qty')) {
          return (binData['actual_qty'] ?? 0.0).toDouble();
        }
        
        final binName = binData['name'];
        // Step 2: Get the bin details only if needed
        final binDetailResponse = await _dio.get('/api/resource/Bin/$binName');

        if (binDetailResponse.statusCode == 200 && 
            binDetailResponse.data != null && 
            binDetailResponse.data['data'] != null) {
          
          final detailData = binDetailResponse.data['data'];
          return (detailData['actual_qty'] ?? 0.0).toDouble();
        }
      }
      
      return 0.0;
    } on DioException catch (e) {
      _logger.warning('Network error getting bin stock for $item: ${e.message}');
      return 0.0;
    } catch (e) {
      _logger.warning('Error getting bin stock for $item: $e');
      return 0.0;
    }
  }

  Future<List<StockEntry>> getStockEntries({
    String? warehouse,
    String? type,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final List<List<dynamic>> filters = [];
      
      if (warehouse != null && warehouse.isNotEmpty) {
        filters.add(['to_warehouse', '=', warehouse]);
      }
      if (type != null && type.isNotEmpty) {
        filters.add(['stock_entry_type', '=', type]);
      }
      if (status != null) {
        filters.add(['docstatus', '=', status]);
      }
      if (startDate != null) {
        filters.add(['posting_date', '>=', startDate.toIso8601String().split('T')[0]]);
      }
      if (endDate != null) {
        filters.add(['posting_date', '<=', endDate.toIso8601String().split('T')[0]]);
      }

      // First get the list of stock entries
      final response = await _dio.get(
        '/api/resource/Stock Entry',
        queryParameters: {
          'fields': '["name", "stock_entry_type", "posting_date", "docstatus"]',
          if (filters.isNotEmpty) 'filters': jsonEncode(filters),
          'limit_page_length': 'None',
          'order_by': 'modified desc',
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<StockEntry> entries = [];
        final stockEntries = response.data['data'] as List;
        
        // Get details for each stock entry in parallel
        await Future.wait(
          stockEntries.map((entry) async {
            try {
              final detailResponse = await _dio.get('/api/resource/Stock Entry/${entry['name']}');
              if (detailResponse.statusCode == 200 && detailResponse.data != null) {
                entries.add(StockEntry.fromJson(detailResponse.data['data']));
              }
            } catch (e) {
              _logger.warning('Error fetching details for stock entry ${entry['name']}: $e');
            }
          })
        );
        
        return entries;
      }
      return [];
    } on DioException catch (e) {
      _logger.severe('Network error getting stock entries: ${e.message}');
      throw Exception('Failed to load stock entries: ${e.message}');
    } catch (e) {
      _logger.severe('Error getting stock entries: $e');
      throw Exception('Failed to load stock entries: $e');
    }
  }

  Future<List<Warehouse>> getWarehouses() async {
    try {
      final response = await _dio.get(
        '/api/resource/Warehouse',
        queryParameters: {
          'fields': '["*"]',
          'limit_page_length': 'None',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return (data['data'] as List)
            .map((warehouse) => Warehouse.fromJson(warehouse))
            .toList();
      } else {
        throw Exception('Failed to load warehouses: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.severe('Network error loading warehouses: ${e.message}');
      throw Exception('Failed to load warehouses: ${e.message}');
    } catch (e) {
      _logger.severe('Error loading warehouses: $e');
      throw Exception('Failed to load warehouses: $e');
    }
  }

  Future<String> createStockEntry(StockEntry stockEntry) async {
    try {
      final response = await _dio.post(
        '/api/resource/Stock Entry',
        data: stockEntry.toJson(),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['data'] != null) {
          final docName = data['data']['name'];
          _logger.info('Successfully created stock entry: $docName');
          return docName;
        }
        throw Exception('Invalid response data: ${response.data}');
      } else {
        _logger.severe('Failed to create stock entry: ${response.statusCode}\nResponse: ${response.data}');
        throw Exception('Failed to create stock entry: ${response.data}');
      }
    } catch (e) {
      _logger.severe('Error creating stock entry: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchReorderLevels() async {
    try {
      final response = await _dio.get(
        '$baseUrl/api/resource/Item Reorder',
        queryParameters: {
          'fields': '["item_code", "warehouse", "warehouse_reorder_level"]',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to fetch reorder levels');
      }
    } catch (e) {
      _logger.severe('Error fetching reorder levels', e);
      throw Exception('Failed to fetch reorder levels: $e');
    }
  }

  Future<Map<String, dynamic>?> getItemDetails(String itemCode) async {
    try {
      final response = await _dio.get(
        '/api/resource/Item/$itemCode',
        queryParameters: {
          'fields': '["name", "item_code", "item_name", "description", "stock_uom", "reorder_levels"]',
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      _logger.severe('Error getting item details: $e');
      return null;
    }
  }

  Future<List<Item>> fetchItems() async {
    try {
      final response = await _dio.get(
        '$baseUrl/api/resource/Item',
        queryParameters: {
          'fields': '["name", "item_code", "item_name", "description", "stock_uom"]',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => Item.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch items');
      }
    } catch (e) {
      _logger.severe('Error fetching items', e);
      throw Exception('Failed to fetch items: $e');
    }
  }

  Future<List<Warehouse>> fetchWarehouses() async {
    try {
      final response = await _dio.get(
        '$baseUrl/api/resource/Warehouse',
        queryParameters: {
          'fields': '["name", "warehouse_name"]',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => Warehouse.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch warehouses');
      }
    } catch (e) {
      _logger.severe('Error fetching warehouses', e);
      throw Exception('Failed to fetch warehouses: $e');
    }
  }
}
