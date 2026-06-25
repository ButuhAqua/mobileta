// inventory_product.dart
import 'package:flutter/material.dart';

import 'package:apps_break/features/product_inventory/presentation/pages/inventory_pA.dart';
import 'package:apps_break/features/product_inventory/presentation/pages/inventory_pB.dart';
import 'package:apps_break/features/product_inventory/presentation/pages/inventory_pC.dart';
import 'package:apps_break/features/product_inventory/presentation/pages/inventory_pD.dart';
import 'package:apps_break/features/product_inventory/presentation/pages/inventory_pE.dart';
import 'package:apps_break/features/product_inventory/presentation/pages/inventory_pF.dart';
import 'package:apps_break/features/product_inventory/presentation/pages/inventory_basecamp.dart';

class InventoryProductPage extends StatefulWidget {
  const InventoryProductPage({super.key});

  @override
  State<InventoryProductPage> createState() => _InventoryProductPageState();
}

class _InventoryProductPageState extends State<InventoryProductPage> {
  static const Color kPrimary = Color(0xFFD32F2F);
  static const Color kBg = Colors.white;
  static const Color kText = Color(0xFF212121);
  static const Color kMuted = Color(0xFF616161);
  static const Color kBorder = Color(0xFFE0E0E0);

  // Daftar lokasi dengan icon dan warna yang berbeda
  final List<Map<String, dynamic>> _locations = [
    {
      'title': 'Basecamp',
      'subtitle': 'Lihat & kelola stok di Basecamp',
      'icon': Icons.store_rounded,
      'color': Color(0xFFD32F2F),
      'page': const InventoryBasecampPage(),
    },
    {
      'title': 'Gerobak A',
      'subtitle': 'Lihat & kelola produk di Gerobak A',
      'icon': Icons.shopping_cart_rounded,
      'color': Color(0xFF1976D2),
      'page': const InventoryGerobakAPage(),
    },
    {
      'title': 'Gerobak B',
      'subtitle': 'Lihat & kelola produk di Gerobak B',
      'icon': Icons.shopping_cart_rounded,
      'color': Color(0xFF388E3C),
      'page': const InventoryGerobakBPage(),
    },
    {
      'title': 'Gerobak C',
      'subtitle': 'Lihat & kelola produk di Gerobak C',
      'icon': Icons.shopping_cart_rounded,
      'color': Color(0xFFF57C00),
      'page': const InventoryGerobakCPage(), // ← Buat halaman ini
    },
    {
      'title': 'Gerobak D',
      'subtitle': 'Lihat & kelola produk di Gerobak D',
      'icon': Icons.shopping_cart_rounded,
      'color': Color(0xFF6A1B9A),
      'page': const InventoryGerobakDPage(), // ← Buat halaman ini
    },
    {
      'title': 'Gerobak E',
      'subtitle': 'Lihat & kelola produk di Gerobak E',
      'icon': Icons.shopping_cart_rounded,
      'color': Color(0xFF00695C),
      'page': const InventoryGerobakEPage(), // ← Buat halaman ini
    },
    {
      'title': 'Gerobak F',
      'subtitle': 'Lihat & kelola produk di Gerobak F',
      'icon': Icons.shopping_cart_rounded,
      'color': Color(0xFFE65100),
      'page': const InventoryGerobakFPage(), // ← Buat halaman ini
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Cek apakah layar lebar (tablet/desktop)
    final isWide = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('Inventory Produk'),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: isWide
            ? _buildGridView()
            : _buildListView(),
      ),
    );
  }

  Widget _buildListView() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _locations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _LocationCard(
        title: _locations[i]['title'],
        subtitle: _locations[i]['subtitle'],
        icon: _locations[i]['icon'],
        color: _locations[i]['color'],
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => _locations[i]['page']),
          );
        },
      ),
    );
  }

  Widget _buildGridView() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.builder(
        itemCount: _locations.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // 3 kolom untuk desktop
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
        ),
        itemBuilder: (_, i) => _LocationCard(
          title: _locations[i]['title'],
          subtitle: _locations[i]['subtitle'],
          icon: _locations[i]['icon'],
          color: _locations[i]['color'],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => _locations[i]['page']),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// WIDGET LOCATION CARD
// ============================================================
class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      shadowColor: const Color(0x1A000000),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF212121),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}