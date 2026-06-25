import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/pengajuan_model.dart';

class PengajuanRemoteDataSource {
  final String baseUrl = 'https://rafi.djncloud.my.id/api';

  Future<void> createPengajuan(
    PengajuanModel model,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/raw-material-requests'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(model.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed create pengajuan: ${response.body}');
    }
  }

  Future<List<PengajuanModel>> getPengajuanList(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/raw-material-requests'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => PengajuanModel.fromJson(e)).toList();
    }

    throw Exception('Failed get pengajuan: ${response.body}');
  }

  Future<List<Map<String, dynamic>>> getRawMaterials(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/raw-materials'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List data = decoded['data'] ?? [];

      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }

    throw Exception('Failed get raw materials: ${response.body}');
  }
}