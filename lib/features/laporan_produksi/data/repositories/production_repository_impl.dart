import '../../domain/entities/production_report.dart';
import '../../domain/repositories/production_repository.dart';
import '../datasources/production_remote_datasource.dart';
import '../models/production_report_model.dart';

class ProductionRepositoryImpl implements ProductionRepository {
  final ProductionRemoteDatasource remoteDatasource;

  ProductionRepositoryImpl(this.remoteDatasource);

  @override
  Future<void> createProductionReport(
    ProductionReport report,
    String token,
  ) async {
    final model = ProductionReportModel(
      id: report.id,
      reportNumber: report.reportNumber,
      productionDate: report.productionDate,
      status: report.status,
      notes: report.notes,
      materialUsages: report.materialUsages,
      finishedProducts: report.finishedProducts,
    );

    await remoteDatasource.createProductionReport(
      model,
      token,
    );
  }

  @override
  Future<List<ProductionReport>> getProductionReports(
    String token,
  ) async {
    return await remoteDatasource.getProductionReports(
      token,
    );
  }
}