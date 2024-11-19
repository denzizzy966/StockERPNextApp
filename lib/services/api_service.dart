import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/item.dart';
import '../models/warehouse.dart';
import '../models/stock_entry.dart';
import '../config/config.dart';

class ApiService {
  final String baseUrl;
  final String apiKey;
  final String apiSecret;

  ApiService({
    String? baseUrl,
    String? apiKey,
    String? apiSecret,
  }) : baseUrl = baseUrl ?? Config.baseUrl,
       apiKey = apiKey ?? Config.apiKey,
       apiSecret = apiSecret ?? Config.apiSecret;

  Map<String, String> get _headers => {
        'Authorization': 'token $apiKey:$apiSecret',
        'Content-Type': 'application/json',
      };

  // Fetch Items
  Future<List<Item>> getItems() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/resource/Item'),
      headers: _headers,
    );

    print('Get Items Response: ${response.statusCode}');
    print('Get Items Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['data'] as List)
          .map((item) => Item.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to load items: ${response.statusCode} - ${response.body}');
    }
  }

  // Fetch Warehouses
  Future<List<Warehouse>> getWarehouses() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/resource/Warehouse'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['data'] as List)
          .map((warehouse) => Warehouse.fromJson(warehouse))
          .toList();
    } else {
      throw Exception('Failed to load warehouses');
    }
  }

  // Create Stock Entry
  Future<String> createStockEntry(StockEntry stockEntry) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/resource/Stock Entry'),
      headers: _headers,
      body: json.encode(stockEntry.toJson()),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return data['data']['name'];
    } else {
      throw Exception('Failed to create stock entry');
    }
  }

  // Get Bin Stock
  Future<double> getBinStock(String item, String warehouse) async {
    final response = await http.get(
      Uri.parse(
          '$baseUrl/api/resource/Bin?filters=[["item_code","=","$item"],["warehouse","=","$warehouse"]]'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if ((data['data'] as List).isNotEmpty) {
        return (data['data'][0]['actual_qty'] ?? 0.0).toDouble();
      }
      return 0.0;
    } else {
      throw Exception('Failed to get bin stock');
    }
  }
}
