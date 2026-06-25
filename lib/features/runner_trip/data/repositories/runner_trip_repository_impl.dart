import '../../domain/entities/runner_trip.dart';
import '../../domain/repositories/runner_trip_repository.dart';
import '../datasources/runner_trip_remote_datasource.dart';

class RunnerTripRepositoryImpl implements RunnerTripRepository {
  final RunnerTripRemoteDatasource remoteDatasource;

  RunnerTripRepositoryImpl(this.remoteDatasource);

  @override
  Future<List<RunnerTrip>> getRunnerTrips(String token) {
    return remoteDatasource.getRunnerTrips(token);
  }

  @override
  Future<RunnerTrip> createDepartureTrip({
    required String token,
    required String notes,
    required List<DepartureTripItem> items,
  }) {
    return remoteDatasource.createDepartureTrip(
      token: token,
      notes: notes,
      items: items,
    );
  }

  @override
  Future<RunnerTrip> createReturnTrip({
    required String token,
    required int runnerTripId,
    required String notes,
    required List<ReturnTripItem> items,
  }) {
    return remoteDatasource.createReturnTrip(
      token: token,
      runnerTripId: runnerTripId,
      notes: notes,
      items: items,
    );
  }
}