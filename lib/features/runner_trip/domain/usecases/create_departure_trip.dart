import '../entities/runner_trip.dart';
import '../repositories/runner_trip_repository.dart';

class CreateDepartureTrip {
  final RunnerTripRepository repository;

  CreateDepartureTrip(this.repository);

  Future<RunnerTrip> call({
    required String token,
    required String notes,
    required List<DepartureTripItem> items,
  }) {
    return repository.createDepartureTrip(
      token: token,
      notes: notes,
      items: items,
    );
  }
}