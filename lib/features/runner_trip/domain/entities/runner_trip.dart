class RunnerTrip {
  final int id;
  final int userId;
  final String runnerName;
  final String location;
  final DateTime? departureAt;
  final DateTime? returnAt;
  final String status;
  final String notes;
  final List<RunnerTripItem> items;

  RunnerTrip({
    required this.id,
    required this.userId,
    required this.runnerName,
    required this.location,
    required this.departureAt,
    required this.returnAt,
    required this.status,
    required this.notes,
    required this.items,
  });
}

class RunnerTripItem {
  final int id;
  final int productId;
  final String productName;
  final int qtyTaken;
  final int? qtyReturned;
  final int qtySold;
  final String uom;

  RunnerTripItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.qtyTaken,
    required this.qtyReturned,
    required this.qtySold,
    required this.uom,
  });
}

class DepartureTripItem {
  final int productId;
  final int qtyTaken;

  DepartureTripItem({
    required this.productId,
    required this.qtyTaken,
  });
}

class ReturnTripItem {
  final int runnerTripItemId;
  final int qtyReturned;

  ReturnTripItem({
    required this.runnerTripItemId,
    required this.qtyReturned,
  });
}