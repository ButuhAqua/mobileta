import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:apps_break/features/approval/data/datasources/approval_remote_datasource.dart';
import 'package:apps_break/features/approval/data/repositories/approval_repository_impl.dart';

import 'package:apps_break/features/approval/domain/usecases/approve_raw_material_request.dart';
import 'package:apps_break/features/approval/domain/usecases/reject_raw_material_request.dart';
import 'package:apps_break/features/approval/domain/usecases/approve_production_report.dart';
import 'package:apps_break/features/approval/domain/usecases/reject_production_report.dart';
import 'package:apps_break/features/approval/domain/usecases/approve_departure_trip.dart';
import 'package:apps_break/features/approval/domain/usecases/reject_departure_trip.dart';
import 'package:apps_break/features/approval/domain/usecases/approve_return_trip.dart';
import 'package:apps_break/features/approval/domain/usecases/reject_return_trip.dart';
import 'package:apps_break/features/approval/domain/usecases/complete_raw_material_request.dart';
import 'package:apps_break/features/approval/domain/usecases/complete_production_report.dart';

import 'package:apps_break/features/pengajuan_bahan_baku/data/datasources/pengajuan_remote_datasource.dart';
import 'package:apps_break/features/pengajuan_bahan_baku/data/repositories/pengajuan_repository_impl.dart';
import 'package:apps_break/features/pengajuan_bahan_baku/domain/entities/pengajuan.dart';
import 'package:apps_break/features/pengajuan_bahan_baku/domain/usecases/get_pengajuan_list.dart';

import 'package:apps_break/features/laporan_produksi/data/datasources/production_remote_datasource.dart';
import 'package:apps_break/features/laporan_produksi/data/repositories/production_repository_impl.dart';
import 'package:apps_break/features/laporan_produksi/domain/entities/production_report.dart';
import 'package:apps_break/features/laporan_produksi/domain/usecases/get_production_reports.dart';

import 'package:apps_break/features/runner_trip/data/datasources/runner_trip_remote_datasource.dart';
import 'package:apps_break/features/runner_trip/data/repositories/runner_trip_repository_impl.dart';
import 'package:apps_break/features/runner_trip/domain/entities/runner_trip.dart';
import 'package:apps_break/features/runner_trip/domain/usecases/get_runner_trips.dart';

class ApprovalPage extends StatefulWidget {
  const ApprovalPage({super.key});

  @override
  State<ApprovalPage> createState() => _ApprovalPageState();
}

class _ApprovalPageState extends State<ApprovalPage> {
  static const Color kPrimary = Color(0xFFD32F2F);
  static const Color kText = Color(0xFF212121);
  static const Color kMuted = Color(0xFF616161);
  static const Color kBorder = Color(0xFFE0E0E0);

  int _selectedTab = 0;
  String _statusFilter = 'Semua';

  bool _isLoading = true;
  bool _isProcessing = false;

  List<Pengajuan> _pengajuanData = [];
  List<ProductionReport> _productionData = [];
  List<RunnerTrip> _runnerTripData = [];

  @override
  void initState() {
    super.initState();
    _loadAllApprovals();
  }

  Future<void> _loadAllApprovals() async {
    setState(() => _isLoading = true);

    try {
      await Future.wait([
        _loadPengajuanApprovals(),
        _loadProductionApprovals(),
        _loadRunnerTripApprovals(),
      ]);

      if (!mounted) return;

      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal ambil approval: $e')),
      );
    }
  }

  Future<void> _loadPengajuanApprovals() async {
    final token = await _getToken();

    final repository = PengajuanRepositoryImpl(
      PengajuanRemoteDataSource(),
    );

    final getPengajuanList = GetPengajuanList(repository);
    final result = await getPengajuanList(token);

    _pengajuanData = result;
  }

  Future<void> _loadProductionApprovals() async {
    final token = await _getToken();

    final repository = ProductionRepositoryImpl(
      ProductionRemoteDatasource(),
    );

    final getProductionReports = GetProductionReports(repository);
    final result = await getProductionReports(token);

    _productionData = result;
  }

  Future<void> _loadRunnerTripApprovals() async {
    final token = await _getToken();

    final repository = RunnerTripRepositoryImpl(
      RunnerTripRemoteDatasource(),
    );

    final getRunnerTrips = GetRunnerTrips(repository);
    final result = await getRunnerTrips(token);

    _runnerTripData = result;
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('Token tidak ditemukan');
    }

    return token;
  }

  ApprovalRepositoryImpl _approvalRepository() {
    return ApprovalRepositoryImpl(
      ApprovalRemoteDataSource(),
    );
  }

  String _approvalGroup(String rawStatus) {
    final status = rawStatus.toLowerCase();

    if (
        status == 'menunggu' ||
        status == 'submitted' ||
        status == 'pending' ||
        status == 'pending_departure' ||
        status == 'pending_return'
    ) {
      return 'Menunggu';
    }

    if (
        status == 'disetujui' ||
        status == 'approved'
    ) {
      return 'Disetujui';
    }

    if (
        status == 'selesai' ||
        status == 'finished' ||
        status == 'ongoing'
    ) {
      return 'Selesai';
    }

    if (
        status == 'ditolak' ||
        status == 'rejected' ||
        status == 'rejected_departure' ||
        status == 'rejected_return'
    ) {
      return 'Ditolak';
    }

    return rawStatus;
  }

  bool _matchesFilter(String rawStatus) {
    if (_statusFilter == 'Semua') return true;
    return _approvalGroup(rawStatus) == _statusFilter;
  }

  bool _isPengajuanPending(Pengajuan item) {
    return _approvalGroup(item.status) == 'Menunggu';
  }

  bool _isPengajuanApproved(Pengajuan item) {
    return _approvalGroup(item.status) == 'Disetujui';
  }

  bool _isProductionPending(ProductionReport item) {
    return _approvalGroup(item.status) == 'Menunggu';
  }

  bool _isProductionApproved(ProductionReport item) {
    return _approvalGroup(item.status) == 'Disetujui';
  }

  bool _isRunnerPending(RunnerTrip trip) {
    return trip.status == 'PENDING_DEPARTURE' ||
        trip.status == 'PENDING_RETURN';
  }

  List<Pengajuan> get _filteredPengajuan {
    return _pengajuanData.where((e) => _matchesFilter(e.status)).toList();
  }

  List<ProductionReport> get _filteredProduction {
    return _productionData.where((e) => _matchesFilter(e.status)).toList();
  }

  List<RunnerTrip> get _filteredRunner {
    return _runnerTripData.where((e) => _matchesFilter(e.status)).toList();
  }

  int get _pendingCount {
    if (_selectedTab == 0) {
      return _pengajuanData.where(_isPengajuanPending).length;
    }

    if (_selectedTab == 1) {
      return _productionData.where(_isProductionPending).length;
    }

    return _runnerTripData.where(_isRunnerPending).length;
  }

  Future<void> _approvePengajuan(Pengajuan item) async {
    await _processApproval(
      action: () async {
        final token = await _getToken();

        final approve = ApproveRawMaterialRequest(
          _approvalRepository(),
        );

        await approve(
          token: token,
          requestId: int.parse(item.id),
        );
      },
      successMessage: 'Pengajuan bahan baku disetujui',
    );
  }
  Future<void> _completePengajuan(
    Pengajuan item,
  ) async {
    final form = await _showCompletePengajuanDialog(item);
    if (form == null) return;

    await _processApproval(
      action: () async {
        final token = await _getToken();
        final complete = CompleteRawMaterialRequest(_approvalRepository());
        await complete(
          token: token,
          requestId: int.parse(item.id),
          supplier: form['supplier'],
          batchNotes: form['batch_notes'],
          location: form['location'], // ✅ perbaiki di sini
          items: form['items'],
        );
      },
      successMessage: 'Pengajuan bahan baku selesai',
    );
  }

  Future<void> _rejectPengajuan(Pengajuan item) async {
    final reason = await _showRejectDialog();

    if (reason == null) return;

    await _processApproval(
      action: () async {
        final token = await _getToken();

        final reject = RejectRawMaterialRequest(
          _approvalRepository(),
        );

        await reject(
          token: token,
          requestId: int.parse(item.id),
          reason: reason,
        );
      },
      successMessage: 'Pengajuan bahan baku ditolak',
    );
  }
  
  Future<Map<String, dynamic>?> _showCompletePengajuanDialog(
    Pengajuan item,
  ) async {

    final supplierC =
        TextEditingController();

    final notesC =
        TextEditingController();

    final locationC = 
        TextEditingController();

    final expiredDates =
        <int, DateTime>{};

    return await showDialog<
        Map<String, dynamic>?>(
      context: context,

      builder: (context) {

        return StatefulBuilder(
          builder: (context, setModalState) {

            return AlertDialog(

              title: const Text(
                'Selesaikan Pengajuan',
              ),

              content: SizedBox(
                width: double.maxFinite,

                child: SingleChildScrollView(

                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,

                    children: [

                      // =====================================
                      // SUPPLIER
                      // =====================================

                      TextField(
                        controller: supplierC,

                        decoration:
                            const InputDecoration(
                          labelText:
                              'Supplier',
                          border:
                              OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      // LOKASI PEMBELIAN (BARU)
                      TextField(
                        controller: locationC, // ← PAKAI CONTROLLER
                        decoration: const InputDecoration(
                          labelText: 'Lokasi Pembelian',
                          hintText: 'Toko atau tempat pembelian',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // =====================================
                      // NOTES
                      // =====================================

                      TextField(
                        controller: notesC,
                        maxLines: 3,

                        decoration:
                            const InputDecoration(
                          labelText:
                              'Catatan Batch',
                          border:
                              OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // =====================================
                      // EXPIRED DATE ITEMS
                      // =====================================

                      Align(
                        alignment:
                            Alignment.centerLeft,

                        child: Text(
                          'Tanggal Expired',
                          style:
                              Theme.of(context)
                                  .textTheme
                                  .titleMedium,
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      ...item.items.map((e) {

                        final selectedDate =
                            expiredDates[e.rawMaterialId!];

                        return Container(

                          margin:
                              const EdgeInsets.only(
                            bottom: 12,
                          ),

                          padding:
                              const EdgeInsets.all(
                            12,
                          ),

                          decoration:
                              BoxDecoration(
                            border: Border.all(
                              color:
                                  Colors.grey.shade300,
                            ),

                            borderRadius:
                                BorderRadius.circular(
                              12,
                            ),
                          ),

                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [

                              Text(
                                e.name,
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),

                              const SizedBox(
                                height: 6,
                              ),

                              Text(
                                '${e.qty} ${e.uom}',
                              ),

                              const SizedBox(
                                height: 10,
                              ),

                              SizedBox(
                                width:
                                    double.infinity,

                                child:
                                    OutlinedButton.icon(

                                  onPressed:
                                      () async {

                                    final picked =
                                        await showDatePicker(

                                      context:
                                          context,

                                      initialDate:
                                          DateTime
                                              .now(),

                                      firstDate:
                                          DateTime
                                              .now(),

                                      lastDate:
                                          DateTime(
                                        2100,
                                      ),
                                    );

                                    if (picked ==
                                        null) {
                                      return;
                                    }

                                    setModalState(() {
                                      expiredDates[
                                          e.rawMaterialId!] = picked;
                                    });
                                  },

                                  icon: const Icon(
                                    Icons
                                        .calendar_month,
                                  ),

                                  label: Text(
                                    selectedDate ==
                                            null
                                        ? 'Pilih Expired Date'
                                        : '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              actions: [

                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      null,
                    );
                  },

                  child:
                      const Text('Batal'),
                ),

                ElevatedButton(

                  onPressed: () {

                    for (final i
                        in item.items) {

                      if (expiredDates[
                              i.rawMaterialId!] ==
                          null) {

                        ScaffoldMessenger.of(
                                context)
                            .showSnackBar(

                          SnackBar(
                            content: Text(
                              'Expired date ${i.name} wajib diisi',
                            ),
                          ),
                        );

                        return;
                      }
                    }

                    Navigator.pop(context, {
                      'supplier': supplierC.text.trim(),
                      'batch_notes': notesC.text.trim(),
                      'location': locationC.text.trim(), // ← PASTIKAN KUTIPANNYA BENAR
                      'items': item.items.map((e) {
                        final d = expiredDates[e.rawMaterialId!]!;
                        return {
                          'raw_material_id': e.rawMaterialId,
                          'expired_date': '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
                        };
                      }).toList(),
                    });
                  },

                  child:
                      const Text(
                    'Simpan',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>?>
      _showCompleteProductionDialog(
    ProductionReport item,
  ) async {

    final expiredDates =
        <int, DateTime>{};

    return await showDialog<
        Map<String, dynamic>?>(
      context: context,

      builder: (context) {

        return StatefulBuilder(
          builder: (
            context,
            setModalState,
          ) {

            return AlertDialog(

              title: const Text(
                'Selesaikan Produksi',
              ),

              content: SizedBox(
                width: double.maxFinite,

                child:
                    SingleChildScrollView(

                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,

                    children: [

                      Align(
                        alignment:
                            Alignment.centerLeft,

                        child: Text(
                          'Expired Produk Jadi',

                          style:
                              Theme.of(context)
                                  .textTheme
                                  .titleMedium,
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      ...item.finishedProducts
                          .map((e) {

                        final selectedDate =
                            expiredDates[
                                e.productId];

                        return Container(

                          margin:
                              const EdgeInsets.only(
                            bottom: 12,
                          ),

                          padding:
                              const EdgeInsets.all(
                            12,
                          ),

                          decoration:
                              BoxDecoration(
                            border: Border.all(
                              color:
                                  Colors.grey
                                      .shade300,
                            ),

                            borderRadius:
                                BorderRadius.circular(
                              12,
                            ),
                          ),

                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [

                              Text(
                                e.productName,

                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),

                              const SizedBox(
                                height: 6,
                              ),

                              Text(
                                '${e.qty} ${e.uom}',
                              ),

                              const SizedBox(
                                height: 10,
                              ),

                              SizedBox(
                                width:
                                    double.infinity,

                                child:
                                    OutlinedButton.icon(

                                  onPressed:
                                      () async {

                                    final picked =
                                        await showDatePicker(

                                      context:
                                          context,

                                      initialDate:
                                          DateTime
                                              .now(),

                                      firstDate:
                                          DateTime
                                              .now(),

                                      lastDate:
                                          DateTime(
                                        2100,
                                      ),
                                    );

                                    if (picked ==
                                        null) {
                                      return;
                                    }

                                    setModalState(() {

                                      expiredDates[
                                          e.productId] = picked;
                                    });
                                  },

                                  icon:
                                      const Icon(
                                    Icons
                                        .calendar_month,
                                  ),

                                  label: Text(

                                    selectedDate ==
                                            null
                                        ? 'Pilih Expired Date'

                                        : '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              actions: [

                TextButton(
                  onPressed: () {

                    Navigator.pop(
                      context,
                      null,
                    );
                  },

                  child:
                      const Text(
                    'Batal',
                  ),
                ),

                ElevatedButton(

                  onPressed: () {

                    for (final i
                        in item
                            .finishedProducts) {

                      if (expiredDates[
                              i.productId] ==
                          null) {

                        ScaffoldMessenger.of(
                                context)
                            .showSnackBar(

                          SnackBar(
                            content: Text(
                              'Expired ${i.productName} wajib diisi',
                            ),
                          ),
                        );

                        return;
                      }
                    }

                    Navigator.pop(
                      context,

                      {
                        'items':
                            item.finishedProducts
                                .map((e) {

                          final d =
                              expiredDates[
                                  e.productId]!;

                          return {

                            'product_id':
                                e.productId,

                            'expired_date':
                                '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
                          };

                        }).toList(),
                      },
                    );
                  },

                  child:
                      const Text(
                    'Simpan',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _approveProduction(ProductionReport item) async {
    await _processApproval(
      action: () async {
        final token = await _getToken();

        final approve = ApproveProductionReport(
          _approvalRepository(),
        );

        await approve(
          token: token,
          reportId: int.parse(item.id),
        );
      },
      successMessage: 'Laporan produksi disetujui',
    );
  }

  Future<void> _completeProduction(
    ProductionReport item,
  ) async {

    final form =
        await _showCompleteProductionDialog(
      item,
    );

    if (form == null) return;

    await _processApproval(
      action: () async {

        final token = await _getToken();

        final complete =
            CompleteProductionReport(
          _approvalRepository(),
        );

        await complete(
          token: token,

          reportId: int.parse(item.id),

          items: form['items'],
        );
      },

      successMessage:
          'Laporan produksi selesai',
    );
  }

  Future<void> _rejectProduction(ProductionReport item) async {
    final reason = await _showRejectDialog();

    if (reason == null) return;

    await _processApproval(
      action: () async {
        final token = await _getToken();

        final reject = RejectProductionReport(
          _approvalRepository(),
        );

        await reject(
          token: token,
          reportId: int.parse(item.id),
          reason: reason,
        );
      },
      successMessage: 'Laporan produksi ditolak',
    );
  }

  Future<void> _approveRunnerTrip(RunnerTrip trip) async {
    await _processApproval(
      action: () async {
        final token = await _getToken();

        if (trip.status == 'PENDING_DEPARTURE') {
          final approve = ApproveDepartureTrip(
            _approvalRepository(),
          );

          await approve(
            token: token,
            tripId: trip.id,
          );
        }

        if (trip.status == 'PENDING_RETURN') {
          final approve = ApproveReturnTrip(
            _approvalRepository(),
          );

          await approve(
            token: token,
            tripId: trip.id,
          );
        }
      },
      successMessage: 'Runner trip selesai',
    );
  }

  Future<void> _rejectRunnerTrip(RunnerTrip trip) async {
    final reason = await _showRejectDialog();

    if (reason == null) return;

    await _processApproval(
      action: () async {
        final token = await _getToken();

        if (trip.status == 'PENDING_DEPARTURE') {
          final reject = RejectDepartureTrip(
            _approvalRepository(),
          );

          await reject(
            token: token,
            tripId: trip.id,
            reason: reason,
          );
        }

        if (trip.status == 'PENDING_RETURN') {
          final reject = RejectReturnTrip(
            _approvalRepository(),
          );

          await reject(
            token: token,
            tripId: trip.id,
            reason: reason,
          );
        }
      },
      successMessage: 'Runner trip ditolak',
    );
  }

  Future<void> _processApproval({
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      await action();

      await _loadAllApprovals();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal proses approval: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<String?> _showRejectDialog() async {
    final reasonC = TextEditingController();

    final result = await showDialog<String?>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Tolak Approval'),
          content: TextField(
            controller: reasonC,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Alasan penolakan',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, reasonC.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tolak'),
            ),
          ],
        );
      },
    );

    reasonC.dispose();
    return result;
  }

  String _emptyMessage() {
    if (_selectedTab == 0) {
      return 'Tidak ada riwayat approval pengajuan bahan';
    }

    if (_selectedTab == 1) {
      return 'Tidak ada riwayat approval laporan produksi';
    }

    return 'Tidak ada riwayat approval runner trip';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: const Text('Approval Manager'),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: kPrimary),
            )
          : RefreshIndicator(
              color: kPrimary,
              onRefresh: _loadAllApprovals,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  _tabSelector(),
                  const SizedBox(height: 12),
                  _statusFilterChips(),
                  const SizedBox(height: 14),
                  Text(
                    'Menunggu approval: $_pendingCount',
                    style: const TextStyle(
                      color: kMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_selectedTab == 0)
                    _buildPengajuanList()
                  else if (_selectedTab == 1)
                    _buildProductionList()
                  else
                    _buildRunnerTripList(),
                ],
              ),
            ),
    );
  }

  Widget _tabSelector() {
    return Row(
      children: [
        Expanded(
          child: _tabButton(
            title: 'Pengajuan',
            selected: _selectedTab == 0,
            onTap: () => setState(() {
              _selectedTab = 0;
              _statusFilter = 'Semua';
            }),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _tabButton(
            title: 'Produksi',
            selected: _selectedTab == 1,
            onTap: () => setState(() {
              _selectedTab = 1;
              _statusFilter = 'Semua';
            }),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _tabButton(
            title: 'Runner',
            selected: _selectedTab == 2,
            onTap: () => setState(() {
              _selectedTab = 2;
              _statusFilter = 'Semua';
            }),
          ),
        ),
      ],
    );
  }

  Widget _tabButton({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: selected ? kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kPrimary),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: selected ? Colors.white : kPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusFilterChips() {
    final filters = [
      'Semua',
      'Menunggu',
      'Disetujui',
      'Selesai',
      'Ditolak',
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final value = filters[index];
          final selected = _statusFilter == value;

          return ChoiceChip(
            label: Text(value),
            selected: selected,
            onSelected: (_) => setState(() => _statusFilter = value),
            selectedColor: kPrimary.withOpacity(.12),
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: selected ? kPrimary : kMuted,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: selected ? kPrimary : kBorder,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPengajuanList() {
    final data = _filteredPengajuan;

    if (data.isEmpty) {

      return Padding(
        padding: const EdgeInsets.only(top: 120),
        child: Center(
          child: Text(_emptyMessage()),
        ),
      );
    }

    return Column(
      children: data.map<Widget>((item) {

        final isPending =
            _isPengajuanPending(item);

        final isApproved =
            _isPengajuanApproved(item);

        return _PengajuanApprovalCard(
          item: item,
          statusGroup:
              _approvalGroup(item.status),

          originalStatus: item.status,

          isProcessing: _isProcessing,

          canApproveReject: isPending,

          canComplete: isApproved,

          onApprove: () =>
              _approvePengajuan(item),

          onReject: () =>
              _rejectPengajuan(item),

          onComplete: () =>
              _completePengajuan(item),
        );

      }).toList(),
    );
  }

  Widget _buildProductionList() {
    final data = _filteredProduction;

    if (data.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 120),
        child: Center(
          child: Text(_emptyMessage()),
        ),
      );
    }

    return Column(
      children: data.map<Widget>((item) {

        final isPending =
            _isProductionPending(item);

        final isApproved =
            _isProductionApproved(item);

        return _ProductionApprovalCard(
          item: item,

          statusGroup:
              _approvalGroup(item.status),

          originalStatus: item.status,

          isProcessing: _isProcessing,

          canApproveReject: isPending,

          canComplete: isApproved,

          onApprove: () =>
              _approveProduction(item),

          onReject: () =>
              _rejectProduction(item),

          onComplete: () =>
              _completeProduction(item),
        );

      }).toList(),
    );
  }

  Widget _buildRunnerTripList() {
    final data = _filteredRunner;

    if (data.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 120),
        child: Center(
          child: Text(_emptyMessage()),
        ),
      );
    }

    return Column(
      children: data.map<Widget>((trip) {
        final canAction = _isRunnerPending(trip);

        return _RunnerTripApprovalCard(
          trip: trip,
          statusGroup: _approvalGroup(trip.status),
          originalStatus: trip.status,
          isProcessing: _isProcessing,
          canAction: canAction,
          onApprove: () => _approveRunnerTrip(trip),
          onReject: () => _rejectRunnerTrip(trip),
        );
      }).toList(),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
  });

  final String label;

  Color get color {
    switch (label) {
      case 'Selesai':
        return const Color(0xFF2E7D32);
      case 'Ditolak':
        return const Color(0xFFC62828);
      case 'Menunggu':
        return const Color(0xFFEF6C00);
      default:
        return const Color(0xFF757575);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PengajuanApprovalCard extends StatelessWidget {
  const _PengajuanApprovalCard({
    required this.item,
    required this.statusGroup,
    required this.originalStatus,
    required this.isProcessing,

    required this.canApproveReject,
    required this.canComplete,

    required this.onApprove,
    required this.onReject,
    required this.onComplete,

    super.key,
  });

  final Pengajuan item;
  final String statusGroup;
  final String originalStatus;
  final bool isProcessing;
  final bool canApproveReject;
  final bool canComplete;
  
  final VoidCallback onApprove;
  final VoidCallback onComplete;
  final VoidCallback onReject;

  static const Color kText = Color(0xFF212121);
  static const Color kMuted = Color(0xFF616161);

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: item.title,
            statusGroup: statusGroup,
          ),
          const SizedBox(height: 6),
          Text(
            '${item.requestType} • ${item.priority}',
            style: const TextStyle(color: kMuted),
          ),
          const SizedBox(height: 6),
          Text(
            'Tanggal: ${_fmtDate(item.requestDate)}',
            style: const TextStyle(color: kMuted),
          ),
          if ((item.purchaseLocation ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Lokasi beli: ${item.purchaseLocation ?? '-'}',
              style: const TextStyle(color: kMuted),
            ),
          ],
          if (item.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(item.notes),
          ],
          const SizedBox(height: 12),
          const Text(
            'Detail Item',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          for (final detail in item.items)
            _MiniDetailRow(
              title: detail.name,
              trailing: '${detail.qty} ${detail.uom}',
            ),
          if (canApproveReject) ...[
            const SizedBox(height: 12),

            _ActionButtons(
              isProcessing: isProcessing,
              onApprove: onApprove,
              onReject: onReject,
            ),
          ],

          if (canComplete) ...[
            const SizedBox(height: 12),

            _CompleteButton(
              isProcessing: isProcessing,
              onComplete: onComplete,
            ),
          ],
        ],
      ),
    );
  }

  static String _fmtDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _ProductionApprovalCard extends StatelessWidget {
  const _ProductionApprovalCard({
    required this.item,
    required this.statusGroup,
    required this.originalStatus,
    required this.isProcessing,

    required this.canApproveReject,
    required this.canComplete,

    required this.onApprove,
    required this.onReject,
    required this.onComplete,

    super.key,
  });

  final ProductionReport item;
  final String statusGroup;
  final String originalStatus;
  final bool isProcessing;
  final bool canApproveReject;
  final bool canComplete;

  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onComplete;

  static const Color kMuted = Color(0xFF616161);

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: item.reportNumber,
            statusGroup: statusGroup,
          ),
          const SizedBox(height: 6),
          Text(
            'Tanggal: ${item.productionDate}',
            style: const TextStyle(color: kMuted),
          ),
          if (item.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(item.notes),
          ],
          const SizedBox(height: 12),
          const Text(
            'Bahan Dipakai',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          for (final usage in item.materialUsages)
            _MiniDetailRow(
              title: usage.rawMaterialName,
              trailing: '${usage.qty} ${usage.uom}',
            ),
          const SizedBox(height: 12),
          const Text(
            'Produk Jadi',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          for (final product in item.finishedProducts)
            _MiniDetailRow(
              title: product.productName,
              trailing: '${product.qty} ${product.uom}',
            ),
          if (canApproveReject) ...[
            const SizedBox(height: 12),

            _ActionButtons(
              isProcessing: isProcessing,
              onApprove: onApprove,
              onReject: onReject,
            ),
          ],

          if (canComplete) ...[
            const SizedBox(height: 12),

            _CompleteButton(
              isProcessing: isProcessing,
              onComplete: onComplete,
            ),
          ],
        ],
      ),
    );
  }
}

class _RunnerTripApprovalCard extends StatelessWidget {
  const _RunnerTripApprovalCard({
    required this.trip,
    required this.statusGroup,
    required this.originalStatus,
    required this.isProcessing,
    required this.canAction,
    required this.onApprove,
    required this.onReject,
    super.key,
  });

  final RunnerTrip trip;
  final String statusGroup;
  final String originalStatus;
  final bool isProcessing;
  final bool canAction;

  final VoidCallback onApprove;
  final VoidCallback onReject;

  static const Color kMuted = Color(0xFF616161);

  String get statusLabel {
    if (trip.status == 'PENDING_DEPARTURE') {
      return 'Menunggu Approval Berangkat';
    }

    if (trip.status == 'PENDING_RETURN') {
      return 'Menunggu Approval Pulang';
    }

    if (trip.status == 'ONGOING') {
      return 'Berangkat Disetujui';
    }

    if (trip.status == 'FINISHED') {
      return 'Pulang Selesai';
    }

    if (trip.status == 'REJECTED_DEPARTURE') {
      return 'Berangkat Ditolak';
    }

    if (trip.status == 'REJECTED_RETURN') {
      return 'Pulang Ditolak';
    }

    return trip.status;
  }

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: 'Trip #${trip.id} • ${trip.location}',
            statusGroup: statusLabel,
          ),
          const SizedBox(height: 6),
          Text(
            'Runner: ${trip.runnerName.isEmpty ? '-' : trip.runnerName}',
            style: const TextStyle(color: kMuted),
          ),
          if (trip.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(trip.notes),
          ],
          const SizedBox(height: 12),
          const Text(
            'Detail Produk',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          for (final item in trip.items)
            _MiniDetailRow(
              title: item.productName,
              trailing: trip.status == 'PENDING_RETURN' ||
                      trip.status == 'FINISHED' ||
                      trip.status == 'REJECTED_RETURN'
                  ? 'Bawa ${item.qtyTaken}, Sisa ${item.qtyReturned ?? 0}, Jual ${item.qtySold}'
                  : 'Bawa ${item.qtyTaken} ${item.uom}',
            ),
          if (canAction) ...[
            const SizedBox(height: 12),

            _ActionButtons(
              isProcessing: isProcessing,
              onApprove: onApprove,
              onReject: onReject,
            ),
          ],
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.title,
    required this.statusGroup,
  });

  final String title;
  final String statusGroup;

  static const Color kText = Color(0xFF212121);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: kText,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _StatusBadge(label: statusGroup),
      ],
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.child,
  });

  final Widget child;

  static const Color kBorder = Color(0xFFE0E0E0);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
          child: child,
        ),
      ),
    );
  }
}

class _MiniDetailRow extends StatelessWidget {
  const _MiniDetailRow({
    required this.title,
    required this.trailing,
  });

  final String title;
  final String trailing;

  static const Color kText = Color(0xFF212121);
  static const Color kBorder = Color(0xFFE0E0E0);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: kText),
            ),
          ),
          Text(
            trailing,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: kText,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.isProcessing,
    required this.onApprove,
    required this.onReject,
  });

  final bool isProcessing;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  static const Color kPrimary = Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isProcessing ? null : onReject,
            icon: const Icon(Icons.close_rounded),
            label: const Text('Tolak'),
            style: OutlinedButton.styleFrom(
              foregroundColor: kPrimary,
              side: const BorderSide(color: kPrimary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isProcessing ? null : onApprove,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Setujui'),
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
    );
  }
}

class _CompleteButton extends StatelessWidget {

  const _CompleteButton({
    required this.isProcessing,
    required this.onComplete,
  });

  final bool isProcessing;
  final VoidCallback onComplete;

  static const Color kPrimary =
      Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context) {

    return SizedBox(
      width: double.infinity,

      child: ElevatedButton.icon(

        onPressed:
            isProcessing
                ? null
                : onComplete,

        icon: const Icon(
          Icons.check_circle,
        ),

        label: const Text(
          'Selesaikan',
        ),

        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,

          padding:
              const EdgeInsets.symmetric(
            vertical: 14,
          ),

          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}