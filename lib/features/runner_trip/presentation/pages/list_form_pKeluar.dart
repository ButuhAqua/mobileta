import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:apps_break/features/runner_trip/data/datasources/runner_trip_remote_datasource.dart';
import 'package:apps_break/features/runner_trip/data/repositories/runner_trip_repository_impl.dart';
import 'package:apps_break/features/runner_trip/domain/entities/runner_trip.dart';
import 'package:apps_break/features/runner_trip/domain/usecases/get_runner_trips.dart';
import 'package:apps_break/features/runner_trip/presentation/pages/create_form_pKeluar.dart';

class ListFormProdukKeluarPage extends StatefulWidget {
  const ListFormProdukKeluarPage({super.key});

  @override
  State<ListFormProdukKeluarPage> createState() =>
      _ListFormProdukKeluarPageState();
}

class _ListFormProdukKeluarPageState extends State<ListFormProdukKeluarPage> {
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
        SnackBar(content: Text('Gagal ambil laporan berangkat: $e')),
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

      final statusLabel = _statusLabel(trip.status);
      final matchStatus =
          _statusFilter == 'Semua' || statusLabel == _statusFilter;

      return matchQuery && matchStatus;
    }).toList();
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'PENDING_DEPARTURE':
        return 'Menunggu Approval';
      case 'ONGOING':
        return 'Sedang Jalan';
      case 'FINISHED':
        return 'Selesai';
      case 'REJECTED_DEPARTURE':
        return 'Ditolak';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PENDING_DEPARTURE':
        return const Color(0xFFEF6C00);
      case 'ONGOING':
        return const Color(0xFF1565C0);
      case 'FINISHED':
        return const Color(0xFF2E7D32);
      case 'REJECTED_DEPARTURE':
        return const Color(0xFFC62828);
      default:
        return kMuted;
    }
  }

  Future<void> _openCreate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateFormProdukKeluarPage(),
      ),
    );

    if (result == true) {
      await _loadTrips();
    } else {
      await _loadTrips();
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Berangkat'),
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
                  hintText: 'Cari runner / gerobak / produk…',
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
                    borderSide: const BorderSide(
                      color: kPrimary,
                      width: 1.2,
                    ),
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
                  _statusChip('Menunggu Approval'),
                  const SizedBox(width: 8),
                  _statusChip('Sedang Jalan'),
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
                              child: Text('Belum ada laporan berangkat'),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 100),
                              itemCount: data.length,
                              itemBuilder: (context, index) {
                                return _RunnerTripCard(
                                  trip: data[index],
                                  statusLabel:
                                      _statusLabel(data[index].status),
                                  statusColor:
                                      _statusColor(data[index].status),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: 260,
        height: 56,
        child: FloatingActionButton.extended(
          heroTag: 'buatFormProdukKeluar',
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'Buat Laporan Berangkat',
            style: TextStyle(fontWeight: FontWeight.w700),
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

class _RunnerTripCard extends StatelessWidget {
  const _RunnerTripCard({
    required this.trip,
    required this.statusLabel,
    required this.statusColor,
  });

  final RunnerTrip trip;
  final String statusLabel;
  final Color statusColor;

  static const Color kText = Color(0xFF212121);
  static const Color kMuted = Color(0xFF616161);
  static const Color kBorder = Color(0xFFE0E0E0);

  @override
  Widget build(BuildContext context) {
    final totalTaken = trip.items.fold<int>(
      0,
      (total, item) => total + item.qtyTaken,
    );

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
                      'Trip #${trip.id} • ${trip.location}',
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
              Row(
                children: [
                  const Icon(
                    Icons.person_rounded,
                    size: 14,
                    color: kMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      trip.runnerName.isEmpty ? '-' : trip.runnerName,
                      style: const TextStyle(color: kMuted, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: kMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    trip.departureAt == null
                        ? '-'
                        : _fmtDateTime(trip.departureAt!),
                    style: const TextStyle(color: kMuted, fontSize: 13),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.inventory_2_rounded,
                    size: 14,
                    color: kMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$totalTaken item dibawa',
                    style: const TextStyle(color: kMuted, fontSize: 13),
                  ),
                ],
              ),
              if (trip.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  trip.notes,
                  style: const TextStyle(color: kText),
                ),
              ],
              const SizedBox(height: 12),
              const Text(
                'Detail Produk Dibawa',
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
                      Expanded(
                        child: Text(
                          item.productName,
                          style: const TextStyle(color: kText),
                        ),
                      ),
                      Text(
                        '${item.qtyTaken} ${item.uom}',
                        style: const TextStyle(
                          color: kText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDateTime(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}