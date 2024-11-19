class Warehouse {
  final String name;
  final String warehouseName;
  final String warehouseType;
  final bool isGroup;

  Warehouse({
    required this.name,
    required this.warehouseName,
    required this.warehouseType,
    required this.isGroup,
  });

  factory Warehouse.fromJson(Map<String, dynamic> json) {
    return Warehouse(
      name: json['name'] ?? '',
      warehouseName: json['warehouse_name'] ?? '',
      warehouseType: json['warehouse_type'] ?? '',
      isGroup: json['is_group'] ?? false,
    );
  }
}
