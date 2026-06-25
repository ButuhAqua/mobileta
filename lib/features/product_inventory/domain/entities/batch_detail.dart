class BatchDetail {
  final String batchNo;
  final int qty;
  final DateTime expiredDate;
  final String status;
  final DateTime? productionDate;
  final int? qtyIn;
  final String? uom;

  const BatchDetail({
    required this.batchNo,
    required this.qty,
    required this.expiredDate,
    required this.status,
    this.productionDate,
    this.qtyIn,
    this.uom,
  });

  // Helper untuk menghitung sisa hari
  int get daysLeft => expiredDate.difference(DateTime.now()).inDays;

  // Helper untuk menentukan status otomatis
  static String determineStatus(DateTime expiredDate, int qtyRemaining) {
    final now = DateTime.now();
    final daysLeft = expiredDate.difference(now).inDays;

    if (qtyRemaining <= 0) return 'Habis';
    if (daysLeft < 0) return 'Expired';
    if (daysLeft <= 3) return 'Akan Expired';
    return 'OK';
  }
}