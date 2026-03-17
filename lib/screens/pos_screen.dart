import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cart_provider.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../widgets/product_card.dart';
import '../widgets/app_header.dart';
import 'native_scanner_screen.dart';
import '../widgets/scan_quantity_dialog.dart';
import '../widgets/app_drawer.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final ProductService _productService = ProductService();
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  
  List<Product> _products = [];
  List<Product> _filtered = [];
  bool _isLoading = true;
  String? _error;
  bool _isProcessingSale = false;
  final TextEditingController _searchController = TextEditingController();

  // Spacer/Configuration

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
        p.barcode.contains(query)
      ).toList();
    });
  }

  Future<void> _onBarcodeDetected(String barcode) async {
    // Basic debounce/throttle logic could be added here if needed
    try {
      final product = await _productService.getProductByBarcode(barcode);
      if (product != null) {
        HapticFeedback.mediumImpact();
        SystemSound.play(SystemSoundType.click);

        if (!mounted) return;
        
        // Show quantity dialog
        final qty = await showDialog<double>(
          context: context,
          builder: (context) => ScanQuantityDialog(product: product),
        );

        if (qty != null && mounted) {
          ref.read(cartProvider).addToCart(product, quantity: qty);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${product.name} Added!'),
              backgroundColor: primaryColor,
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Product not found: $barcode'), backgroundColor: Colors.orange),
          );
        }
      }
    } catch (e) {
      print('Scanner Error: $e');
    }
  }

  Future<void> _handleCheckout() async {
    final cart = ref.read(cartProvider);
    if (cart.items.isEmpty) return;

    setState(() => _isProcessingSale = true);
    try {
      final success = await cart.sell();
      if (!mounted) return;
      if (success) {
        _sheetController.animateTo(0.1, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sale completed! 🚀'), backgroundColor: primaryColor, behavior: SnackBarBehavior.floating),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sale failed.'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingSale = false);
    }
  }

  void _toggleSheet() {
    final double currentSize = _sheetController.size;
    if (currentSize <= 0.15) {
      _sheetController.animateTo(0.75, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _sheetController.animateTo(0.1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: const AppHeader(title: 'POS'),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          // MAIN LAYOUT
          Column(
            children: [
              // 1. CART SELECTOR
              _buildCartSelector(cartState),

              // 2. SEARCH + SCAN TOGGLE ROW
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search products...',
                            hintStyle: const TextStyle(color: secondaryTextColor, fontSize: 13),
                            prefixIcon: const Icon(Icons.search, color: secondaryTextColor, size: 20),
                            filled: true,
                            fillColor: const Color(0xFFF1F5F9),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildTopActionBtn(
                      icon: Icons.qr_code_scanner,
                      isActive: true,
                      onPressed: () {
                        // Open scanner as a separate screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NativeScannerScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // 3. PRODUCTS GRID
              Expanded(
                child: _buildProductsSection(),
              ),
              
              // Spacer for the collapsed cart bar
              const SizedBox(height: 70),
            ],
          ),

          // DRAGGABLE CART PANEL
          _buildDraggableCart(),
        ],
      ),
    );
  }

  Widget _buildTopActionBtn({required IconData icon, required bool isActive, required VoidCallback onPressed}) {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? primaryColor : textColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Icon(icon, size: 22),
      ),
    );
  }

  Widget _buildCartSelector(CartProvider cartState) {
    return Container(
      height: 60,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        itemCount: cartState.carts.length + 1,
        itemBuilder: (context, index) {
          if (index == cartState.carts.length) {
            // Add Cart Button
            return _buildAddCartButton(cartState);
          }

          final cart = cartState.carts[index];
          final isActive = cartState.activeCartIndex == index;

          return _buildCartTab(
            name: cart.name,
            items: cart.items.length,
            isActive: isActive,
            onTap: () => cartState.switchCart(index),
            onDelete: cartState.carts.length > 1 ? () => _confirmDeleteCart(index) : null,
          );
        },
      ),
    );
  }

  Widget _buildCartTab({
    required String name, 
    required int items, 
    required bool isActive, 
    required VoidCallback onTap,
    VoidCallback? onDelete,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? primaryColor : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? primaryColor : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Text(
              '$name ${items > 0 ? "($items)" : ""}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isActive ? Colors.white : textColor,
              ),
            ),
            if (onDelete != null && isActive) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDelete,
                child: Icon(Icons.close, size: 14, color: Colors.white.withAlpha(200)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddCartButton(CartProvider cartState) {
    return GestureDetector(
      onTap: cartState.addNewCart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.add, size: 20, color: secondaryTextColor),
      ),
    );
  }

  void _confirmDeleteCart(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Cart?'),
        content: const Text('Are you sure you want to remove this cart and all its items?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              ref.read(cartProvider).deleteCart(index);
              Navigator.pop(context);
            }, 
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: primaryColor, strokeWidth: 3));
    }
    if (_error != null) {
      return Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)));
    }
    if (_filtered.isEmpty) {
      return const Center(child: Text('No products found.', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 500 ? 3 : 2;
        
        return RefreshIndicator(
          onRefresh: _loadProducts,
          color: primaryColor,
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _filtered.length,
            itemBuilder: (context, index) {
              final product = _filtered[index];
              return ProductCard(
                product: product,
                onAdd: () {
                  ref.read(cartProvider).addToCart(product);
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product.name} added'),
                      duration: const Duration(milliseconds: 500),
                      backgroundColor: primaryColor,
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDraggableCart() {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.10,
      minChildSize: 0.08,
      maxChildSize: 0.75,
      snap: true,
      snapSizes: const [0.10, 0.45, 0.75],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              // HANDLE & COLLAPSED HEADER
              SliverToBoxAdapter(
                child: GestureDetector(
                  onTap: _toggleSheet,
                  behavior: HitTestBehavior.opaque,
                  child: _buildCartHeader(),
                ),
              ),
              
              // CART ITEMS
              _buildCartItemsSliver(),

              // TOTALS & BUTTON (Only visible when expanded or enough items exist)
              SliverFillRemaining(
                hasScrollBody: false,
                fillOverscroll: true,
                child: _buildCartFooter(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCartHeader() {
    final cartState = ref.watch(cartProvider);
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_cart_outlined, color: primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${cartState.activeCart.name.toUpperCase()} (${cartState.items.length})',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: textColor, letterSpacing: 0.5),
                    ),
                  ],
                ),
                Text(
                  '${cartState.total.toStringAsFixed(0)} UZS',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: primaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemsSliver() {
    final cart = ref.watch(cartProvider);
    if (cart.items.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey[100]),
                const SizedBox(height: 12),
                Text('Your cart is empty', style: TextStyle(color: Colors.grey[300], fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = cart.items[index];
            return _CompactCartTile(item: item);
          },
          childCount: cart.items.length,
        ),
      ),
    );
  }

  Widget _buildCartFooter() {
    final cart = ref.watch(cartProvider);
    if (cart.items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildTotalRow('Subtotal', '${cart.total.toStringAsFixed(0)} UZS'),
          _buildTotalRow('Discount', '0 UZS'),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: textColor)),
              Text(
                cart.total.toStringAsFixed(0), 
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: primaryColor)
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isProcessingSale ? null : _handleCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[200],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isProcessingSale
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                  : const Text('SELL', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: textColor)),
        ],
      ),
    );
  }
}

class _CompactCartTile extends ConsumerWidget {
  final CartItem item;
  const _CompactCartTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const Color textColor = Color(0xFF2C3E50);
    const Color primaryColor = Color(0xFF22A6A1);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: item.product.imagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(item.product.imagePath!, fit: BoxFit.cover),
                  )
                : const Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: textColor),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${item.quantity.toStringAsFixed(item.product.isWeighted ? 2 : 0)} x ${item.price.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.subtotal.toStringAsFixed(0),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: textColor),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SmallIconButton(
                    icon: Icons.remove,
                    onPressed: () => ref.read(cartProvider).updateQuantity(item.product.id!, item.quantity - 1),
                  ),
                  const SizedBox(width: 12),
                  _SmallIconButton(
                    icon: Icons.add,
                    onPressed: () => ref.read(cartProvider).updateQuantity(item.product.id!, item.quantity + 1),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const _SmallIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28, height: 28,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 14),
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF22A6A1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: const BorderSide(color: Color(0xFFE9ECEF)),
        ),
      ),
    );
  }
}
