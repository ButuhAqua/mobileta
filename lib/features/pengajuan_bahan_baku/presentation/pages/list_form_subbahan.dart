// file: list_form_subbahan.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:apps_break/features/pengajuan_bahan_baku/presentation/pages/create_form_subbahan.dart';

import '../../data/datasources/pengajuan_remote_datasource.dart';
import '../../data/repositories/pengajuan_repository_impl.dart';
import '../../domain/entities/pengajuan.dart';
import '../../domain/usecases/get_pengajuan_list.dart';

class ListFormSubBahanPage extends StatefulWidget {
  const ListFormSubBahanPage({super.key});

  @override
  State<ListFormSubBahanPage> createState() => _ListFormSubBahanPageState();
}

class _ListFormSubBahanPageState extends State<ListFormSubBahanPage> {
  static const Color kPrimary = Color(0xFFD32F2F);
  static const Color kMuted = Color(0xFF616161);
  static const Color kBorder = Color(0xFFE0E0E0);

  String _query = '';
  String _statusFilter = 'Semua';

  late Future<List<Pengajuan>> _futurePengajuan;

  @override
  void initState() {
    super.initState();
    _futurePengajuan = _loadPengajuan();
  }

  Future<List<Pengajuan>> _loadPengajuan() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('Token tidak ditemukan, silakan login ulang');
    }

    final repository = PengajuanRepositoryImpl(
      PengajuanRemoteDataSource(),
    );

    final getPengajuanList = GetPengajuanList(repository);

    return getPengajuanList(token);
  }

  void _refresh() {
    setState(() {
      _futurePengajuan = _loadPengajuan();
    });
  }

  String _computedStatus(Pengajuan item) {
    switch (item.status) {
      case 'Menunggu':
        return 'Menunggu Persetujuan';
      case 'Diproses':
        return 'Diproses';
      case 'Selesai':
        return 'Selesai';
      case 'Ditolak':
        return 'Ditolak';
      default:
        return item.status;
    }
  }

  List<Pengajuan> _filtered(List<Pengajuan> data) {
    return data.where((item) {
      final q = _query.toLowerCase();

      final matchQuery = q.isEmpty ||
          item.title.toLowerCase().contains(q) ||
          item.id.toLowerCase().contains(q) ||
          item.requestType.toLowerCase().contains(q);

      final statusView = _computedStatus(item);
      final matchStatus =
          _statusFilter == 'Semua' || statusView == _statusFilter;

      return matchQuery && matchStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Pengajuan Bahan Baku'),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Cari ID / judul / tipe…',
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
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                children: [
                  _statusChip('Semua'),
                  const SizedBox(width: 8),
                  _statusChip('Menunggu Persetujuan'),
                  const SizedBox(width: 8),
                  _statusChip('Diproses'),
                  const SizedBox(width: 8),
                  _statusChip('Selesai'),
                  const SizedBox(width: 8),
                  _statusChip('Ditolak'),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Pengajuan>>(
                future: _futurePengajuan,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: kPrimary),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Terjadi error: ${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final data = _filtered(snapshot.data ?? []);

                  if (data.isEmpty) {
                    return const Center(
                      child: Text('Belum ada pengajuan'),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => _refresh(),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        final item = data[index];

                        return _FormDetailCard(
                          item: item,
                          statusView: _computedStatus(item),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: 220,
        height: 56,
        child: FloatingActionButton.extended(
          heroTag: 'buatForm',
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'Buat Pengajuan',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CreateFormSubBahanPage(
                  isAdmin: false,
                  currentUserName: 'Rafi Rahman',
                  currentUserEmail: 'rafi@example.com',
                ),
              ),
            );

            if (result == true && mounted) {
              _refresh();
            }
          },
        ),
      ),
    );
  }

  Widget _statusChip(String value) {
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
}

class _FormDetailCard extends StatelessWidget {
  const _FormDetailCard({
    required this.item,
    required this.statusView,
  });

  final Pengajuan item;
  final String statusView;

  static const Color kText = Color(0xFF212121);
  static const Color kMuted = Color(0xFF616161);
  static const Color kBorder = Color(0xFFE0E0E0);

  Color _statusColor(String status) {
    switch (status) {
      case 'Selesai':
        return const Color(0xFF2E7D32);
      case 'Ditolak':
        return const Color(0xFFC62828);
      case 'Diproses':
        return const Color(0xFF1565C0);
      case 'Menunggu Persetujuan':
        return const Color(0xFFEF6C00);
      default:
        return const Color(0xFF757575);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(statusView);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: Colors.white,
        elevation: 4,
        shadowColor: const Color(0x14000000),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: kText,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusView,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 14, color: kMuted),
                  const SizedBox(width: 6),
                  Text(
                    _formatDateLong(item.requestDate),
                    style: const TextStyle(color: kMuted, fontSize: 13),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.confirmation_number_rounded,
                      size: 14, color: kMuted),
                  const SizedBox(width: 6),
                  Text(
                    '#${item.id}',
                    style: const TextStyle(color: kMuted, fontSize: 13),
                  ),
                ],
              ),
              if (item.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(item.notes, style: const TextStyle(color: kText)),
              ],
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Identitas Pengajuan',
                child: _kvGrid([
                  ('Jenis Pengajuan', item.requestType),
                  ('Prioritas', item.priority),
                  ('Tanggal Pengajuan', _formatDate(item.requestDate)),
                ]),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Item Belanja',
                subtitle: 'Nama item, kategori, satuan, dan kuantitas',
                child: Column(
                  children: [
                    for (final itemBelanja in item.items) _itemRow(itemBelanja),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Lokasi Pembelian',
                child: _kvGrid([
                  (
                    'Beli di',
                    item.purchaseLocation == null ||
                            item.purchaseLocation!.isEmpty
                        ? '—'
                        : item.purchaseLocation!,
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemRow(PengajuanItem item) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          _kvGrid([
            ('Kategori', item.category),
            ('Satuan', item.uom),
            ('Qty', '${item.qty}'),
          ]),
        ],
      ),
    );
  }

  Widget _kvGrid(List<(String, String)> pairs) {
    return Column(
      children: [
        for (int i = 0; i < pairs.length; i++) ...[
          _kvRow(pairs[i].$1, pairs[i].$2),
          if (i != pairs.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _kvRow(String key, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(key, style: const TextStyle(color: kMuted)),
          const Spacer(),
          Flexible(
            child: Text(
              value.isEmpty ? '—' : value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: kText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateLong(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    this.subtitle,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  static const Color kBorder = Color(0xFFE0E0E0);
  static const Color kText = Color(0xFF212121);
  static const Color kMuted = Color(0xFF616161);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: const Color(0x14000000),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: kText,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: const TextStyle(color: kMuted, fontSize: 12),
              ),
            ],
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}