import '../../domain/entities/batch_detail.dart';

class BatchDetailModel extends BatchDetail {
  const BatchDetailModel({
    required super.batchNo,
    required super.qty,
    required super.expiredDate,
    required super.status,
    super.productionDate,
    super.qtyIn,
    super.uom,
  });

  factory BatchDetailModel.fromJson(Map<String, dynamic> json) {
    final expiredDate = DateTime.parse(json['expired_date'] ?? json['expiredDate']);
    final qtyRemaining = json['qty'] ?? json['qty_remaining'] ?? 0;
    
    // Tentukan status dari JSON atau hitung otomatis
    String status = json['status'] ?? 
        BatchDetail.determineStatus(expiredDate, qtyRemaining);

    return BatchDetailModel(
      batchNo: json['batch_no']?.toString() ?? json['batchNumber']?.toString() ?? '',
      qty: qtyRemaining,
      expiredDate: expiredDate,
      status: status,
      productionDate: json['production_date'] != null 
          ? DateTime.parse(json['production_date']) 
          : null,
      qtyIn: json['qty_in'],
      uom: json['uom'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'batch_no': batchNo,
      'qty': qty,
      'expired_date': expiredDate.toIso8601String(),
      'status': status,
      'production_date': productionDate?.toIso8601String(),
      'qty_in': qtyIn,
      'uom': uom,
    };
  }
}