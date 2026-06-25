import '../entities/runner_trip.dart';

abstract class RunnerTripRepository {
  Future<List<RunnerTrip>> getRunnerTrips(String token);

  Future<RunnerTrip> createDepartureTrip({
    required String token,
    required String notes,
    required List<DepartureTripItem> items,
  });

  Future<RunnerTrip> createReturnTrip({
    required String token,
    required int runnerTripId,
    required String notes,
    required List<ReturnTripItem> items,
  });
}