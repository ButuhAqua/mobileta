import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/product_inventory_remote_datasource.dart';
import '../../data/repositories/product_inventory_repository_impl.dart';
import '../../domain/entities/product_inventory_item.dart' show ProductInventoryItem;
import '../../domain/entities/batch_detail.dart';
import '../../domain/usecases/get_product_inventory_by_location.dart';
import '../../domain/usecases/get_product_batches.dart';
import '../../data/datasources/batch_remote_datasource.dart';
import '../../data/repositories/batch_repository_impl.dart';

class InventoryGerobakDPage extends StatefulWidget {
  const InventoryGerobakDPage({super.key});

  @override
  State<InventoryGerobakDPage> createState() => _InventoryGerobakDPageState();
}

class _InventoryGerobakDPageState extends State<InventoryGerobakDPage> {
  static const Color kPrimary = Color(0xFF6A1B9A); // Orange untuk Gerobak C
  static const Color kMuted = Color(0xFF616161);
  static const Color kBorder = Color(0xFFE0E0E0);
  static const Color kCard = Colors.white;

  String _query = '';
  String _statusFilter = 'Semua';
  String _sort = 'Nama (A-Z)';

  late Future<List<ProductInventoryItem>> _futureInventory;

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      setState(() {
        _futureInventory = Future.error('Token tidak ditemukan, silakan login ulang');
      });
      return;
    }

    final repository = ProductInventoryRepositoryImpl(
      ProductInventoryRemoteDataSource(),
    );

    final getInventoryByLocation = GetProductInventoryByLocation(repository);

    setState(() {
      _futureInventory = getInventoryByLocation('Gerobak D', token);
    });
  }

  String _statusOf(ProductInventoryItem e) {
    if (e.qty <= 0) return 'Habis';
    if (e.qty <= e.minQty) return 'Low';
    return 'OK';
  }

  List<ProductInventoryItem> _filteredSorted(List<ProductInventoryItem> data) {
    final list = data.where((e) {
      final q = _query.toLowerCase();

      final matchQ = q.isEmpty ||
          e.name.toLowerCase().contains(q) ||
          e.sku.toLowerCase().contains(q) ||
          e.id.toLowerCase().contains(q);

      final status = _statusOf(e);
      final matchStatus = _statusFilter == 'Semua' || status == _statusFilter;

      return matchQ && matchStatus;
    }).toList();

    list.sort((a, b) {
      switch (_sort) {
        case 'Stok Terendah':
          return a.qty.compareTo(b.qty);
        case 'Stok Tertinggi':
          return b.qty.compareTo(a.qty);
        case 'Terbaru':
          return (b.lastUpdated ?? DateTime(2000))
              .compareTo(a.lastUpdated ?? DateTime(2000));
        case 'Nama (A-Z)':
        default:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
    });

    return list;
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m)),
    );
  }

  void _showBatchDetailPopup(ProductInventoryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      _snack('Token tidak ditemukan, silakan login ulang');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _BatchDetailSheet(
        item: item,
        token: token,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: const Text('Inventory Produk — Gerobak D'),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Cari nama / SKU…',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                _chip('Semua', selected: _statusFilter == 'Semua', onTap: () => setState(() => _statusFilter = 'Semua')),
                const SizedBox(width: 8),
                _chip('OK', selected: _statusFilter == 'OK', onTap: () => setState(() => _statusFilter = 'OK')),
                const SizedBox(width: 8),
                _chip('Low', selected: _statusFilter == 'Low', onTap: () => setState(() => _statusFilter = 'Low')),
                const SizedBox(width: 8),
                _chip('Habis', selected: _statusFilter == 'Habis', onTap: () => setState(() => _statusFilter = 'Habis')),
                const SizedBox(width: 12),
                _sortDropdown(),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ProductInventoryItem>>(
              future: _futureInventory,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: kPrimary));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Terjadi error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final data = snapshot.data ?? [];
                final filteredData = _filteredSorted(data);

                if (filteredData.isEmpty) {
                  return const Center(child: Text('Data inventory tidak ditemukan'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: filteredData.length,
                  itemBuilder: (context, i) {
                    final item = filteredData[i];
                    final status = _statusOf(item);

                    return _ProductCard(
                      item: item,
                      status: status,
                      onTap: () => _showBatchDetailPopup(item),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, {required bool selected, required VoidCallback onTap}) {
    return ChoiceChip(
      label: Text(text),
      selected: selected,
      onSelected: (_) => onTap(),
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
        color: kCard,
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
              DropdownMenuItem(value: 'Nama (A-Z)', child: Text('Nama (A-Z)')),
              DropdownMenuItem(value: 'Stok Terendah', child: Text('Stok Terendah')),
              DropdownMenuItem(value: 'Stok Tertinggi', child: Text('Stok Tertinggi')),
              DropdownMenuItem(value: 'Terbaru', child: Text('Terbaru')),
            ],
            onChanged: (v) => setState(() => _sort = v ?? _sort),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color c;

    switch (status) {
      case 'OK':
        c = const Color(0xFF2E7D32);
        break;
      case 'Low':
        c = const Color(0xFFEF6C00);
        break;
      case 'Habis':
        c = const Color(0xFFC62828);
        break;
      default:
        c = kMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }

  Widget _sheetBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: kPrimary),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: kBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

// ============================================================
// WIDGET PRODUCT CARD
// ============================================================
class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.item,
    required this.status,
    required this.onTap,
  });

  final ProductInventoryItem item;
  final String status;
  final VoidCallback onTap;

  static const Color kText = Color(0xFF212121);
  static const Color kMuted = Color(0xFF616161);
  static const Color kBorder = Color(0xFFE0E0E0);

  Color _statusColor(String s) {
    switch (s) {
      case 'OK':
        return const Color(0xFF2E7D32);
      case 'Low':
        return const Color(0xFFEF6C00);
      case 'Habis':
        return const Color(0xFFC62828);
      default:
        return kMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _statusColor(status);
    final need = item.minQty <= 0 ? 0 : (item.minQty - item.qty).clamp(0, 999999);
    final pct = item.minQty <= 0 ? 1.0 : (item.qty / (item.minQty * 2)).clamp(0.0, 1.0);

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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: c.withOpacity(.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _iconText(Icons.qr_code_rounded, item.sku),
                    _iconText(Icons.place_rounded, item.location),
                    _iconText(Icons.inventory_2_rounded, '${item.qty} ${item.uom} (min ${item.minQty})'),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFF0F0F0),
                    valueColor: AlwaysStoppedAnimation<Color>(c),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.update_rounded, size: 14, color: kMuted),
                    const SizedBox(width: 6),
                    Text(
                      item.lastUpdated == null ? '—' : _fmtDateLong(item.lastUpdated!),
                      style: const TextStyle(color: kMuted, fontSize: 12),
                    ),
                    const Spacer(),
                    if (need > 0)
                      Text(
                        'Butuh +$need ${item.uom}',
                        style: const TextStyle(color: kMuted, fontSize: 12),
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

  String _fmtDateLong(DateTime d) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];

    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ============================================================
// WIDGET BATCH DETAIL SHEET
// ============================================================
class _BatchDetailSheet extends StatefulWidget {
  const _BatchDetailSheet({
    required this.item,
    required this.token,
  });

  final ProductInventoryItem item;
  final String token;

  @override
  State<_BatchDetailSheet> createState() => _BatchDetailSheetState();
}

class _BatchDetailSheetState extends State<_BatchDetailSheet> {
  late Future<List<BatchDetail>> _futureBatches;

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  void _loadBatches() {
    print('===== LOAD BATCHES =====');
    print('Product ID: ${widget.item.productId}');
    print('Product Name: ${widget.item.name}');

    final repository = BatchRepositoryImpl(
      BatchRemoteDataSource(),
    );
    final getBatches = GetProductBatches(repository);

    setState(() {
      _futureBatches = getBatches(widget.item.productId, widget.token);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
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
                          ),
                        ),
                        Text(
                          'SKU: ${widget.item.sku}',
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
                      '${widget.item.qty} ${widget.item.uom}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              Expanded(
                child: FutureBuilder<List<BatchDetail>>(
                  future: _futureBatches,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFF57C00),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Gagal memuat data batch',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${snapshot.error}',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    final batches = snapshot.data ?? [];

                    if (batches.isEmpty) {
                      return Center(
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
                              'Tidak ada data batch',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final totalBatches = batches.length;
                    final expiringSoon = batches.where(
                      (b) => b.status == 'Akan Expired'
                    ).length;
                    final expired = batches.where(
                      (b) => b.status == 'Expired'
                    ).length;

                    return Column(
                      children: [
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
                              'Akan Expired',
                              expiringSoon.toString(),
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
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            itemCount: batches.length,
                            itemBuilder: (context, index) {
                              final batch = batches[index];
                              return _BatchCard(batch: batch);
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
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
  const _BatchCard({required this.batch});

  final BatchDetail batch;

  Color _getStatusColor(String status) {
    switch (status) {
      case 'OK':
        return Colors.green;
      case 'Akan Expired':
        return Colors.orange;
      case 'Expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'OK':
        return Colors.green.shade50;
      case 'Akan Expired':
        return Colors.orange.shade50;
      case 'Expired':
        return Colors.red.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(batch.status);
    final bgColor = _getStatusBgColor(batch.status);
    final daysLeft = batch.daysLeft;

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
            height: 40,
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
                Text(
                  batch.batchNo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sisa: ${batch.qty} cup',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
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
              const SizedBox(height: 4),
              Text(
                'Exp: ${_formatDate(batch.expiredDate)}${daysLeft > 0 ? ' ($daysLeft hari)' : daysLeft == 0 ? ' (Hari ini)' : ' (Terlewat)'}',
                style: TextStyle(
                  color: daysLeft < 0 ? Colors.red : Colors.grey[600],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}