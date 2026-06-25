import '../entities/runner_trip.dart';
import '../repositories/runner_trip_repository.dart';

class GetRunnerTrips {
  final RunnerTripRepository repository;

  GetRunnerTrips(this.repository);

  Future<List<RunnerTrip>> call(String token) {
    return repository.getRunnerTrips(token);
  }
}