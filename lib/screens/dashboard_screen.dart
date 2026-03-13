import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/app_header.dart';
import '../services/analytics_service.dart';
import '../services/sales_service.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import 'product_form_screen.dart';
import 'products_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  final SalesService _salesService = SalesService();
  final ProductService _productService = ProductService();

  bool _isLoading = true;
  List<Map<String, dynamic>> _recentSales = [];
  List<Product> _lowStockProducts = [];

  // Global Design System
  static const Color primaryColor = Color(0xFF2FA7A4);
  static const Color bgColor = Color(0xFFF6F7F9);
  static const Color textColor = Color(0xFF2C3E50);
  static const Color secondaryTextColor = Color(0xFF8A97A5);
  static const double borderRadius = 16.0;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final sales = await _salesService.fetchSalesHistory();
      final products = await _productService.fetchProducts();

      if (mounted) {
        setState(() {
          _recentSales = sales.take(5).toList();
          _lowStockProducts = products.where((p) => p.isLowStock || p.isOutOfStock).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: const AppHeader(title: 'HOME'),
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        color: primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. STATISTICS CARDS
              _buildStatsGrid(),
              
              const SizedBox(height: 24),
              // 2. QUICK ACTIONS
              _buildSectionHeader('Quick Actions'),
              _buildQuickActions(),

              const SizedBox(height: 24),
              // 3. LOW STOCK ALERT
              _buildSectionHeader('Low Stock Alert', trailing: const Icon(Icons.chevron_right, size: 20, color: secondaryTextColor)),
              _buildLowStockList(),

              const SizedBox(height: 24),
              // 4. RECENT SALES
              _buildSectionHeader('Recent Sales', trailing: const Icon(Icons.chevron_right, size: 20, color: secondaryTextColor)),
              _buildRecentSalesList(),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: textColor),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard(
          'Today\'s Sales', 
          '830,000', 
          Icons.shopping_bag_outlined,
          isGradient: true,
          trend: '▼ 25% Today',
        ),
        _buildStatCard(
          'Yesterday\'s Sales', 
          '616,000',
          Icons.calendar_today_outlined,
          trend: '- 10% vs day before',
        ),
        _buildStatCard(
          'Today\'s Profit', 
          '120,000',
          Icons.monetization_on_outlined,
        ),
        _buildStatCard(
          'Total Orders', 
          '45',
          Icons.shopping_cart_outlined,
          isCurrency: false,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, {
    bool isGradient = false, 
    String? trend,
    bool isCurrency = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isGradient ? null : Colors.white,
        gradient: isGradient 
            ? const LinearGradient(
                colors: [Color(0xFF2FA7A4), Color(0xFF3FB7B2)], 
                begin: Alignment.topLeft, 
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 20, 
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon, 
                  size: 20, 
                  color: isGradient ? Colors.white : secondaryTextColor,
                ),
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isGradient ? Colors.white.withAlpha(200) : secondaryTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    isCurrency ? '$value UZS' : value,
                    style: TextStyle(
                      color: isGradient ? Colors.white : textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (trend != null)
                  Text(
                    trend,
                    style: TextStyle(
                      color: isGradient ? Colors.white.withAlpha(200) : primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _buildActionPill(Icons.add, 'Add Product', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductFormScreen()));
          }, isOutline: true),
          const SizedBox(width: 10),
          _buildActionPill(Icons.inventory_2_outlined, 'Add Stock', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductsScreen()));
          }, isOutline: true),
          const SizedBox(width: 10),
          _buildActionPill(Icons.receipt_long_outlined, 'New Sale', () {
             // Navigation logic placeholder
          }, isFilled: true),
        ],
      ),
    );
  }

  Widget _buildActionPill(IconData icon, String label, VoidCallback onTap, {bool isOutline = false, bool isFilled = false}) {
    return SizedBox(
      height: 44,
      child: Material(
        color: isFilled ? const Color(0xFFF4F6F8) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: isOutline ? Border.all(color: primaryColor) : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: isFilled ? textColor : primaryColor),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600, 
                    fontSize: 13, 
                    color: isFilled ? textColor : primaryColor
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLowStockList() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _lowStockProducts.isEmpty ? 3 : _lowStockProducts.length,
        clipBehavior: Clip.none,
        itemBuilder: (context, index) {
          if (_isLoading || _lowStockProducts.isEmpty) {
            return _buildLowStockCardPlaceholder();
          }
          final product = _lowStockProducts[index];
          return _buildLowStockCard(product);
        },
      ),
    );
  }

  Widget _buildLowStockCard(Product product) {
    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textColor),
                ),
                Text(
                  'Stock: ${product.stock.toInt()}', 
                  style: const TextStyle(color: secondaryTextColor, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6C66A), 
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'LOW STOCK', 
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: bgColor, 
              borderRadius: BorderRadius.circular(10),
            ),
            child: product.imagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(product.imagePath!, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.inventory_2_outlined, size: 20, color: Colors.grey)))
                : const Icon(Icons.inventory_2_outlined, size: 20, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockCardPlaceholder() {
    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Loading...', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textColor)),
                Text('Stock: --', style: TextStyle(color: secondaryTextColor, fontSize: 11)),
              ],
            ),
          ),
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.inventory_2_outlined, size: 20, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSalesList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentSales.isEmpty ? 2 : _recentSales.length,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        if (_isLoading || _recentSales.isEmpty) return _buildRecentSalePlaceholder();
        final sale = _recentSales[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order #${sale['id']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textColor)),
                  Text('${sale['item_count']} items', style: const TextStyle(color: secondaryTextColor, fontSize: 12)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${sale['total_amount']} UZS',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: primaryColor),
                  ),
                  Text(
                    '${index * 5 + 2} mins ago',
                    style: const TextStyle(color: secondaryTextColor, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentSalePlaceholder() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order #----', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textColor)),
              Text('-- items', style: TextStyle(color: secondaryTextColor, fontSize: 12)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('0 UZS', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: primaryColor)),
              Text('-- mins ago', style: TextStyle(color: secondaryTextColor, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
