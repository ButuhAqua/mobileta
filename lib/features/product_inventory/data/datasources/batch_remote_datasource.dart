import 'dart:convert';
import 'package:http/http.dart' as http;

class BatchRemoteDataSource {
  final String baseUrl;

  BatchRemoteDataSource({this.baseUrl = 'https://rafi.djncloud.my.id'}); // ← GANTI dengan URL API Anda

  Future<List<Map<String, dynamic>>> getBatchesByProduct(
    String productId,
    String token,
  ) async {
    try {
      final url = '$baseUrl/api/products/$productId/batches';
      print('===== BATCH API REQUEST =====');
      print('URL: $url');
      print('Token: ${token.substring(0, 20)}...'); // Hanya tampilkan sebagian
      print('Token Length: ${token.length}');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json', // ← TAMBAHKAN INI
        },
      );

      print('===== BATCH API RESPONSE =====');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print('Parsed Response: $jsonResponse');
        
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final data = jsonResponse['data'];
          if (data is List) {
            return List<Map<String, dynamic>>.from(data);
          }
        }
        
        if (jsonResponse is List) {
          return List<Map<String, dynamic>>.from(jsonResponse);
        }
        
        return [];
      } else {
        print('Error Status Code: ${response.statusCode}');
        print('Error Body: ${response.body}');
        throw Exception('Failed to load batches: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error loading batches: $e');
      throw Exception('Error loading batches: $e');
    }
  }
}