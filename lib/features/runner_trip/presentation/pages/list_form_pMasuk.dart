import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:apps_break/features/runner_trip/data/datasources/runner_trip_remote_datasource.dart';
import 'package:apps_break/features/runner_trip/data/repositories/runner_trip_repository_impl.dart';
import 'package:apps_break/features/runner_trip/domain/entities/runner_trip.dart';
import 'package:apps_break/features/runner_trip/domain/usecases/get_runner_trips.dart';
import 'package:apps_break/features/runner_trip/presentation/pages/create_form_pMasuk.dart';

class ListFormProdukMasukPage extends StatefulWidget {
  const ListFormProdukMasukPage({super.key});

  @override
  State<ListFormProdukMasukPage> createState() =>
      _ListFormProdukMasukPageState();
}

class _ListFormProdukMasukPageState extends State<ListFormProdukMasukPage> {
  static const Color kPrimary = Color(0xFFD32F2F);
  static const Color kMuted = Color(0xFF616161);
  static const Color kBorder = Color(0xFFE0E0E0);

  String _query = '';
  String _statusFilter = 'Semua';

  bool _isLoading = true;
  List<RunnerTrip> _data = [];

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final repository = RunnerTripRepositoryImpl(
        RunnerTripRemoteDatasource(),
      );

      final getRunnerTrips = GetRunnerTrips(repository);
      final trips = await getRunnerTrips(token);

      if (!mounted) return;

      setState(() {
        _data = trips;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal ambil laporan pulang: $e')),
      );
    }
  }

  List<RunnerTrip> get _filtered {
    return _data.where((trip) {
      final q = _query.toLowerCase();

      final matchQuery = q.isEmpty ||
          trip.id.toString().contains(q) ||
          trip.runnerName.toLowerCase().contains(q) ||
          trip.location.toLowerCase().contains(q) ||
          trip.notes.toLowerCase().contains(q) ||
          trip.items.any(
            (item) => item.productName.toLowerCase().contains(q),
          );

      final label = _statusLabel(trip.status);
      final matchStatus = _statusFilter == 'Semua' || label == _statusFilter;

      return matchQuery && matchStatus;
    }).toList();
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'ONGOING':
        return 'Perlu Pulang';
      case 'PENDING_RETURN':
        return 'Menunggu Approval';
      case 'FINISHED':
        return 'Selesai';
      case 'REJECTED_RETURN':
        return 'Ditolak';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ONGOING':
        return const Color(0xFFEF6C00);
      case 'FINISHED':
        return const Color(0xFF2E7D32);
      default:
        return kMuted;
    }
  }

  Future<void> _openReturnForm(RunnerTrip trip) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateFormProdukMasukPage(trip: trip),
      ),
    );

    if (result == true) {
      await _loadTrips();
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Pulang'),
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
                  hintText: 'Cari trip / gerobak / produk…',
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
                  _statusChip('Perlu Pulang'),
                  const SizedBox(width: 8),
                  _statusChip('Menunggu Approval'),
                  const SizedBox(width: 8),
                  _statusChip('Selesai'),
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
                      onRefresh: _loadTrips,
                      child: data.isEmpty
                          ? const Center(
                              child: Text('Belum ada laporan pulang'),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 100),
                              itemCount: data.length,
                              itemBuilder: (context, index) {
                                final trip = data[index];

                                return _RunnerReturnCard(
                                  trip: trip,
                                  statusLabel: _statusLabel(trip.status),
                                  statusColor: _statusColor(trip.status),
                                  onReturn: trip.status == 'ONGOING'
                                      ? () => _openReturnForm(trip)
                                      : null,
                                );
                              },
                            ),
                    ),
            ),
          ],
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
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: selected ? kPrimary : kBorder),
      ),
    );
  }
}

class _RunnerReturnCard extends StatelessWidget {
  const _RunnerReturnCard({
    required this.trip,
    required this.statusLabel,
    required this.statusColor,
    required this.onReturn,
  });

  final RunnerTrip trip;
  final String statusLabel;
  final Color statusColor;
  final VoidCallback? onReturn;

  static const Color kPrimary = Color(0xFFD32F2F);
  static const Color kText = Color(0xFF212121);
  static const Color kMuted = Color(0xFF616161);
  static const Color kBorder = Color(0xFFE0E0E0);

  @override
  Widget build(BuildContext context) {
    final totalTaken = trip.items.fold<int>(
      0,
      (total, item) => total + item.qtyTaken,
    );

    final totalSold = trip.items.fold<int>(
      0,
      (total, item) => total + item.qtySold,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: Colors.white,
        elevation: 4,
        shadowColor: const Color(0x14000000),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Trip #${trip.id} • ${trip.location}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
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
                      statusLabel,
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
              Text(
                'Runner: ${trip.runnerName.isEmpty ? '-' : trip.runnerName}',
                style: const TextStyle(color: kMuted),
              ),
              const SizedBox(height: 4),
              Text(
                'Berangkat: ${trip.departureAt == null ? '-' : _fmtDateTime(trip.departureAt!)}',
                style: const TextStyle(color: kMuted),
              ),
              const SizedBox(height: 8),
              Text(
                'Total dibawa: $totalTaken item'
                '${trip.status == 'FINISHED' ? ' • Terjual: $totalSold item' : ''}',
                style: const TextStyle(
                  color: kText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Detail Produk',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              for (final item in trip.items)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(item.productName)),
                      Text(
                        trip.status == 'FINISHED'
                            ? 'Bawa ${item.qtyTaken}, Sisa ${item.qtyReturned ?? 0}, Jual ${item.qtySold}'
                            : 'Bawa ${item.qtyTaken} ${item.uom}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              if (onReturn != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: onReturn,
                    icon: const Icon(Icons.move_to_inbox_rounded),
                    label: const Text(
                      'Buat Laporan Pulang',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _fmtDateTime(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}