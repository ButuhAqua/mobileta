class ProductionReport {
  final String id;
  final String reportNumber;
  final DateTime productionDate;
  final String status;
  final String notes;

  final List<ProductionMaterialUsage> materialUsages;
  final List<ProductionFinishedProduct> finishedProducts;

  ProductionReport({
    required this.id,
    required this.reportNumber,
    required this.productionDate,
    required this.status,
    required this.notes,
    required this.materialUsages,
    required this.finishedProducts,
  });
}

class ProductionMaterialUsage {
  final int rawMaterialId;
  final String rawMaterialName;
  final int qty;
  final String uom;

  ProductionMaterialUsage({
    required this.rawMaterialId,
    required this.rawMaterialName,
    required this.qty,
    required this.uom,
  });
}

class ProductionFinishedProduct {
  final int productId;
  final String productName;
  final int qty;
  final String uom;

  ProductionFinishedProduct({
    required this.productId,
    required this.productName,
    required this.qty,
    required this.uom,
  });
}