import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../domain/entities/product_inventory_item.dart';

class ProductInventoryRemoteDataSource {
  final String baseUrl = 'https://rafi.djncloud.my.id/api';

  Future<List<ProductInventoryItem>> getInventoryByLocation(
    String location,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/inventory?location=$location'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      return data.map((e) {
        return ProductInventoryItem(
          id: e['id'].toString(),
          productId: e['product_id'].toString(),
          name: e['name'] ?? '',
          sku: e['sku'] ?? '',
          uom: e['uom'] ?? '',
          qty: e['qty'] ?? 0,
          minQty: e['min_qty'] ?? 0,
          location: e['location'] ?? '',
          lastUpdated: e['last_updated'] == null
              ? null
              : DateTime.parse(e['last_updated']),
        );
      }).toList();
    }

    throw Exception('Failed to load product inventory: ${response.body}');
  }
}