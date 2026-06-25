import '../repositories/approval_repository.dart';

class RejectRawMaterialRequest {
  final ApprovalRepository repository;

  RejectRawMaterialRequest(this.repository);

  Future<void> call({
    required String token,
    required int requestId,
    String? reason,
  }) {
    return repository.rejectRawMaterialRequest(
      token: token,
      requestId: requestId,
      reason: reason,
    );
  }
}