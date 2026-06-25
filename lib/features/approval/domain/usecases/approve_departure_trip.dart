import '../repositories/approval_repository.dart';

class ApproveDepartureTrip {
  final ApprovalRepository repository;

  ApproveDepartureTrip(this.repository);

  Future<void> call({
    required String token,
    required int tripId,
  }) {
    return repository.approveDepartureTrip(
      token: token,
      tripId: tripId,
    );
  }
}