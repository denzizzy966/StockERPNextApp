class StockEntry {
  final String name;
  final String stockEntryType;
  final String postingDate;
  final String fromWarehouse;
  final String toWarehouse;
  final List<StockEntryItem> items;

  StockEntry({
    required this.name,
    required this.stockEntryType,
    required this.postingDate,
    required this.fromWarehouse,
    required this.toWarehouse,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'doctype': 'Stock Entry',
      'stock_entry_type': stockEntryType,
      'posting_date': postingDate,
      'from_warehouse': fromWarehouse,
      'to_warehouse': toWarehouse,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  factory StockEntry.fromJson(Map<String, dynamic> json) {
    return StockEntry(
      name: json['name'] ?? '',
      stockEntryType: json['stock_entry_type'] ?? '',
      postingDate: json['posting_date'] ?? '',
      fromWarehouse: json['from_warehouse'] ?? '',
      toWarehouse: json['to_warehouse'] ?? '',
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => StockEntryItem.fromJson(item))
          .toList() ?? [],
    );
  }
}

class StockEntryItem {
  final String item;
  final double qty;
  final String uom;
  final String fromWarehouse;
  final String toWarehouse;

  StockEntryItem({
    required this.item,
    required this.qty,
    required this.uom,
    required this.fromWarehouse,
    required this.toWarehouse,
  });

  Map<String, dynamic> toJson() {
    return {
      'item_code': item,
      'qty': qty,
      'uom': uom,
      'from_warehouse': fromWarehouse,
      'to_warehouse': toWarehouse,
    };
  }

  factory StockEntryItem.fromJson(Map<String, dynamic> json) {
    return StockEntryItem(
      item: json['item_code'] ?? '',
      qty: (json['qty'] ?? 0.0).toDouble(),
      uom: json['uom'] ?? '',
      fromWarehouse: json['from_warehouse'] ?? '',
      toWarehouse: json['to_warehouse'] ?? '',
    );
  }
}
