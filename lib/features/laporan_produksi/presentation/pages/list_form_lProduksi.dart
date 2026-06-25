import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/production_remote_datasource.dart';
import '../../data/repositories/production_repository_impl.dart';
import '../../domain/entities/production_report.dart';
import '../../domain/usecases/get_production_reports.dart';
import 'create_form_lProduksi.dart';

class ListFormLProduksiPage extends StatefulWidget {
  const ListFormLProduksiPage({super.key});

  @override
  State<ListFormLProduksiPage> createState() => _ListFormLProduksiPageState();
}

class _ListFormLProduksiPageState extends State<ListFormLProduksiPage> {
  static const Color kPrimary = Color(0xFFD32F2F);
  static const Color kBorder = Color(0xFFE0E0E0);

  String _query = '';
  String _statusFilter = 'Semua';

  bool _isLoading = true;
  List<ProductionReport> _data = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Token tidak ditemukan, silakan login ulang');
      }

      final repository = ProductionRepositoryImpl(
        ProductionRemoteDatasource(),
      );

      final getReports = GetProductionReports(repository);
      final reports = await getReports(token);

      if (!mounted) return;

      setState(() {
        _data = reports;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal ambil laporan produksi: $e')),
      );
    }
  }

  List<ProductionReport> get _filtered {
    return _data.where((e) {
      final q = _query.toLowerCase();

      final matchQ = q.isEmpty ||
          e.reportNumber.toLowerCase().contains(q) ||
          e.notes.toLowerCase().contains(q) ||
          e.finishedProducts.any(
            (p) => p.productName.toLowerCase().contains(q),
          ) ||
          e.materialUsages.any(
            (m) => m.rawMaterialName.toLowerCase().contains(q),
          );

      final statusLabel = _statusLabel(e.status);
      final matchS =
          _statusFilter == 'Semua' || statusLabel == _statusFilter;

      return matchQ && matchS;
    }).toList();
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'Submitted':
        return 'Menunggu';
      case 'Approved':
        return 'Disetujui';
      case 'Rejected':
        return 'Ditolak';
      case 'Draft':
        return 'Draft';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (_statusLabel(status)) {
      case 'Disetujui':
        return const Color(0xFF2E7D32);
      case 'Ditolak':
        return const Color(0xFFC62828);
      case 'Draft':
        return Colors.grey;
      default:
        return const Color(0xFFEF6C00);
    }
  }

  Future<void> _openCreate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateFormLProduksiPage(),
      ),
    );

    if (result == true) {
      await _loadReports();
    } else {
      await _loadReports();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Produksi'),
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
                hintText: 'Cari nomor laporan / produk / bahan…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: kBorder),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              children: [
                _statusChip('Semua'),
                const SizedBox(width: 8),
                _statusChip('Menunggu'),
                const SizedBox(width: 8),
                _statusChip('Disetujui'),
                const SizedBox(width: 8),
                _statusChip('Ditolak'),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: kPrimary),
                  )
                : RefreshIndicator(
                    color: kPrimary,
                    onRefresh: _loadReports,
                    child: filtered.isEmpty
                        ? const Center(
                            child: Text('Belum ada laporan produksi'),
                          )
                        : ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              return _ProduksiCard(
                                item: filtered[i],
                                statusLabel:
                                    _statusLabel(filtered[i].status),
                                statusColor:
                                    _statusColor(filtered[i].status),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: 260,
        height: 56,
        child: FloatingActionButton.extended(
          backgroundColor: kPrimary,
          icon: const Icon(Icons.add),
          label: const Text(
            'Buat Laporan Produksi',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          onPressed: _openCreate,
        ),
      ),
    );
  }

  Widget _statusChip(String value) {
    final selected = _statusFilter == value;

    return ChoiceChip(
      label: Text(value),
      selected: selected,
      selectedColor: kPrimary.withOpacity(.12),
      onSelected: (_) => setState(() => _statusFilter = value),
    );
  }
}

class _ProduksiCard extends StatelessWidget {
  const _ProduksiCard({
    required this.item,
    required this.statusLabel,
    required this.statusColor,
  });

  final ProductionReport item;
  final String statusLabel;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.reportNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Tanggal: ${_fmtDate(item.productionDate)}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              const Text(
                'Bahan dipakai:',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              for (final material in item.materialUsages)
                Text(
                  '- ${material.rawMaterialName} • ${material.qty} ${material.uom}',
                ),
              const SizedBox(height: 10),
              const Text(
                'Produk jadi:',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              for (final product in item.finishedProducts)
                Text(
                  '- ${product.productName} • ${product.qty} ${product.uom}',
                ),
              if (item.notes.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(item.notes),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}