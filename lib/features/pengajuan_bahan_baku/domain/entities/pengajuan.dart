class Pengajuan {
  final String id;
  final String title;
  final String requestType;
  final String priority;
  final DateTime requestDate;
  final String notes;
  final List<PengajuanItem> items;
  final String? purchaseLocation;
  final String status;

  Pengajuan({
    required this.id,
    required this.title,
    required this.requestType,
    required this.priority,
    required this.requestDate,
    required this.notes,
    required this.items,
    required this.purchaseLocation,
    required this.status,
  });
}

class PengajuanItem {
  final int? rawMaterialId;
  final String name;
  final String category;
  final String uom;
  final int qty;

  PengajuanItem({
    this.rawMaterialId,
    required this.name,
    required this.category,
    required this.uom,
    required this.qty,
  });
}