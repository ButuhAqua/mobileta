abstract class ApprovalRepository {

  // =========================================================
  // RAW MATERIAL REQUEST
  // =========================================================

  Future<void> approveRawMaterialRequest({
    required String token,
    required int requestId,
  });

  Future<void> completeRawMaterialRequest({
    required String token,
    required int requestId,
    required String supplier,
    required String batchNotes,
    String? location,
    required List<Map<String, dynamic>> items,
  });

  Future<void> rejectRawMaterialRequest({
    required String token,
    required int requestId,
    String? reason,
  });

  // =========================================================
  // PRODUCTION REPORT
  // =========================================================

  Future<void> approveProductionReport({
    required String token,
    required int reportId,
  });

  Future<void> completeProductionReport({
    required String token,
    required int reportId,
    required List<Map<String, dynamic>> items,
  });

  Future<void> rejectProductionReport({
    required String token,
    required int reportId,
    String? reason,
  });

  // =========================================================
  // RUNNER TRIP
  // =========================================================

  Future<void> approveDepartureTrip({
    required String token,
    required int tripId,
  });

  Future<void> rejectDepartureTrip({
    required String token,
    required int tripId,
    String? reason,
  });

  Future<void> approveReturnTrip({
    required String token,
    required int tripId,
  });

  Future<void> rejectReturnTrip({
    required String token,
    required int tripId,
    String? reason,
  });
}