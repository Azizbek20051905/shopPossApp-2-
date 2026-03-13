import '../services/api_service.dart';

enum ProductUnit { piece, kg }

extension ProductUnitExt on ProductUnit {
  String get label => this == ProductUnit.piece ? 'Piece' : 'Kg';
  String get value => this == ProductUnit.piece ? 'piece' : 'kg';
}

/// Predefined product categories.
const productCategories = [
  'Drinks',
  'Food',
  'Snacks',
  'Dairy',
  'Household',
  'Other',
];

class Product {
  final int? id;
  final String name;
  final String barcode;
  final String category;
  final double purchasePrice;
  final double salePrice;
  final int stock;
  final double minStock;
  final ProductUnit unit;
  final String? imagePath;

  const Product({
    this.id,
    required this.name,
    required this.barcode,
    this.category = 'Other',
    required this.purchasePrice,
    required this.salePrice,
    this.stock = 0,
    this.minStock = 10.0,
    this.unit = ProductUnit.piece,
    this.imagePath,
  });

  /// Sale price (used in POS/cart).
  double get price => salePrice;

  bool get isWeighted => unit == ProductUnit.kg;

  bool get isLowStock => stock > 0 && stock <= minStock;

  bool get isOutOfStock => stock <= 0;

  String get stockDisplay {
    final displayStock = stock < 0 ? 0 : stock;
    return isWeighted ? '${displayStock.toStringAsFixed(2)} kg' : '$displayStock pcs';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'category': category,
      'purchase_price': purchasePrice,
      'sale_price': salePrice,
      'stock_quantity': stock,
      'min_stock': minStock,
      'unit': unit.value,
      'image_path': imagePath,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    final unitStr = map['unit'] as String?;

    // Helper to parse double safely
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    // Helper to parse int safely
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toInt();
      if (value is String) return double.tryParse(value)?.toInt() ?? 0;
      return 0;
    }

    try {
      return Product(
        id: map['id'] as int?,
        name: map['name'] as String,
        barcode: map['barcode'] as String,
        category: (map['category'] is Map)
            ? (map['category']['name'] as String? ?? 'Other')
            : (map['category'] as String? ?? 'Other'),
        purchasePrice: parseDouble(map['purchase_price']),
        salePrice: parseDouble(map['sale_price'] ?? map['price']),
        stock: parseInt(map['stock_quantity'] ?? map['stock']),
        minStock: parseDouble(map['min_stock']),
        unit: unitStr == 'kg' ? ProductUnit.kg : ProductUnit.piece,
        imagePath: () {
          String? path = map['image'] as String? ?? map['image_path'] as String?;
          if (path != null && path.startsWith('/media/')) {
            return '${ApiService.serverUrl}$path';
          }
          return path;
        }(),
      );
    } catch (e) {
      print('Error parsing product from map: $e');
      print('Problematic map: $map');
      rethrow;
    }
  }

  Product copyWith({
    int? id,
    String? name,
    String? barcode,
    String? category,
    double? purchasePrice,
    double? salePrice,
    int? stock,
    double? minStock,
    ProductUnit? unit,
    String? imagePath,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salePrice: salePrice ?? this.salePrice,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      unit: unit ?? this.unit,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
