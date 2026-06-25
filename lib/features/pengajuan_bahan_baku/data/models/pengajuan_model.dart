import '../../domain/entities/pengajuan.dart';

class PengajuanModel extends Pengajuan {
  PengajuanModel({
    required super.id,
    required super.title,
    required super.requestType,
    required super.priority,
    required super.requestDate,
    required super.notes,
    required super.items,
    required super.purchaseLocation,
    required super.status,
  });

  factory PengajuanModel.fromJson(Map<String, dynamic> json) {
    return PengajuanModel(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      requestType: json['request_type'] ?? '',
      priority: json['priority'] ?? '',
      requestDate: DateTime.parse(json['request_date']),
      notes: json['notes'] ?? '',
      purchaseLocation: json['purchase_location'],
      status: json['status'] ?? 'Menunggu',
      items: ((json['items'] ?? []) as List)
          .map((e) => PengajuanItem(
                rawMaterialId: e['raw_material_id'],
                name: e['name'] ?? '',
                category: e['category'] ?? '',
                uom: e['uom'] ?? '',
                qty: e['qty'] ?? 0,
              ))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "title": title,
      "request_type": requestType,
      "priority": priority,
      "request_date": requestDate.toIso8601String(),
      "notes": notes,
      "purchase_location": purchaseLocation,
      "items": items.map((e) {
        return {
          "raw_material_id": e.rawMaterialId,
          "qty": e.qty,
        };
      }).toList(),
    };
  }
}