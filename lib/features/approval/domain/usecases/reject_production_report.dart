import '../repositories/approval_repository.dart';

class RejectProductionReport {
  final ApprovalRepository repository;

  RejectProductionReport(this.repository);

  Future<void> call({
    required String token,
    required int reportId,
    String? reason,
  }) {
    return repository.rejectProductionReport(
      token: token,
      reportId: reportId,
      reason: reason,
    );
  }
}