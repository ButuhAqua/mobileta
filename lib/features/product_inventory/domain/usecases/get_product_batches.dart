import '../entities/batch_detail.dart';
import '../repositories/batch_repository.dart';

class GetProductBatches {
  final BatchRepository repository;

  GetProductBatches(this.repository);

  Future<List<BatchDetail>> call(String productId, String token) {
    return repository.getBatchesByProduct(productId, token);
  }
}