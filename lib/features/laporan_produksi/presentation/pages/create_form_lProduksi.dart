import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/production_remote_datasource.dart';
import '../../data/repositories/production_repository_impl.dart';
import '../../domain/entities/production_report.dart';
import '../../domain/usecases/create_production_report.dart';

class CreateFormLProduksiPage extends StatefulWidget {
  const CreateFormLProduksiPage({super.key});

  @override
  State<CreateFormLProduksiPage> createState() => _CreateFormLProduksiPageState();
}

class _CreateFormLProduksiPageState extends State<CreateFormLProduksiPage> {
  static const Color kPrimary = Color(0xFFD32F2F);
  static const Color kText = Color(0xFF212121);
  static const Color kMuted = Color(0xFF616161);
  static const Color kBorder = Color(0xFFE0E0E0);

  final _formKey = GlobalKey<FormState>();
  final _notesC = TextEditingController();

  DateTime _productionDate = DateTime.now();

  final List<_MaterialUsageRow> _materials = [_MaterialUsageRow()];
  final List<_FinishedProductRow> _products = [_FinishedProductRow()];

  List<Map<String, dynamic>> _rawMaterialInventory = [];
  List<Map<String, dynamic>> _productOptions = [];

  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _notesC.dispose();

    for (final item in _materials) {
      item.dispose();
    }

    for (final item in _products) {
      item.dispose();
    }

    super.dispose();
  }

  Future<void> _loadOptions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Token tidak ditemukan, silakan login ulang');
      }

      final datasource = ProductionRemoteDatasource();

      final rawMaterials = await datasource.getRawMaterialInventory(token);
      final products = await datasource.getProducts(token);

      if (!mounted) return;

      setState(() {
        _rawMaterialInventory = rawMaterials;
        _productOptions = products;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal ambil data: $e')),
      );
    }
  }

  Future<void> _pickProductionDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _productionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => _productionDate = picked);
    }
  }

  void _addMaterial() {
    setState(() => _materials.add(_MaterialUsageRow()));
  }

  void _removeMaterial(int index) {
    if (_materials.length > 1) {
      setState(() {
        _materials[index].dispose();
        _materials.removeAt(index);
      });
    }
  }

  void _addProduct() {
    setState(() => _products.add(_FinishedProductRow()));
  }

  void _removeProduct(int index) {
    if (_products.length > 1) {
      setState(() {
        _products[index].dispose();
        _products.removeAt(index);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final invalidMaterial = _materials.any((item) {
      final qty = int.tryParse(item.qtyC.text.trim()) ?? 0;
      return item.rawMaterialId == null || qty <= 0;
    });

    final invalidProduct = _products.any((item) {
      final qty = int.tryParse(item.qtyC.text.trim()) ?? 0;
      return item.productId == null || qty <= 0;
    });

    if (invalidMaterial || invalidProduct) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengkapi bahan baku dan produk jadi dengan qty > 0'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Token tidak ditemukan, silakan login ulang');
      }

      final repository = ProductionRepositoryImpl(
        ProductionRemoteDatasource(),
      );

      final createProductionReport = CreateProductionReport(repository);

      final report = ProductionReport(
        id: '',
        reportNumber: '',
        productionDate: _productionDate,
        status: 'Submitted',
        notes: _notesC.text.trim(),
        materialUsages: _materials.map((item) {
          return ProductionMaterialUsage(
            rawMaterialId: item.rawMaterialId!,
            rawMaterialName: item.name,
            qty: int.tryParse(item.qtyC.text.trim()) ?? 0,
            uom: item.uom,
          );
        }).toList(),
        finishedProducts: _products.map((item) {
          return ProductionFinishedProduct(
            productId: item.productId!,
            productName: item.name,
            qty: int.tryParse(item.qtyC.text.trim()) ?? 0,
            uom: item.uom,
          );
        }).toList(),
      );

      await createProductionReport(report, token);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan produksi berhasil dikirim')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal simpan laporan produksi: $e')),
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
        title: const Text('Buat Laporan Produksi'),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : SafeArea(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  child: Column(
                    children: [
                      _SectionCard(
                        title: 'Informasi Produksi',
                        child: Column(
                          children: [
                            _dateField(
                              label: 'Tanggal Produksi',
                              date: _productionDate,
                              onPick: _pickProductionDate,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _notesC,
                              maxLines: 3,
                              decoration: _dec('Catatan'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Bahan Baku yang Dipakai',
                        subtitle: 'Stok akan berkurang setelah laporan di-approve admin',
                        action: TextButton.icon(
                          onPressed: _addMaterial,
                          icon: const Icon(Icons.add_rounded, color: kPrimary),
                          label: const Text(
                            'Tambah',
                            style: TextStyle(
                              color: kPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        child: Column(
                          children: List.generate(_materials.length, (index) {
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index == _materials.length - 1 ? 0 : 12,
                              ),
                              child: _MaterialUsageCard(
                                data: _materials[index],
                                options: _rawMaterialInventory,
                                onChanged: () => setState(() {}),
                                onRemove: _materials.length > 1
                                    ? () => _removeMaterial(index)
                                    : null,
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Produk Jadi',
                        subtitle: 'Produk akan masuk inventory basecamp setelah approve',
                        action: TextButton.icon(
                          onPressed: _addProduct,
                          icon: const Icon(Icons.add_rounded, color: kPrimary),
                          label: const Text(
                            'Tambah',
                            style: TextStyle(
                              color: kPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        child: Column(
                          children: List.generate(_products.length, (index) {
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index == _products.length - 1 ? 0 : 12,
                              ),
                              child: _FinishedProductCard(
                                data: _products[index],
                                options: _productOptions,
                                onChanged: () => setState(() {}),
                                onRemove: _products.length > 1
                                    ? () => _removeProduct(index)
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
                                  'Simpan Laporan Produksi',
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

  Widget _dateField({
    required String label,
    required DateTime date,
    required VoidCallback onPick,
  }) {
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: _dec(label),
        child: Row(
          children: [
            const Icon(Icons.date_range_rounded, size: 18, color: kMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _fmtDate(date),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: kText,
                ),
              ),
            ),
            const Icon(Icons.expand_more_rounded, color: kMuted),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    this.subtitle,
    required this.child,
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
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: kText,
                    ),
                  ),
                ),
                if (action != null) action!,
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  subtitle!,
                  style: const TextStyle(color: kMuted, fontSize: 12),
                ),
              ),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _MaterialUsageRow {
  int? rawMaterialId;
  String name = '';
  String uom = '';

  final qtyC = TextEditingController();

  void dispose() {
    qtyC.dispose();
  }
}

class _FinishedProductRow {
  int? productId;
  String name = '';
  String uom = '';

  final qtyC = TextEditingController();

  void dispose() {
    qtyC.dispose();
  }
}

class _MaterialUsageCard extends StatelessWidget {
  const _MaterialUsageCard({
    required this.data,
    required this.options,
    required this.onChanged,
    this.onRemove,
  });

  final _MaterialUsageRow data;
  final List<Map<String, dynamic>> options;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  static const Color kPrimary = Color(0xFFD32F2F);
  static const Color kBorder = Color(0xFFE0E0E0);
  static const Color kText = Color(0xFF212121);
  static const Color kMuted = Color(0xFF616161);

  @override
  Widget build(BuildContext context) {
    return _Box(
      child: Column(
        children: [
          DropdownButtonFormField<int>(
            isExpanded: true,
            value: data.rawMaterialId,
            decoration: _dec('Bahan Baku'),
            hint: const Text('Pilih bahan'),
            items: options.map((item) {
              final stock = item['total_stock'] ?? 0;
              final uom = item['uom'] ?? '';

              return DropdownMenuItem<int>(
                value: item['raw_material_id'],
                child: Text('${item['name']} — stok: $stock $uom'),
              );
            }).toList(),
            onChanged: (value) {
              final selected = options.firstWhere(
                (item) => item['raw_material_id'] == value,
              );

              data.rawMaterialId = selected['raw_material_id'];
              data.name = selected['name']?.toString() ?? '';
              data.uom = selected['uom']?.toString() ?? '';

              onChanged();
            },
            validator: (value) {
              if (value == null) return 'Pilih bahan baku';
              return null;
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InputDecorator(
                  decoration: _dec('Satuan'),
                  child: Text(
                    data.uom.isEmpty ? '—' : data.uom,
                    style: const TextStyle(
                      color: kText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: data.qtyC,
                  keyboardType: TextInputType.number,
                  decoration: _dec('Qty Dipakai'),
                  validator: (value) {
                    final qty = int.tryParse(value ?? '') ?? 0;
                    if (qty <= 0) return 'Qty wajib > 0';
                    return null;
                  },
                ),
              ),
              if (onRemove != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded, color: kPrimary),
                ),
              ],
            ],
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

class _FinishedProductCard extends StatelessWidget {
  const _FinishedProductCard({
    required this.data,
    required this.options,
    required this.onChanged,
    this.onRemove,
  });

  final _FinishedProductRow data;
  final List<Map<String, dynamic>> options;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  static const Color kPrimary = Color(0xFFD32F2F);
  static const Color kBorder = Color(0xFFE0E0E0);
  static const Color kText = Color(0xFF212121);

  @override
  Widget build(BuildContext context) {
    return _Box(
      child: Column(
        children: [
          DropdownButtonFormField<int>(
            isExpanded: true,
            value: data.productId,
            decoration: _dec('Produk Jadi'),
            hint: const Text('Pilih produk'),
            items: options.map((item) {
              return DropdownMenuItem<int>(
                value: item['id'],
                child: Text(item['name']?.toString() ?? '-'),
              );
            }).toList(),
            onChanged: (value) {
              final selected = options.firstWhere(
                (item) => item['id'] == value,
              );

              data.productId = selected['id'];
              data.name = selected['name']?.toString() ?? '';
              data.uom = selected['uom']?.toString() ?? 'pcs';

              onChanged();
            },
            validator: (value) {
              if (value == null) return 'Pilih produk jadi';
              return null;
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InputDecorator(
                  decoration: _dec('Satuan'),
                  child: Text(
                    data.uom.isEmpty ? '—' : data.uom,
                    style: const TextStyle(
                      color: kText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: data.qtyC,
                  keyboardType: TextInputType.number,
                  decoration: _dec('Qty Jadi'),
                  validator: (value) {
                    final qty = int.tryParse(value ?? '') ?? 0;
                    if (qty <= 0) return 'Qty wajib > 0';
                    return null;
                  },
                ),
              ),
              if (onRemove != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded, color: kPrimary),
                ),
              ],
            ],
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

class _Box extends StatelessWidget {
  const _Box({
    required this.child,
  });

  final Widget child;

  static const Color kBorder = Color(0xFFE0E0E0);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}