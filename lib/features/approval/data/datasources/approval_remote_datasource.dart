import 'dart:convert';

import 'package:http/http.dart' as http;

class ApprovalRemoteDataSource {
  final String baseUrl = 'https://rafi.djncloud.my.id/api';

  // =========================================================
  // RAW MATERIAL REQUEST
  // =========================================================

  Future<void> approveRawMaterialRequest({
    required String token,
    required int requestId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/raw-material-requests/$requestId/approve'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal approve pengajuan: ${response.body}');
    }
  }

  Future<void> completeRawMaterialRequest({
    required String token,
    required int requestId,
    required String supplier,
    required String batchNotes,
    required List<Map<String, dynamic>> items,
  }) async {

    final response = await http.post(
      Uri.parse(
        '$baseUrl/raw-material-requests/$requestId/complete',
      ),

      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },

      body: jsonEncode({
        'supplier': supplier,
        'batch_notes': batchNotes,
        'items': items,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal menyelesaikan pengajuan: ${response.body}',
      );
    }
  }

  Future<void> rejectRawMaterialRequest({
    required String token,
    required int requestId,
    String? reason,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/raw-material-requests/$requestId/reject'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'reason': reason ?? '',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal reject pengajuan: ${response.body}');
    }
  }

  // =========================================================
  // PRODUCTION REPORT
  // =========================================================

  Future<void> approveProductionReport({
    required String token,
    required int reportId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/production-reports/$reportId/approve'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal approve laporan produksi: ${response.body}');
    }
  }

  Future<void> completeProductionReport({
    required String token,
    required int reportId,
    required List<Map<String, dynamic>> items,
  }) async {

    final response = await http.post(
      Uri.parse(
        '$baseUrl/production-reports/$reportId/complete',
      ),

      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },

      body: jsonEncode({
        'items': items,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal menyelesaikan laporan produksi: ${response.body}',
      );
    }
  }

  Future<void> rejectProductionReport({
    required String token,
    required int reportId,
    String? reason,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/production-reports/$reportId/reject'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'reason': reason ?? '',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal reject laporan produksi: ${response.body}');
    }
  }

  // =========================================================
  // RUNNER TRIP
  // =========================================================

  Future<void> approveDepartureTrip({
    required String token,
    required int tripId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/runner-trips/$tripId/approve-departure'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal approve laporan berangkat: ${response.body}');
    }
  }

  Future<void> rejectDepartureTrip({
    required String token,
    required int tripId,
    String? reason,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/runner-trips/$tripId/reject-departure'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'reason': reason ?? '',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal reject laporan berangkat: ${response.body}');
    }
  }

  Future<void> approveReturnTrip({
    required String token,
    required int tripId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/runner-trips/$tripId/approve-return'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal approve laporan pulang: ${response.body}');
    }
  }

  Future<void> rejectReturnTrip({
    required String token,
    required int tripId,
    String? reason,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/runner-trips/$tripId/reject-return'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'reason': reason ?? '',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal reject laporan pulang: ${response.body}');
    }
  }
}