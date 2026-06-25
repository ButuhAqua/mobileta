class RawMaterial {
  final int id;
  final String name;
  final String category;
  final String uom;
  final int stock;

  RawMaterial({
    required this.id,
    required this.name,
    required this.category,
    required this.uom,
    required this.stock,
  });

  factory RawMaterial.fromJson(Map<String, dynamic> json) {
    return RawMaterial(
      id: json['id'],
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      uom: json['uom'] ?? '',
      stock: json['stock'] ?? 0,
    );
  }
}