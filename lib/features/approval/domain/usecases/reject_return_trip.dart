import '../repositories/approval_repository.dart';

class RejectReturnTrip {
  final ApprovalRepository repository;

  RejectReturnTrip(this.repository);

  Future<void> call({
    required String token,
    required int tripId,
    String? reason,
  }) {
    return repository.rejectReturnTrip(
      token: token,
      tripId: tripId,
      reason: reason,
    );
  }
}