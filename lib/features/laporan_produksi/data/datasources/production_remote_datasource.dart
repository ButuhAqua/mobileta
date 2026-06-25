import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/production_report_model.dart';

class ProductionRemoteDatasource {
  final String baseUrl = 'https://rafi.djncloud.my.id/api';

  Future<List<ProductionReportModel>> getProductionReports(
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/production-reports'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed get production reports: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    final List data = decoded['data'] ?? [];

    return data.map((e) => ProductionReportModel.fromJson(e)).toList();
  }

  Future<void> createProductionReport(
    ProductionReportModel model,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/production-reports'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(model.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed create production report: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getRawMaterialInventory(
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/raw-material-inventory'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed get raw material inventory: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    final List data = decoded['data'] ?? [];

    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getProducts(
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/products'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed get products: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    final List data = decoded['data'] ?? [];

    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }
}