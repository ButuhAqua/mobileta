import '../../domain/entities/batch_detail.dart';
import '../../domain/repositories/batch_repository.dart';
import '../datasources/batch_remote_datasource.dart';
import '../models/batch_detail_model.dart';

class BatchRepositoryImpl implements BatchRepository {
  final BatchRemoteDataSource remoteDataSource;

  BatchRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<BatchDetail>> getBatchesByProduct(
    String productId,
    String token,
  ) async {
    try {
      final batchData = await remoteDataSource.getBatchesByProduct(
        productId,
        token,
      );
      
      return batchData
          .map((data) => BatchDetailModel.fromJson(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to get batches: $e');
    }
  }
}