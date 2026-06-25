import '../../domain/entities/product_inventory_item.dart';
import '../../domain/repositories/product_inventory_repository.dart';
import '../datasources/product_inventory_remote_datasource.dart';

class ProductInventoryRepositoryImpl implements ProductInventoryRepository {
  final ProductInventoryRemoteDataSource dataSource;

  ProductInventoryRepositoryImpl(this.dataSource);

  @override
  Future<List<ProductInventoryItem>> getInventoryByLocation(
    String location,
    String token,
  ) {
    return dataSource.getInventoryByLocation(location, token);
  }
}