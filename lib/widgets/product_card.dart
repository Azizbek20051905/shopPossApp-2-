import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onAdd;

  const ProductCard({
    super.key,
    required this.product,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2FA7A4);
    const Color textColor = Color(0xFF2C3E50);
    const Color secondaryTextColor = Color(0xFF8A97A5);
    const Color outOfStockColor = Color(0xFFE74C3C);
    const Color lowStockColor = Color(0xFFF6C66A);
    const Color stockColor = Color(0xFF2ECC71);

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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isOut ? null : onAdd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Section
              AspectRatio(
                aspectRatio: 1.25,
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
                    // Stock Badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isOut 
                              ? outOfStockColor 
                              : (isLow ? lowStockColor : stockColor.withAlpha(200)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isOut ? 'OUT OF STOCK' : 'STK: ${product.stockDisplay}',
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
                          fontSize: 15,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return const Center(
      child: Icon(Icons.inventory_2_outlined, color: Color(0xFFCBD5E0), size: 32),
    );
  }
}
