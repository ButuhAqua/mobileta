import '../repositories/approval_repository.dart';

class CompleteProductionReport {

  final ApprovalRepository repository;

  CompleteProductionReport(
    this.repository,
  );

  Future<void> call({

    required String token,

    required int reportId,

    required List<Map<String, dynamic>> items,

  }) {

    return repository
        .completeProductionReport(

      token: token,

      reportId: reportId,

      items: items,
    );
  }
}