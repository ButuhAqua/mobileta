import '../entities/product_inventory_item.dart';

abstract class ProductInventoryRepository {
  Future<List<ProductInventoryItem>> getInventoryByLocation(
    String location,
    String token,
  );
}