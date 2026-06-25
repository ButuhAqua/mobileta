class ProductInventoryItem {
  final String id;
  final String productId;
  final String name;
  final String sku;
  final String uom;
  final int qty;
  final int minQty;
  final String location;
  final DateTime? lastUpdated;
  final List<BatchDetail>? batches; // <-- Tambahkan ini

  const ProductInventoryItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.sku,
    required this.uom,
    required this.qty,
    required this.minQty,
    required this.location,
    required this.lastUpdated,
    this.batches, // <-- Opsional
  });
}

class BatchDetail {
  final String batchNo;
  final int qty;
  final DateTime expiredDate;
  final String status;

  const BatchDetail({
    required this.batchNo,
    required this.qty,
    required this.expiredDate,
    required this.status,
  });
}