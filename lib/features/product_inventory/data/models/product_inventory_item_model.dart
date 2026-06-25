import '../../domain/entities/product_inventory_item.dart';

class ProductInventoryItemModel extends ProductInventoryItem {
  const ProductInventoryItemModel({
    required super.id,
    required super.name,
    required super.sku,
    required super.uom,
    required super.qty,
    required super.minQty,
    required super.location,
    required super.lastUpdated,
  });

  factory ProductInventoryItemModel.fromJson(Map<String, dynamic> json) {
    return ProductInventoryItemModel(
      id: json['id'].toString(),
      productId: json['product_id']?.toString() ?? json['productId']?.toString() ?? '',
      name: json['name'] ?? '',
      sku: json['sku'] ?? '',
      uom: json['uom'] ?? '',
      qty: json['qty'] ?? 0,
      minQty: json['min_qty'] ?? 0,
      location: json['location'] ?? '',
      lastUpdated: json['last_updated'] == null
          ? null
          : DateTime.parse(json['last_updated']),
    );
  }
}