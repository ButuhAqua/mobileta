import '../entities/runner_trip.dart';
import '../repositories/runner_trip_repository.dart';

class CreateReturnTrip {
  final RunnerTripRepository repository;

  CreateReturnTrip(this.repository);

  Future<RunnerTrip> call({
    required String token,
    required int runnerTripId,
    required String notes,
    required List<ReturnTripItem> items,
  }) {
    return repository.createReturnTrip(
      token: token,
      runnerTripId: runnerTripId,
      notes: notes,
      items: items,
    );
  }
}