import '../entities/batch_detail.dart';

abstract class BatchRepository {
  Future<List<BatchDetail>> getBatchesByProduct(String productId, String token);
}