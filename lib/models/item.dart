class Item {
  final String name;
  final String itemCode;
  final String itemName;
  final String description;
  final String uom;

  Item({
    required this.name,
    required this.itemCode,
    required this.itemName,
    required this.description,
    required this.uom,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      name: json['name'] ?? '',
      itemCode: json['item_code'] ?? '',
      itemName: json['item_name'] ?? '',
      description: json['description'] ?? '',
      uom: json['stock_uom'] ?? '',
    );
  }
}
