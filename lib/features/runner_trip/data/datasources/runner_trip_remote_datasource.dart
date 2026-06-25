import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/runner_trip_model.dart';
import '../../domain/entities/runner_trip.dart';

class RunnerTripRemoteDatasource {
  final String baseUrl = 'https://rafi.djncloud.my.id/api';

  Future<List<RunnerTripModel>> getRunnerTrips(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/runner-trips'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed get runner trips: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    final List data = decoded['data'] ?? [];

    return data.map((e) => RunnerTripModel.fromJson(e)).toList();
  }

  Future<RunnerTripModel> createDepartureTrip({
    required String token,
    required String notes,
    required List<DepartureTripItem> items,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/runner-trips/departure'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'notes': notes,
        'items': items.map((e) {
          return {
            'product_id': e.productId,
            'qty_taken': e.qtyTaken,
          };
        }).toList(),
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed create departure trip: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    return RunnerTripModel.fromJson(decoded['data']);
  }

  Future<RunnerTripModel> createReturnTrip({
    required String token,
    required int runnerTripId,
    required String notes,
    required List<ReturnTripItem> items,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/runner-trips/$runnerTripId/return'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'notes': notes,
        'items': items.map((e) {
          return {
            'runner_trip_item_id': e.runnerTripItemId,
            'qty_returned': e.qtyReturned,
          };
        }).toList(),
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed create return trip: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    return RunnerTripModel.fromJson(decoded['data']);
  }
}