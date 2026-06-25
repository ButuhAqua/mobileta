import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class InventoryBahanPage extends StatefulWidget {
  const InventoryBahanPage({super.key});

  @override
  State<InventoryBahanPage> createState() => _InventoryBahanPageState();
}

class _InventoryBahanPageState extends State<InventoryBahanPage> {
  static const Color kPrimary = Color(0xFFD32F2F);
  static const Color kText = Color(0xFF212121);
  static const Color kMuted = Color(0xFF616161);
  static const Color kBorder = Color(0xFFE0E0E0);

  final String baseUrl = 'https://rafi.djncloud.my.id/api';

  String _query = '';
  String _statusFilter = 'Semua';
  String _sort = 'Nama (A-Z)';

  bool _isLoading = true;
  List<RawMaterialInventoryItem> _data = [];

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Token tidak ditemukan, silakan login ulang');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/raw-material-inventory'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(response.body);
      }

      final decoded = jsonDecode(response.body);
      final List data = decoded['data'] ?? [];

      setState(() {
        _data = data
            .map((e) => RawMaterialInventoryItem.fromJson(e))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal ambil inventory: $e')),
      );
    }
  }

  String _statusOf(RawMaterialInventoryItem item) {
    if (item.totalStock <= 0) return 'Kosong';

    final hasExpired = item.batches.any((batch) => batch.status == 'Expired');
    if (hasExpired) return 'Ada Expired';

    final hasAlmostExpired =
        item.batches.any((batch) => batch.status == 'Hampir Expired');
    if (hasAlmostExpired) return 'Hampir Expired';

    return 'Aman';
  }

  List<RawMaterialInventoryItem> get _filteredSorted {
    final list = _data.where((item) {
      final q = _query.toLowerCase();

      final matchQuery = q.isEmpty ||
          item.name.toLowerCase().contains(q) ||
          item.category.toLowerCase().contains(q) ||
          item.uom.toLowerCase().contains(q);

      final status = _statusOf(item);
      final matchStatus = _statusFilter == 'Semua' || status == _statusFilter;

      return matchQuery && matchStatus;
    }).toList();

    list.sort((a, b) {
      switch (_sort) {
        case 'Stok Terendah':
          return a.totalStock.compareTo(b.totalStock);
        case 'Stok Tertinggi':
          return b.totalStock.compareTo(a.totalStock);
        case 'Expired Terdekat':
          final aDate = a.nearestExpiredDate ?? DateTime(9999);
          final bDate = b.nearestExpiredDate ?? DateTime(9999);
          return aDate.compareTo(bDate);
        case 'Nama (A-Z)':
        default:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
    });

    return list;
  }

  void _showBatchDetail(RawMaterialInventoryItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return _BatchDetailSheet(item: item);
      },
    );
  }

  Future<void> _refresh() async {
    await _loadInventory();
  }

  @override
  Widget build(BuildContext context) {
    final data = _filteredSorted;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: const Text('Inventory Bahan Baku'),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Cari nama / kategori / satuan…',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: kBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: kBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: kPrimary, width: 1.2),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              children: [
                _chip('Semua'),
                const SizedBox(width: 8),
                _chip('Aman'),
                const SizedBox(width: 8),
                _chip('Hampir Expired'),
                const SizedBox(width: 8),
                _chip('Ada Expired'),
                const SizedBox(width: 8),
                _chip('Kosong'),
                const SizedBox(width: 12),
                _sortDropdown(),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: kPrimary),
                  )
                : RefreshIndicator(
                    onRefresh: _refresh,
                    color: kPrimary,
                    child: data.isEmpty
                        ? const Center(
                            child: Text('Belum ada inventory bahan baku'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            itemCount: data.length,
                            itemBuilder: (context, index) {
                              final item = data[index];
                              final status = _statusOf(item);

                              return _InventoryCard(
                                item: item,
                                status: status,
                                onTap: () => _showBatchDetail(item),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String value) {
    final selected = _statusFilter == value;

    return ChoiceChip(
      label: Text(value),
      selected: selected,
      onSelected: (_) => setState(() => _statusFilter = value),
      selectedColor: kPrimary.withOpacity(.12),
      labelStyle: TextStyle(
        color: selected ? kPrimary : kMuted,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: selected ? kPrimary : kBorder),
      ),
      backgroundColor: Colors.white,
    );
  }

  Widget _sortDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.sort_rounded, size: 18, color: kMuted),
          const SizedBox(width: 6),
          DropdownButton<String>(
            value: _sort,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(
                value: 'Nama (A-Z)',
                child: Text('Nama (A-Z)'),
              ),
              DropdownMenuItem(
                value: 'Stok Terendah',
                child: Text('Stok Terendah'),
              ),
              DropdownMenuItem(
                value: 'Stok Tertinggi',
                child: Text('Stok Tertinggi'),
              ),
              DropdownMenuItem(
                value: 'Expired Terdekat',
                child: Text('Expired Terdekat'),
              ),
            ],
            onChanged: (value) {
              setState(() => _sort = value ?? _sort);
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================
// WIDGET INVENTORY CARD
// ============================================================
class _InventoryCard extends StatelessWidget {
  const _InventoryCard({
    required this.item,
    required this.status,
    required this.onTap,
  });

  final RawMaterialInventoryItem item;
  final String status;
  final VoidCallback onTap;

  static const Color kText = Color(0xFF212121);
  static const Color kMuted = Color(0xFF616161);
  static const Color kBorder = Color(0xFFE0E0E0);

  Color _statusColor(String status) {
    switch (status) {
      case 'Aman':
        return const Color(0xFF2E7D32);
      case 'Hampir Expired':
        return const Color(0xFFEF6C00);
      case 'Ada Expired':
      case 'Kosong':
        return const Color(0xFFC62828);
      default:
        return kMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: Colors.white,
        elevation: 4,
        shadowColor: const Color(0x14000000),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: kBorder),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: kText,
                        ),
                      ),
                    ),
                    _badge(status, color),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 14,
                  runSpacing: 8,
                  children: [
                    _iconText(
                      Icons.inventory_2_rounded,
                      '${item.totalStock} ${item.uom}',
                    ),
                    _iconText(
                      Icons.category_rounded,
                      item.category,
                    ),
                    _iconText(
                      Icons.all_inbox_rounded,
                      '${item.batchCount} batch',
                    ),
                    _iconText(
                      Icons.event_rounded,
                      item.nearestExpiredDate == null
                          ? 'Exp: -'
                          : 'Exp: ${_fmtDate(item.nearestExpiredDate!)}',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.touch_app_rounded,
                      size: 14,
                      color: kMuted,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Ketuk untuk lihat detail batch',
                      style: TextStyle(color: kMuted, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _iconText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: kMuted),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: kText)),
      ],
    );
  }

  String _fmtDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';
  }
}

// ============================================================
// WIDGET BATCH DETAIL SHEET (POPUP)
// ============================================================
class _BatchDetailSheet extends StatefulWidget {
  const _BatchDetailSheet({required this.item});

  final RawMaterialInventoryItem item;

  @override
  State<_BatchDetailSheet> createState() => _BatchDetailSheetState();
}

class _BatchDetailSheetState extends State<_BatchDetailSheet> {
  @override
  Widget build(BuildContext context) {
    final batches = widget.item.batches;
    final totalBatches = batches.length;
    final expired = batches.where((b) => b.status == 'Expired').length;
    final almostExpired = batches.where((b) => b.status == 'Hampir Expired').length;
    final aman = batches.where((b) => b.status == 'Aman').length;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.item.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF212121),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Kategori: ${widget.item.category}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${widget.item.totalStock} ${widget.item.uom}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),

                // Summary Cards
                Row(
                  children: [
                    _summaryCard(
                      'Total Batch',
                      totalBatches.toString(),
                      Icons.inventory_2_rounded,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _summaryCard(
                      'Aman',
                      aman.toString(),
                      Icons.check_circle_rounded,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    _summaryCard(
                      'Hampir Expired',
                      almostExpired.toString(),
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    _summaryCard(
                      'Expired',
                      expired.toString(),
                      Icons.cancel_rounded,
                      color: Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // List Batch
                Expanded(
                  child: batches.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Belum ada batch aktif',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: batches.length,
                          itemBuilder: (context, index) {
                            final batch = batches[index];
                            return _BatchCard(batch: batch);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, {Color color = Colors.green}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// WIDGET BATCH CARD
// ============================================================
class _BatchCard extends StatelessWidget {
  const _BatchCard({
    required this.batch,
  });

  final RawMaterialBatchItem batch;

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Aman':
        return Colors.green;
      case 'Hampir Expired':
        return Colors.orange;
      case 'Expired':
        return Colors.red;
      case 'Habis':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'Aman':
        return Colors.green.shade50;
      case 'Hampir Expired':
        return Colors.orange.shade50;
      case 'Expired':
        return Colors.red.shade50;
      case 'Habis':
        return Colors.grey.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day}/${date.month}/${date.year}';
  }

  int? _getDaysLeft(DateTime? date) {
    if (date == null) return null;
    return date.difference(DateTime.now()).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(batch.status);
    final bgColor = _getStatusBgColor(batch.status);
    final daysLeft = _getDaysLeft(batch.expiredDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        batch.batchNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF212121),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        batch.status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.inventory_2_rounded, size: 14, color: Color(0xFF616161)),
                    const SizedBox(width: 4),
                    Text(
                      'Sisa: ${batch.qtyRemaining} ${batch.uom}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.event_rounded, size: 14, color: Color(0xFF616161)),
                    const SizedBox(width: 4),
                    Text(
                      'Exp: ${_formatDate(batch.expiredDate)}',
                      style: TextStyle(
                        color: daysLeft != null && daysLeft < 0 ? Colors.red : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    if (batch.supplier != null && batch.supplier!.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.business_rounded, size: 14, color: Color(0xFF616161)),
                      const SizedBox(width: 4),
                      Text(
                        batch.supplier!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
                if (daysLeft != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    daysLeft > 0
                        ? '⏳ ${daysLeft.toString()} hari lagi expired'
                        : daysLeft == 0
                            ? '⚠️ Hari ini expired!'
                            : '❌ Telah expired ${daysLeft.abs().toString()} hari lalu',
                    style: TextStyle(
                      color: daysLeft < 0 ? Colors.red : Colors.grey[600],
                      fontSize: 11,
                      fontWeight: daysLeft < 0 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DATA MODELS
// ============================================================
class RawMaterialInventoryItem {
  final int rawMaterialId;
  final String name;
  final String category;
  final String uom;
  final int totalStock;
  final int batchCount;
  final DateTime? nearestExpiredDate;
  final List<RawMaterialBatchItem> batches;

  RawMaterialInventoryItem({
    required this.rawMaterialId,
    required this.name,
    required this.category,
    required this.uom,
    required this.totalStock,
    required this.batchCount,
    required this.nearestExpiredDate,
    required this.batches,
  });

  factory RawMaterialInventoryItem.fromJson(Map<String, dynamic> json) {
    return RawMaterialInventoryItem(
      rawMaterialId: json['raw_material_id'] ?? 0,
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      uom: json['uom'] ?? '',
      totalStock: json['total_stock'] ?? 0,
      batchCount: json['batch_count'] ?? 0,
      nearestExpiredDate: json['nearest_expired_date'] == null
          ? null
          : DateTime.parse(json['nearest_expired_date']),
      batches: ((json['batches'] ?? []) as List)
          .map((e) => RawMaterialBatchItem.fromJson(e))
          .toList(),
    );
  }
}

class RawMaterialBatchItem {
  final int id;
  final String batchNumber;
  final DateTime? receivedDate;
  final DateTime? expiredDate;
  final int qtyIn;
  final int qtyRemaining;
  final String uom;
  final String? supplier;
  final String status;

  RawMaterialBatchItem({
    required this.id,
    required this.batchNumber,
    required this.receivedDate,
    required this.expiredDate,
    required this.qtyIn,
    required this.qtyRemaining,
    required this.uom,
    required this.supplier,
    required this.status,
  });

  factory RawMaterialBatchItem.fromJson(Map<String, dynamic> json) {
    return RawMaterialBatchItem(
      id: json['id'] ?? 0,
      batchNumber: json['batch_number'] ?? '',
      receivedDate: json['received_date'] == null
          ? null
          : DateTime.parse(json['received_date']),
      expiredDate: json['expired_date'] == null
          ? null
          : DateTime.parse(json['expired_date']),
      qtyIn: json['qty_in'] ?? 0,
      qtyRemaining: json['qty_remaining'] ?? 0,
      uom: json['uom'] ?? '',
      supplier: json['supplier'],
      status: json['status'] ?? 'Aman',
    );
  }
}