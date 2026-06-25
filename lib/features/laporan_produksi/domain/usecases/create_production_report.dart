import '../entities/production_report.dart';
import '../repositories/production_repository.dart';

class CreateProductionReport {
  final ProductionRepository repository;

  CreateProductionReport(this.repository);

  Future<void> call(
    ProductionReport report,
    String token,
  ) async {
    await repository.createProductionReport(
      report,
      token,
    );
  }
}