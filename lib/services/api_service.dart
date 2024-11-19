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
  final _cacheOptions = CacheOptions(
    store: MemCacheStore(),
    policy: CachePolicy.refreshForceCache,
    hitCacheOnErrorExcept: [401, 403],
    maxStale: const Duration(days: 1),
    priority: CachePriority.normal,
  );
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
    ));
    _dio.interceptors.add(DioCacheInterceptor(options: _cacheOptions));
  }

  Map<String, String> get _headers => {
        'Authorization': 'token $apiKey:$apiSecret',
        'Content-Type': 'application/json',
      };

  Future<List<Item>> getItems() async {
    try {
      final response = await _dio.get(
        '/api/resource/Item',
        queryParameters: {
          'fields': '["name", "item_code", "item_name", "description", "stock_uom"]',
        },
        options: _cacheOptions.copyWith(
          policy: CachePolicy.refreshForceCache,
        ).toOptions(),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['data'] != null) {
          return (data['data'] as List)
              .map((item) => Item.fromJson(item))
              .toList();
        }
        return [];
      } else {
        throw Exception('Failed to load items: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error loading items: $e');
      rethrow;
    }
  }

  Future<List<Warehouse>> getWarehouses() async {
    try {
      final response = await _dio.get(
        '/api/resource/Warehouse',
        options: _cacheOptions.copyWith(
          policy: CachePolicy.refreshForceCache,
        ).toOptions(),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return (data['data'] as List)
            .map((warehouse) => Warehouse.fromJson(warehouse))
            .toList();
      } else {
        throw Exception('Failed to load warehouses: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load warehouses: $e');
    }
  }

  Future<double> getBinStock(String item, String warehouse) async {
    try {
      // Step 1: Get the bin name
      final binListResponse = await _dio.get(
        '/api/resource/Bin',
        queryParameters: {
          'filters': jsonEncode([
            ['item_code', '=', item],
            ['warehouse', '=', warehouse]
          ])
        },
        options: _cacheOptions.copyWith(
          policy: CachePolicy.refreshForceCache,
        ).toOptions(),
      );

      if (binListResponse.statusCode == 200 && 
          binListResponse.data != null && 
          binListResponse.data['data'] is List && 
          binListResponse.data['data'].isNotEmpty) {
        
        final binName = binListResponse.data['data'][0]['name'];
        
        // Step 2: Get the bin details using the bin name
        final binDetailResponse = await _dio.get(
          '/api/resource/Bin/$binName',
          options: _cacheOptions.copyWith(
            policy: CachePolicy.refreshForceCache,
          ).toOptions(),
        );

        if (binDetailResponse.statusCode == 200 && 
            binDetailResponse.data != null && 
            binDetailResponse.data['data'] != null) {
          
          final binData = binDetailResponse.data['data'];
          return (binData['actual_qty'] ?? 0.0).toDouble();
        }
      }
      
      _logger.info('No bin found for item: $item in warehouse: $warehouse');
      return 0.0;
    } catch (e) {
      _logger.severe('Error getting bin stock: $e');
      return 0.0;
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

  Future<List<Map<String, dynamic>>> getStockEntries() async {
    try {
      final response = await _dio.get(
        '/api/resource/Stock Entry',
        queryParameters: {
          'fields': '["name", "posting_date", "stock_entry_type", "docstatus", "modified", "owner"]',
          'order_by': 'modified desc',
          'limit': '50'
        },
        options: _cacheOptions.copyWith(
          policy: CachePolicy.refreshForceCache,
        ).toOptions(),
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> entries = response.data['data'] ?? [];
        return entries.map((entry) => entry as Map<String, dynamic>).toList();
      }
      
      _logger.warning('Failed to load stock entries: ${response.statusCode}');
      return [];
    } catch (e) {
      _logger.severe('Error loading stock entries: $e');
      return [];
    }
  }
}
