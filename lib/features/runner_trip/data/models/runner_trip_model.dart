import '../../domain/entities/runner_trip.dart';

class RunnerTripModel extends RunnerTrip {
  RunnerTripModel({
    required super.id,
    required super.userId,
    required super.runnerName,
    required super.location,
    required super.departureAt,
    required super.returnAt,
    required super.status,
    required super.notes,
    required super.items,
  });

  factory RunnerTripModel.fromJson(Map<String, dynamic> json) {
    return RunnerTripModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      runnerName: json['user']?['name'] ?? '',
      location: json['location'] ?? '',
      departureAt: json['departure_at'] == null
          ? null
          : DateTime.parse(json['departure_at']),
      returnAt:
          json['return_at'] == null ? null : DateTime.parse(json['return_at']),
      status: json['status'] ?? '',
      notes: json['notes'] ?? '',
      items: ((json['items'] ?? []) as List).map((e) {
        return RunnerTripItem(
          id: e['id'] ?? 0,
          productId: e['product_id'] ?? 0,
          productName: e['product']?['name'] ?? '',
          qtyTaken: e['qty_taken'] ?? 0,
          qtyReturned: e['qty_returned'],
          qtySold: e['qty_sold'] ?? 0,
          uom: e['uom'] ?? '',
        );
      }).toList(),
    );
  }
}