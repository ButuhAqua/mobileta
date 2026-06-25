import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/pengajuan_remote_datasource.dart';
import '../../data/repositories/pengajuan_repository_impl.dart';
import '../../domain/entities/pengajuan.dart';
import '../../domain/usecases/create_pengajuan.dart';

class CreateFormSubBahanPage extends StatefulWidget {
  const CreateFormSubBahanPage({
    super.key,
    this.isAdmin = false,
    this.currentUserName = 'User',
    this.currentUserEmail = 'user@example.com',
  });

  final bool isAdmin;
  final String currentUserName;
  final String currentUserEmail;

  @override
  State<CreateFormSubBahanPage> createState() => _CreateFormSubBahanPageState();
}

class _CreateFormSubBahanPageState extends State<CreateFormSubBahanPage> {
  static const Color kPrimary = Color(0xFFD32F2F);
  static const Color kText = Color(0xFF212121);
  static const Color kMuted = Color(0xFF616161);
  static const Color kBorder = Color(0xFFE0E0E0);

  final _formKey = GlobalKey<FormState>();

  final _judulC = TextEditingController();
  final _catatanC = TextEditingController();
  final _lokasiPembelianC = TextEditingController();

  String _prioritas = 'Normal';
  DateTime _tanggal = DateTime.now();

  final List<_ItemRowData> _items = [_ItemRowData()];

  bool _isLoading = false;
  bool _isLoadingMaterials = true;

  List<Map<String, dynamic>> _rawMaterials = [];

  @override
  void initState() {
    super.initState();
    _loadRawMaterials();
  }

  @override
  void dispose() {
    _judulC.dispose();
    _catatanC.dispose();
    _lokasiPembelianC.dispose();

    for (final item in _items) {
      item.dispose();
    }

    super.dispose();
  }

  Future<void> _loadRawMaterials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Token tidak ditemukan, silakan login ulang');
      }

      final datasource = PengajuanRemoteDataSource();
      final materials = await datasource.getRawMaterials(token);

      if (!mounted) return;

      setState(() {
        _rawMaterials = materials;
        _isLoadingMaterials = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoadingMaterials = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal ambil bahan baku: $e')),
      );
    }
  }

  Future<void> _pickDatePengajuan() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => _tanggal = picked);
    }
  }

  void _addItem() {
    setState(() => _items.add(_ItemRowData()));
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() {
        _items[index].dispose();
        _items.removeAt(index);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_items.any(
      (item) =>
          item.rawMaterialId == null ||
          (int.tryParse(item.qtyC.text.trim()) ?? 0) <= 0,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengkapi item: pilih bahan dan qty > 0'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Token tidak ditemukan, silakan login ulang');
      }

      final repository = PengajuanRepositoryImpl(
        PengajuanRemoteDataSource(),
      );

      final createPengajuan = CreatePengajuan(repository);

      final pengajuan = Pengajuan(
        id: '',
        title: _judulC.text.trim(),
        requestType: 'Pembelian Bahan Baku',
        priority: _prioritas,
        requestDate: _tanggal,
        notes: _catatanC.text.trim(),
        purchaseLocation: _lokasiPembelianC.text.trim(),
        status: 'Menunggu',
        items: _items.map((item) {
          return PengajuanItem(
            rawMaterialId: item.rawMaterialId,
            name: item.name,
            category: item.category,
            uom: item.uom,
            qty: int.tryParse(item.qtyC.text.trim()) ?? 0,
          );
        }).toList(),
      );

      await createPengajuan(pengajuan, token);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengajuan berhasil dikirim')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal kirim pengajuan: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Pengajuan Bahan Baku'),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionCard(
                  title: 'Identitas Pengajuan',
                  child: Column(
                    children: [
                      _textField(
                        label: 'Judul Pengajuan',
                        controller: _judulC,
                        validator: (value) {
                          if (value == null || value.trim().length < 5) {
                            return 'Minimal 5 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _textField(
                        label: 'Jenis Pengajuan',
                        initialValue: 'Pembelian Bahan Baku',
                        readOnly: true,
                      ),
                      const SizedBox(height: 12),
                      _dropdown(
                        label: 'Prioritas',
                        value: _prioritas,
                        items: const ['Normal', 'Mendesak'],
                        onChanged: (value) {
                          setState(() => _prioritas = value!);
                        },
                      ),
                      const SizedBox(height: 12),
                      _dateField(
                        label: 'Tanggal Pengajuan',
                        date: _tanggal,
                        onPick: _pickDatePengajuan,
                      ),
                      const SizedBox(height: 12),
                      _textField(
                        label: 'Catatan (opsional)',
                        controller: _catatanC,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Item Belanja',
                  subtitle: 'Pilih bahan baku dari master inventory',
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
                  child: _isLoadingMaterials
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: CircularProgressIndicator(color: kPrimary),
                          ),
                        )
                      : _rawMaterials.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                'Belum ada data bahan baku. Tambahkan dulu di master raw materials.',
                              ),
                            )
                          : Column(
                              children: List.generate(
                                _items.length,
                                (index) => Padding(
                                  padding: EdgeInsets.only(
                                    bottom:
                                        index == _items.length - 1 ? 0 : 12,
                                  ),
                                  child: _ItemRow(
                                    data: _items[index],
                                    rawMaterials: _rawMaterials,
                                    onChanged: () => setState(() {}),
                                    onRemove: _items.length > 1
                                        ? () => _removeItem(index)
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Lokasi Pembelian',
                  child: _textField(
                    label: 'Beli di toko mana?',
                    controller: _lokasiPembelianC,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Simpan Pengajuan'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _textField({
    required String label,
    TextEditingController? controller,
    String? initialValue,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool enabled = true,
    bool readOnly = false,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      validator: validator,
      maxLines: maxLines,
      enabled: enabled,
      readOnly: readOnly,
      onChanged: onChanged,
      decoration: _dec(label),
      style: const TextStyle(color: kText),
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
    bool enabled = true,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: value,
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: enabled ? onChanged : null,
      decoration: _dec(label),
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? date,
    required VoidCallback? onPick,
    bool enabled = true,
  }) {
    final text = date == null ? '—' : _fmtDate(date);

    return InkWell(
      onTap: enabled && onPick != null ? onPick : null,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: _dec(label),
        child: Row(
          children: [
            const Icon(Icons.date_range_rounded, size: 18, color: kMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: kText,
                ),
              ),
            ),
            if (enabled) const Icon(Icons.expand_more_rounded, color: kMuted),
          ],
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
              Text(
                subtitle!,
                style: const TextStyle(color: kMuted, fontSize: 12),
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

class _ItemRowData {
  int? rawMaterialId;
  String name = '';
  String category = '';
  String uom = '';

  final qtyC = TextEditingController();

  void dispose() {
    qtyC.dispose();
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.data,
    required this.rawMaterials,
    required this.onChanged,
    this.onRemove,
  });

  final _ItemRowData data;
  final List<Map<String, dynamic>> rawMaterials;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  static const Color kPrimary = Color(0xFFD32F2F);
  static const Color kBorder = Color(0xFFE0E0E0);
  static const Color kText = Color(0xFF212121);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          DropdownButtonFormField<int>(
            isExpanded: true,
            value: data.rawMaterialId,
            decoration: _dec('Nama Item'),
            hint: const Text('Pilih bahan baku'),
            items: rawMaterials.map((material) {
              return DropdownMenuItem<int>(
                value: material['id'],
                child: Text(material['name']?.toString() ?? '-'),
              );
            }).toList(),
            onChanged: (value) {
              final selected = rawMaterials.firstWhere(
                (material) => material['id'] == value,
              );

              data.rawMaterialId = selected['id'];
              data.name = selected['name']?.toString() ?? '';
              data.category = selected['category']?.toString() ?? '';
              data.uom = selected['uom']?.toString() ?? '';

              onChanged();
            },
            validator: (value) {
              if (value == null) {
                return 'Pilih bahan baku';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Flexible(
                child: _readonlyBox(
                  label: 'Kategori',
                  value: data.category.isEmpty ? '—' : data.category,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: _readonlyBox(
                  label: 'Satuan',
                  value: data.uom.isEmpty ? '—' : data.uom,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Flexible(
                child: TextFormField(
                  controller: data.qtyC,
                  keyboardType: TextInputType.number,
                  decoration: _dec('Qty'),
                  validator: (value) {
                    final qty = int.tryParse(value ?? '') ?? 0;

                    if (qty <= 0) {
                      return 'Qty wajib > 0';
                    }

                    return null;
                  },
                ),
              ),
              if (onRemove != null) ...[
                const SizedBox(width: 12),
                IconButton(
                  onPressed: onRemove,
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

  Widget _readonlyBox({
    required String label,
    required String value,
  }) {
    return InputDecorator(
      decoration: _dec(label),
      child: Text(
        value,
        style: const TextStyle(
          color: kText,
          fontWeight: FontWeight.w600,
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
}