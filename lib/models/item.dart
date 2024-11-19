class Item {
  final String? itemCode;
  final String? itemName;
  final String? description;
  final String? stockUom;

  Item({
    this.itemCode,
    this.itemName,
    this.description,
    this.stockUom,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      itemCode: json['item_code'] as String? ?? '',
      itemName: json['item_name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      stockUom: json['stock_uom'] as String? ?? 'Nos',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_code': itemCode,
      'item_name': itemName,
      'description': description,
      'stock_uom': stockUom,
    };
  }
}
