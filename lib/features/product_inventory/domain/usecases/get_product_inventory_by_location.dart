import '../entities/product_inventory_item.dart';
import '../repositories/product_inventory_repository.dart';

class GetProductInventoryByLocation {
  final ProductInventoryRepository repository;

  GetProductInventoryByLocation(this.repository);

  Future<List<ProductInventoryItem>> call(
    String location,
    String token,
  ) {
    return repository.getInventoryByLocation(location, token);
  }
}