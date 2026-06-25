import '../repositories/approval_repository.dart';

class ApproveProductionReport {
  final ApprovalRepository repository;

  ApproveProductionReport(this.repository);

  Future<void> call({
    required String token,
    required int reportId,
  }) {
    return repository.approveProductionReport(
      token: token,
      reportId: reportId,
    );
  }
}