import '../repositories/approval_repository.dart';

class ApproveReturnTrip {
  final ApprovalRepository repository;

  ApproveReturnTrip(this.repository);

  Future<void> call({
    required String token,
    required int tripId,
  }) {
    return repository.approveReturnTrip(
      token: token,
      tripId: tripId,
    );
  }
}