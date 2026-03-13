import 'package:flutter/material.dart';
import '../models/product.dart';

class InventoryProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onAddStock;
  final VoidCallback onEdit;

  const InventoryProductCard({
    super.key,
    required this.product,
    required this.onAddStock,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2FA7A4);
    const Color textColor = Color(0xFF2C3E50);
    const Color secondaryTextColor = Color(0xFF8A97A5);
    const Color stockColor = Color(0xFF2ECC71);
    const Color lowStockColor = Color(0xFFF6C66A);
    const Color outOfStockColor = Color(0xFFE74C3C);

    final bool isOut = product.isOutOfStock;
    final bool isLow = product.isLowStock;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image Section
          AspectRatio(
            aspectRatio: 1.3,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  color: const Color(0xFFF6F7F9),
                  child: product.imagePath != null
                      ? Image.network(
                          product.imagePath!,
                          fit: BoxFit.cover,
                          headers: const {'ngrok-skip-browser-warning': 'true'},
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                ),
                // Stock Badge on Image (Matching POS style)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOut 
                          ? outOfStockColor 
                          : (isLow ? lowStockColor : stockColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isOut 
                          ? 'OUT OF STOCK' 
                          : 'STK: ${product.stockDisplay}',
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Info Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.category.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: secondaryTextColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: textColor,
                      height: 1.2,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${product.salePrice.toStringAsFixed(0)} UZS',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action Buttons Section
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 34,
                    child: ElevatedButton(
                      onPressed: onAddStock,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text('Stock', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 34,
                    child: OutlinedButton(
                      onPressed: onEdit,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        'Edit',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return const Center(
      child: Icon(Icons.inventory_2_outlined, color: Color(0xFFCBD5E0), size: 32),
    );
  }
}
