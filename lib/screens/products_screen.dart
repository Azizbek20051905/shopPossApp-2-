import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/inventory_service.dart';
import '../widgets/inventory_product_card.dart';
import '../widgets/app_header.dart';
import 'native_scanner_screen.dart';
import 'product_form_screen.dart';
import '../widgets/app_drawer.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final ProductService _productService = ProductService();
  final InventoryService _inventoryService = InventoryService();
  
  List<Product> _products = [];
  List<Product> _filtered = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();

  static const Color primaryColor = Color(0xFF2FA7A4);
  static const Color bgColor = Color(0xFFF6F7F9);
  static const Color textColor = Color(0xFF2C3E50);
  static const Color secondaryTextColor = Color(0xFF8A97A5);

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _productService.fetchProducts();
      if (mounted) {
        setState(() {
          _products = data;
          _filtered = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  void _onSearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filtered = _products.where((p) =>
        p.name.toLowerCase().contains(query) ||
        (p.barcode?.contains(query) ?? false)
      ).toList();
    });
  }

  void _showAddStockDialog(Product product) {
    final quantityController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Stock: ${product.name}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current: ${product.stockDisplay}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: quantityController,
              decoration: InputDecoration(
                labelText: 'Quantity to add',
                hintText: 'e.g. 50',
                filled: true,
                fillColor: bgColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              final qty = double.tryParse(quantityController.text);
              if (qty == null || qty <= 0) return;
              try {
                final success = await _inventoryService.addStock(product.id!, qty);
                if (success && mounted) {
                  Navigator.pop(context);
                  _loadProducts();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Stock updated!'), backgroundColor: primaryColor, behavior: SnackBarBehavior.floating),
                  );
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('ADD STOCK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: const AppHeader(title: 'PRODUCTS'),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // SEARCH + SCAN BUTTON ROW
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        prefixIcon: const Icon(Icons.search, color: Colors.black54),
                        filled: true,
                        fillColor: bgColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NativeScannerScreen())),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: const Icon(Icons.center_focus_weak, size: 24),
                  ),
                ),
              ],
            ),
          ),
          
          // PRODUCTS GRID
          Expanded(
            child: _buildGrid(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductFormScreen()));
          if (res == true) _loadProducts();
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, size: 32, color: Colors.white),
      ),
    );
  }

  Widget _buildGrid() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: primaryColor));
    }
    if (_error != null) {
      return Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)));
    }
    if (_filtered.isEmpty) {
      return const Center(child: Text('No products found', style: TextStyle(fontWeight: FontWeight.bold)));
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      color: primaryColor,
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65, // Adjusted to fit buttons
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _filtered.length,
        itemBuilder: (context, index) {
          final product = _filtered[index];
          return InventoryProductCard(
            product: product,
            onAddStock: () => _showAddStockDialog(product),
            onEdit: () async {
              final res = await Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => ProductFormScreen(product: product))
              );
              if (res == true) _loadProducts();
            },
          );
        },
      ),
    );
  }
}
