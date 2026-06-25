import '../repositories/approval_repository.dart';

class RejectDepartureTrip {
  final ApprovalRepository repository;

  RejectDepartureTrip(this.repository);

  Future<void> call({
    required String token,
    required int tripId,
    String? reason,
  }) {
    return repository.rejectDepartureTrip(
      token: token,
      tripId: tripId,
      reason: reason,
    );
  }
}