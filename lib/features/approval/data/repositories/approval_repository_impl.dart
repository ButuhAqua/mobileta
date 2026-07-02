import '../../domain/repositories/approval_repository.dart';
import '../datasources/approval_remote_datasource.dart';

class ApprovalRepositoryImpl implements ApprovalRepository {
  final ApprovalRemoteDataSource remoteDataSource;

  ApprovalRepositoryImpl(this.remoteDataSource);

  // =========================================================
  // RAW MATERIAL REQUEST
  // =========================================================

  @override
  Future<void> approveRawMaterialRequest({
    required String token,
    required int requestId,
  }) {
    return remoteDataSource.approveRawMaterialRequest(
      token: token,
      requestId: requestId,
    );
  }

  @override
  Future<void> completeRawMaterialRequest({
    required String token,
    required int requestId,
    required String supplier,
    required String batchNotes,
    String? location,
    required List<Map<String, dynamic>> items,
  }) {

    return remoteDataSource
        .completeRawMaterialRequest(
      token: token,
      requestId: requestId,
      supplier: supplier,
      batchNotes: batchNotes,
      location: location,
      items: items,
    );
  }

  @override
  Future<void> rejectRawMaterialRequest({
    required String token,
    required int requestId,
    String? reason,
  }) {
    return remoteDataSource.rejectRawMaterialRequest(
      token: token,
      requestId: requestId,
      reason: reason,
    );
  }

  // =========================================================
  // PRODUCTION REPORT
  // =========================================================

  @override
  Future<void> approveProductionReport({
    required String token,
    required int reportId,
  }) {
    return remoteDataSource.approveProductionReport(
      token: token,
      reportId: reportId,
    );
  }

  @override
  Future<void> completeProductionReport({
    required String token,
    required int reportId,
    required List<Map<String, dynamic>> items,
  }) {

    return remoteDataSource.completeProductionReport(
      token: token,
      reportId: reportId,
      items: items,
    );
  }

  @override
  Future<void> rejectProductionReport({
    required String token,
    required int reportId,
    String? reason,
  }) {
    return remoteDataSource.rejectProductionReport(
      token: token,
      reportId: reportId,
      reason: reason,
    );
  }

  // =========================================================
  // RUNNER TRIP
  // =========================================================

  @override
  Future<void> approveDepartureTrip({
    required String token,
    required int tripId,
  }) {
    return remoteDataSource.approveDepartureTrip(
      token: token,
      tripId: tripId,
    );
  }

  @override
  Future<void> rejectDepartureTrip({
    required String token,
    required int tripId,
    String? reason,
  }) {
    return remoteDataSource.rejectDepartureTrip(
      token: token,
      tripId: tripId,
      reason: reason,
    );
  }

  @override
  Future<void> approveReturnTrip({
    required String token,
    required int tripId,
  }) {
    return remoteDataSource.approveReturnTrip(
      token: token,
      tripId: tripId,
    );
  }

  @override
  Future<void> rejectReturnTrip({
    required String token,
    required int tripId,
    String? reason,
  }) {
    return remoteDataSource.rejectReturnTrip(
      token: token,
      tripId: tripId,
      reason: reason,
    );
  }
}