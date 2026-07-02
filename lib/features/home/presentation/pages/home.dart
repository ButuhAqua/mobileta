import 'package:flutter/material.dart';

import 'package:apps_break/core/constants/app_colors.dart';
import 'package:apps_break/features/auth/data/auth_service.dart';
import 'package:apps_break/features/pengajuan_bahan_baku/presentation/pages/list_form_subbahan.dart';
import 'package:apps_break/features/runner_trip/presentation/pages/list_form_pKeluar.dart';
import 'package:apps_break/features/runner_trip/presentation/pages/list_form_pMasuk.dart';
import 'package:apps_break/features/laporan_produksi/presentation/pages/list_form_lProduksi.dart';
import 'package:apps_break/features/product_inventory/presentation/pages/inventory.dart';
import 'package:apps_break/features/product_inventory/presentation/pages/inventory_pA.dart';
import 'package:apps_break/features/product_inventory/presentation/pages/inventory_pB.dart';
import 'package:apps_break/features/product_inventory/presentation/pages/inventory_pC.dart';
import 'package:apps_break/features/product_inventory/presentation/pages/inventory_pD.dart';
import 'package:apps_break/features/product_inventory/presentation/pages/inventory_pE.dart';
import 'package:apps_break/features/product_inventory/presentation/pages/inventory_pF.dart';
import 'package:apps_break/features/profile/presentation/pages/profile.dart' as profile;
import 'package:apps_break/features/approval/presentation/pages/approval_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 1;

  bool _isLoading = true;
  String _name = 'User';
  String _role = '';
  String? _assignedLocation;

  int _statPengajuan = 0;
  int _statProduksi = 0;
  int _statBerangkat = 0;
  int _statPulang = 0;
  int _statInventory = 0;

  @override
  void initState() {
    super.initState();
    _loadHome();
  }

  bool get _isFullAccessRole {
    return _role == 'Manager' ||
        _role == 'Owner' ||
        _role == 'Admin' ||
        _role == 'Super Admin' ||
        _role == 'super_admin';
  }

  String _resolveRole(Map<String, dynamic> data, dynamic employee) {
    final roleFromEmployee = employee?['role'];

    final roles = data['roles'];

    String roleFromSpatie = '';

    if (roles is List && roles.isNotEmpty) {
      roleFromSpatie = roles.first.toString();
    }

    if (roleFromEmployee != null && roleFromEmployee.toString().isNotEmpty) {
      return roleFromEmployee.toString();
    }

    if (roleFromSpatie == 'super_admin') {
      return 'Super Admin';
    }

    if (roleFromSpatie.isNotEmpty) {
      return roleFromSpatie;
    }

    return '';
  }

  Future<void> _loadHome() async {
    try {
      final data = await AuthService().me();
      final employee = data['employee'];

      final dashboard = await AuthService().getHomeDashboard();
      final stats = dashboard['data'];

      final resolvedRole = _resolveRole(data, employee);

      if (!mounted) return;

      setState(() {
        _name = employee?['full_name'] ?? data['name'] ?? 'User';
        _role = resolvedRole;
        _assignedLocation = employee?['assigned_location'];

        _statPengajuan = stats?['pengajuan'] ?? 0;
        _statProduksi = stats?['produksi'] ?? 0;
        _statBerangkat = stats?['berangkat'] ?? 0;
        _statPulang = stats?['pulang'] ?? 0;
        _statInventory = stats?['inventory'] ?? 0;

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      final message = e.toString();

      if (message.contains('Token tidak ditemukan')) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal ambil data home: $e')),
      );
    }
  }

  List<_HomeOption> _menusByRole() {
    if (_role == 'Runner') {
      return [
        _HomeOption(
          title: 'Laporan Berangkat',
          icon: Icons.outbox_rounded,
          badge: 0,
          page: const ListFormProdukKeluarPage(),
          onBack: _loadHome,
        ),
        _HomeOption(
          title: 'Laporan Pulang',
          icon: Icons.move_to_inbox_rounded,
          badge: 0,
          page: const ListFormProdukMasukPage(),
          onBack: _loadHome,
        ),
        _HomeOption(
          title: 'Inventory Gerobak',
          icon: Icons.inventory_2_rounded,
          badge: 0,
          page: _runnerInventoryPage(),
          onBack: _loadHome,
        ),
      ];
    }

    if (_role == 'Unit Produksi') {
      return [
        _HomeOption(
          title: 'Pengajuan Bahan Baku',
          icon: Icons.assignment_rounded,
          badge: 0,
          page: const ListFormSubBahanPage(),
          onBack: _loadHome,
        ),
        _HomeOption(
          title: 'Laporan Produksi',
          icon: Icons.factory_rounded,
          badge: 0,
          page: const ListFormLProduksiPage(),
          onBack: _loadHome,
        ),
        _HomeOption(
          title: 'Inventori',
          icon: Icons.inventory_2_rounded,
          badge: 0,
          page: const InventoryPage(),
          onBack: _loadHome,
        ),
      ];
    }

    if (_isFullAccessRole) {
      return [
        _HomeOption(
          title: 'Approval Pengajuan',
          icon: Icons.verified_rounded,
          badge: _statPengajuan,
          page: const ApprovalPage(),
          onBack: _loadHome,
        ),
        _HomeOption(
          title: 'Pengajuan Bahan Baku',
          icon: Icons.assignment_rounded,
          badge: 0,
          page: const ListFormSubBahanPage(),
          onBack: _loadHome,
        ),
        _HomeOption(
          title: 'Laporan Produksi',
          icon: Icons.factory_rounded,
          badge: 0,
          page: const ListFormLProduksiPage(),
          onBack: _loadHome,
        ),
        _HomeOption(
          title: 'Laporan Berangkat',
          icon: Icons.outbox_rounded,
          badge: 0,
          page: const ListFormProdukKeluarPage(),
          onBack: _loadHome,
        ),
        _HomeOption(
          title: 'Laporan Pulang',
          icon: Icons.move_to_inbox_rounded,
          badge: 0,
          page: const ListFormProdukMasukPage(),
          onBack: _loadHome,
        ),
        _HomeOption(
          title: 'Inventori',
          icon: Icons.inventory_2_rounded,
          badge: 0,
          page: const InventoryPage(),
          onBack: _loadHome,
        ),
      ];
    }

    return [
      _HomeOption(
        title: 'Inventori',
        icon: Icons.inventory_2_rounded,
        badge: 0,
        page: const InventoryPage(),
        onBack: _loadHome,
      ),
    ];
  }

  List<Widget> _buildQuickStats() {
    if (_role == 'Unit Produksi') {
      return [
        _QuickStat(title: 'Pengajuan', value: _statPengajuan.toString()),
        _QuickStat(title: 'Produksi', value: _statProduksi.toString()),
        _QuickStat(title: 'Inventory', value: _statInventory.toString()),
      ];
    }

    if (_role == 'Runner') {
      return [
        _QuickStat(title: 'Berangkat', value: _statBerangkat.toString()),
        _QuickStat(title: 'Pulang', value: _statPulang.toString()),
        _QuickStat(title: 'Inventory', value: _statInventory.toString()),
      ];
    }

    return [
      _QuickStat(title: 'Pengajuan', value: _statPengajuan.toString()),
      _QuickStat(title: 'Produksi', value: _statProduksi.toString()),
      _QuickStat(title: 'Berangkat', value: _statBerangkat.toString()),
      _QuickStat(title: 'Pulang', value: _statPulang.toString()),
    ];
  }

  Widget _runnerInventoryPage() {
    // import halaman gerobak C-F di atas
    if (_assignedLocation == 'Gerobak A') {
      return const InventoryGerobakAPage();
    }
    if (_assignedLocation == 'Gerobak B') {
      return const InventoryGerobakBPage();
    }
    if (_assignedLocation == 'Gerobak C') {
      return const InventoryGerobakCPage();
    }
    if (_assignedLocation == 'Gerobak D') {
      return const InventoryGerobakDPage();
    }
    if (_assignedLocation == 'Gerobak E') {
      return const InventoryGerobakEPage();
    }
    if (_assignedLocation == 'Gerobak F') {
      return const InventoryGerobakFPage();
    }
    return const InventoryPage();
  }

  @override
  Widget build(BuildContext context) {
    final options = _menusByRole();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Break.Co Dashboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Halo, $_name',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _assignedLocation == null || _assignedLocation!.isEmpty
                            ? _role
                            : '$_role • $_assignedLocation',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: _buildQuickStats(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _loadHome,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: options.length,
                      itemBuilder: (_, i) {
                        final item = options[i];
                        return _AnimatedMenuCard(option: item);
                      },
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          setState(() => _currentIndex = i);

          if (i == 0) {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          } else if (i == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const profile.ProfilePage(),
              ),
            ).then((_) {
              setState(() => _currentIndex = 1);
              _loadHome();
            });
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.arrow_back),
            label: 'Back',
          ),
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _AnimatedMenuCard extends StatelessWidget {
  final _HomeOption option;

  const _AnimatedMenuCard({required this.option});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.9, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(
            context,
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 400),
              pageBuilder: (_, animation, __) => FadeTransition(
                opacity: animation,
                child: option.page,
              ),
            ),
          );

          option.onBack?.call();
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                blurRadius: 12,
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      option.icon,
                      size: 30,
                      color: AppColors.primary,
                    ),
                  ),
                  if (option.badge > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          option.badge.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  option.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String title;
  final String value;

  const _QuickStat({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeOption {
  final String title;
  final IconData icon;
  final int badge;
  final Widget page;
  final VoidCallback? onBack;

  _HomeOption({
    required this.title,
    required this.icon,
    required this.badge,
    required this.page,
    this.onBack,
  });
}