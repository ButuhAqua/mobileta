import '../../domain/entities/production_report.dart';

class ProductionReportModel extends ProductionReport {
  ProductionReportModel({
    required super.id,
    required super.reportNumber,
    required super.productionDate,
    required super.status,
    required super.notes,
    required super.materialUsages,
    required super.finishedProducts,
  });

  factory ProductionReportModel.fromJson(Map<String, dynamic> json) {
    return ProductionReportModel(
      id: json['id'].toString(),
      reportNumber: json['report_number'] ?? '',
      productionDate: DateTime.parse(json['production_date']),
      status: json['status'] ?? '',
      notes: json['notes'] ?? '',
      materialUsages: ((json['material_usages'] ?? []) as List)
          .map(
            (e) => ProductionMaterialUsage(
              rawMaterialId: e['raw_material_id'] ?? 0,
              rawMaterialName:
                  e['raw_material']?['name'] ??
                  e['raw_material_name'] ??
                  '',
              qty: e['qty'] ?? 0,
              uom: e['uom'] ?? '',
            ),
          )
          .toList(),
      finishedProducts: ((json['finished_products'] ?? []) as List)
          .map(
            (e) => ProductionFinishedProduct(
              productId: e['product_id'] ?? 0,
              productName:
                  e['product']?['name'] ??
                  e['product_name'] ??
                  '',
              qty: e['qty'] ?? 0,
              uom: e['uom'] ?? '',
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'report_number': reportNumber,
      'production_date': productionDate.toIso8601String(),
      'status': status,
      'notes': notes,
      'material_usages': materialUsages.map((e) {
        return {
          'raw_material_id': e.rawMaterialId,
          'qty': e.qty,
          'uom': e.uom,
        };
      }).toList(),
      'finished_products': finishedProducts.map((e) {
        return {
          'product_id': e.productId,
          'qty': e.qty,
          'uom': e.uom,
        };
      }).toList(),
    };
  }
}