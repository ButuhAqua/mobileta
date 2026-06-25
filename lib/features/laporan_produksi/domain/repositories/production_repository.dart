import '../entities/production_report.dart';

abstract class ProductionRepository {
  Future<List<ProductionReport>> getProductionReports(
    String token,
  );

  Future<void> createProductionReport(
    ProductionReport report,
    String token,
  );
}