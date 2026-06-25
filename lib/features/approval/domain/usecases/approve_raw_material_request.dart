import '../repositories/approval_repository.dart';

class ApproveRawMaterialRequest {
  final ApprovalRepository repository;

  ApproveRawMaterialRequest(this.repository);

  Future<void> call({
    required String token,
    required int requestId,
  }) {
    return repository.approveRawMaterialRequest(
      token: token,
      requestId: requestId,
    );
  }
}