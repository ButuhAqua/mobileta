import '../entities/production_report.dart';
import '../repositories/production_repository.dart';

class GetProductionReports {
  final ProductionRepository repository;

  GetProductionReports(this.repository);

  Future<List<ProductionReport>> call(
    String token,
  ) async {
    return await repository.getProductionReports(
      token,
    );
  }
}