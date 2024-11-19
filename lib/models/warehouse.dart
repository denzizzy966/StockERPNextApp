class Warehouse {
  final String? name;
  final String? warehouseName;

  Warehouse({
    this.name,
    this.warehouseName,
  });

  factory Warehouse.fromJson(Map<String, dynamic> json) {
    return Warehouse(
      name: json['name'],
      warehouseName: json['warehouse_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'warehouse_name': warehouseName,
    };
  }
}
