class Item {
  final String? itemCode;
  final String? itemName;
  final String? description;
  final String? stockUom;
  final double totalQty;
  final double reorderLevel;
  final String? defaultWarehouse;

  Item({
    this.itemCode,
    this.itemName,
    this.description,
    this.stockUom,
    this.totalQty = 0.0,
    this.reorderLevel = 0.0,
    this.defaultWarehouse,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      itemCode: json['item_code'] as String? ?? '',
      itemName: json['item_name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      stockUom: json['stock_uom'] as String? ?? 'Nos',
      totalQty: (json['total_qty'] ?? 0.0).toDouble(),
      reorderLevel: (json['warehouse_reorder_level'] ?? 0.0).toDouble(),
      defaultWarehouse: json['default_warehouse'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_code': itemCode,
      'item_name': itemName,
      'description': description,
      'stock_uom': stockUom,
      'total_qty': totalQty,
      'warehouse_reorder_level': reorderLevel,
      'default_warehouse': defaultWarehouse,
    };
  }
}
