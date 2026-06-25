import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:apps_break/features/auth/data/auth_service.dart';
import 'package:apps_break/features/product_inventory/data/datasources/product_inventory_remote_datasource.dart';
import 'package:apps_break/features/runner_trip/data/datasources/runner_trip_remote_datasource.dart';
import 'package:apps_break/features/runner_trip/data/repositories/runner_trip_repository_impl.dart';
import 'package:apps_break/features/runner_trip/domain/entities/runner_trip.dart';
import 'package:apps_break/features/runner_trip/domain/usecases/create_departure_trip.dart';

class CreateFormProdukKeluarPage extends StatefulWidget {
  const CreateFormProdukKeluarPage({super.key});

  @override
  State<CreateFormProdukKeluarPage> createState() =>
      _CreateFormProdukKeluarPageState();
}

class _CreateFormProdukKeluarPageState
    extends State<CreateFormProdukKeluarPage> {
  static const Color kPrimary = Color(0xFFD32F2F);
  static const Color kText = Color(0xFF212121);
  static const Color kMuted = Color(0xFF616161);
  static const Color kBorder = Color(0xFFE0E0E0);

  final _formKey = GlobalKey<FormState>();
  final _catatanC = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;

  String _runnerName = '';
  String _assignedLocation = '';

  final List<Map<String, dynamic>> _inventoryItems = [];
  final List<_DepartureItemRowData> _items = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _catatanC.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final me = await AuthService().me();
      final employee = me['employee'];

      final assignedLocation = employee?['assigned_location'];
      final runnerName = employee?['full_name'] ?? me['name'] ?? 'Runner';

      if (assignedLocation == null || assignedLocation.toString().isEmpty) {
        throw Exception('Runner belum memiliki assigned location');
      }

      final response = await ProductInventoryRemoteDataSource()
          .getInventoryByLocation(assignedLocation, token);

      _inventoryItems.clear();

      for (final item in response) {
        _inventoryItems.add({
          'id': item.id,
          'product_id': item.productId,
          'name': item.name,
          'sku': item.sku,
          'uom': item.uom,
          'qty': item.qty,
          'location': item.location,
        });
      }

      if (_inventoryItems.isEmpty) {
        throw Exception('Inventory gerobak kosong');
      }

      _items.add(_DepartureItemRowData());

      setState(() {
        _runnerName = runnerName;
        _assignedLocation = assignedLocation;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data: $e')),
      );
    }
  }

  void _addItem() {
    setState(() {
      _items.add(_DepartureItemRowData());
    });
  }

  void _removeItem(int index) {
    if (_items.length <= 1) return;

    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token tidak ditemukan')),
      );
      return;
    }

    final departureItems = <DepartureTripItem>[];

    for (final row in _items) {
      final selected = row.selectedInventory;

      if (selected == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih produk terlebih dahulu')),
        );
        return;
      }

      final productId = int.tryParse(selected['product_id'].toString()) ?? 0;
      final qtyTaken = int.tryParse(row.qtyC.text.trim()) ?? 0;
      final stock = selected['qty'] ?? 0;

      if (qtyTaken <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Qty harus lebih dari 0')),
        );
        return;
      }

      if (qtyTaken > stock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Qty ${selected['name']} melebihi stok tersedia ($stock)',
            ),
          ),
        );
        return;
      }

      departureItems.add(
        DepartureTripItem(
          productId: productId,
          qtyTaken: qtyTaken,
        ),
      );
    }

    setState(() => _isSubmitting = true);

    try {
      final repository = RunnerTripRepositoryImpl(
        RunnerTripRemoteDatasource(),
      );

      final createDepartureTrip = CreateDepartureTrip(repository);

      await createDepartureTrip(
        token: token,
        notes: _catatanC.text.trim(),
        items: departureItems,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan berangkat berhasil dibuat')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal submit: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: const Text('Laporan Berangkat'),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: kPrimary),
            )
          : SafeArea(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionCard(
                        title: 'Informasi Runner',
                        child: Column(
                          children: [
                            _readonlyTile(
                              title: 'Runner',
                              value: _runnerName,
                            ),
                            const SizedBox(height: 10),
                            _readonlyTile(
                              title: 'Gerobak',
                              value: _assignedLocation,
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _catatanC,
                              maxLines: 3,
                              decoration: _dec('Catatan Berangkat'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Produk Dibawa',
                        subtitle: 'Pilih produk dari inventory gerobak kamu',
                        action: TextButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add_rounded, color: kPrimary),
                          label: const Text(
                            'Tambah Item',
                            style: TextStyle(
                              color: kPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        child: Column(
                          children: List.generate(_items.length, (index) {
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index == _items.length - 1 ? 0 : 12,
                              ),
                              child: _DepartureItemRow(
                                data: _items[index],
                                inventoryItems: _inventoryItems,
                                onRemove: _items.length > 1
                                    ? () => _removeItem(index)
                                    : null,
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Submit Laporan Berangkat',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
    );
  }

  Widget _readonlyTile({
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(title, style: const TextStyle(color: kMuted)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
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
}

class _DepartureItemRowData {
  Map<String, dynamic>? selectedInventory;
  final qtyC = TextEditingController();

  void dispose() {
    qtyC.dispose();
  }
}

class _DepartureItemRow extends StatefulWidget {
  const _DepartureItemRow({
    required this.data,
    required this.inventoryItems,
    this.onRemove,
  });

  final _DepartureItemRowData data;
  final List<Map<String, dynamic>> inventoryItems;
  final VoidCallback? onRemove;

  @override
  State<_DepartureItemRow> createState() => _DepartureItemRowState();
}

class _DepartureItemRowState extends State<_DepartureItemRow> {
  static const Color kPrimary = Color(0xFFD32F2F);
  static const Color kBorder = Color(0xFFE0E0E0);
  static const Color kMuted = Color(0xFF616161);

  @override
  Widget build(BuildContext context) {
    final selected = widget.data.selectedInventory;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          DropdownButtonFormField<Map<String, dynamic>>(
            value: widget.data.selectedInventory,
            isExpanded: true,
            decoration: _dec('Produk'),
            items: widget.inventoryItems.map((item) {
              return DropdownMenuItem<Map<String, dynamic>>(
                value: item,
                child: Text(
                  '${item['name']} • stok ${item['qty']} ${item['uom']}',
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                widget.data.selectedInventory = value;
                widget.data.qtyC.clear();
              });
            },
            validator: (value) {
              if (value == null) return 'Pilih produk';
              return null;
            },
          ),
          if (selected != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _infoBox(
                    'SKU',
                    selected['sku']?.toString() ?? '-',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _infoBox(
                    'Satuan',
                    selected['uom']?.toString() ?? '-',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _infoBox(
                    'Stok',
                    selected['qty'].toString(),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: widget.data.qtyC,
                  keyboardType: TextInputType.number,
                  decoration: _dec('Qty Dibawa'),
                  validator: (value) {
                    final qty = int.tryParse(value ?? '') ?? 0;
                    final stock = selected?['qty'] ?? 0;

                    if (qty <= 0) return 'Harus > 0';
                    if (qty > stock) return 'Melebihi stok';
                    return null;
                  },
                ),
              ),
              if (widget.onRemove != null) ...[
                const SizedBox(width: 12),
                IconButton(
                  onPressed: widget.onRemove,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: kPrimary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoBox(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: kMuted, fontSize: 11)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? action;

  static const Color kBorder = Color(0xFFE0E0E0);
  static const Color kText = Color(0xFF212121);
  static const Color kMuted = Color(0xFF616161);

  @override
  Widget build(BuildContext context) {
    return Material(
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
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: kText,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            color: kMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (action != null) action!,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}